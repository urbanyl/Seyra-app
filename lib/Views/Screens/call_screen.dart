import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:http/http.dart' as http;

enum CallSituations {
  Dialing,
  InCall,
  Done,
}
class CallPage extends StatefulWidget {
  static const ROUTE_NAME = '/callScreen';
  String? name;
  String? callType;
  String? contactId;
  String? roomId;
  bool? isOffering;
  String? callerPic;
  bool? isGroup;

  CallPage(
      {this.name, this.callType, this.contactId, this.isOffering, this.roomId, this.callerPic, this.isGroup = false});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  static const String _meteredHost =
      String.fromEnvironment('METERED_HOST', defaultValue: 'syera.metered.live');
  static const String _meteredApiKey =
      String.fromEnvironment('METERED_API_KEY', defaultValue: '');

  // Centralized WebRTC ICE Server Configuration
  final Map<String, dynamic> iceConfiguration = {
    'iceServers': [
      // Free public Google STUN servers to resolve public IP addresses
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      }
    ]
  };

  // Fetch dynamic TURN server credentials from Metered.ca (syera.metered.live)
  Future<void> _fetchTurnCredentials() async {
    if (_meteredApiKey.trim().isEmpty) {
      return;
    }
    try {
      final response = await http
          .get(Uri.parse(
              'https://$_meteredHost/api/v1/turn/credentials?apiKey=$_meteredApiKey'))
          .timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final List<dynamic> fetchedIceServers = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          iceConfiguration['iceServers'] = [
            {
              'urls': [
                'stun:stun.l.google.com:19302',
                'stun:stun1.l.google.com:19302',
                'stun:stun2.l.google.com:19302',
                'stun:stun3.l.google.com:19302',
                'stun:stun4.l.google.com:19302',
              ]
            },
            ...fetchedIceServers,
          ];
        });
      }
    } catch (e) {
    }
  }

  late CallSituations _callSituations = CallSituations.Dialing;

  late String docID;
  bool _isExited = false;
  bool _isRoomInitialized = false;

  bool isFirst = true;
  RTCVideoRenderer _localVideoRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();

  RTCPeerConnection? peerConnection;

  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _hasAnswered = false;
  bool _isMuted = false;
  bool _isCamOff = false;
  bool _isSpeakerOn = true;

  List<String> _groupMemberIds = [];

  // Group call dynamic mesh variables
  Map<String, RTCPeerConnection> peerConnections = {};
  Map<String, MediaStream> remoteStreams = {};
  Map<String, RTCVideoRenderer> remoteRenderers = {};
  Map<String, String> participantNames = {};
  StreamSubscription? _groupParticipantsSubscription;
  final List<StreamSubscription> _groupSignalSubscriptions = [];
  final Map<String, List<RTCIceCandidate>> _queuedRemoteCandidates = {};

  final _roomRef = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('Room')
      .doc();

  @override
  void initState() {
    super.initState();
    _hasAnswered = widget.isOffering ?? false;
    docID = widget.roomId ?? '';
    _localVideoRenderer.initialize();
    _remoteVideoRenderer.initialize();
    
    _initializeCall();
  }

  void _startRinging() async {
    if (kIsWeb) return;
    if (!mounted) return;
    
    try {
      if (widget.isOffering == false) {
        // Incoming Call: Play native ringtone stream (highly robust URI mapping)
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.electronic,
          looping: true,
          volume: 1.0,
          asAlarm: false,
        );
      }
    } catch (e) {
      try {
        await FlutterRingtonePlayer().playRingtone(
          looping: true,
          asAlarm: false,
          volume: 1.0,
        );
      } catch (e2) {
      }
    }

    if (widget.isOffering == false) {
      try {
        final bool hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          try {
            // High fidelity pulsing pattern
            await Vibration.vibrate(
              pattern: [500, 1000, 500, 1000],
              repeat: 0,
            );
          } catch (_) {
            // General continuous vibration
            await Vibration.vibrate(duration: 15000);
          }
        } else {
          await Vibration.vibrate();
        }
      } catch (e) {
      }
    }
  }

  void _stopRinging() {
    if (kIsWeb) return;
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {
    }
    try {
      Vibration.cancel();
    } catch (e) {
    }
  }

  void _initializeCall() async {
    // Dynamically fetch robust TURN relay servers before negotiating WebRTC connections
    await _fetchTurnCredentials();

    if (widget.isOffering == false) {
      _startRinging();
    }

    if (widget.isOffering!) {
      await initLocalCamera();
      if (widget.isGroup == true) {
        _startGroupCallSignaling();
      } else {
        createOffer();
      }
    } else {
      // For callee, the document already exists in Firestore.
      // We don't start the camera yet; they must click answer first!
      _isRoomInitialized = false;
    }

    if (docID.isNotEmpty) {
      _listenForRoomDeletion();
    }
  }

  void _listenForRoomDeletion() {
    if (widget.isGroup == true) {
      FirebaseFirestore.instance
          .collection('groupCalls')
          .doc(docID)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _isRoomInitialized = true;
        } else if (_isRoomInitialized && !_isExited) {
          hangUp(docID, shouldPop: true);
        }
      });
    } else {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('Room')
          .doc(docID)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _isRoomInitialized = true;
        } else if (_isRoomInitialized && !_isExited) {
          hangUp(docID, shouldPop: true);
        }
      });
    }
  }

  void _answerCall() async {
    _stopRinging();
    await initLocalCamera();
    setState(() {
      _hasAnswered = true;
    });
    if (widget.isGroup == true) {
      _joinGroupCallSignaling();
    } else {
      createAnswer(widget.roomId!);
    }
  }

  // --- Group Call Signaling Methods ---

  void _startGroupCallSignaling() async {
    var roomId = _roomRef.id;
    docID = roomId;
    _listenForRoomDeletion();

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    String callerName = 'Someone';
    String callerPic = '';

    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        callerName = myDoc.data()?['displayName'] ?? myDoc.data()?['username'] ?? 'Someone';
        callerPic = myDoc.data()?['profilePic'] ?? '';
      }
    } catch (e) {
    }

    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.contactId)
          .get();
      if (chatDoc.exists) {
        final List<dynamic> users = chatDoc.data()?['users'] ?? [];
        _groupMemberIds = users.where((uid) => uid != myUid).cast<String>().toList();
      }
    } catch (e) {
    }

    final groupCallData = {
      'roomId': docID,
      'groupId': widget.contactId,
      'callerId': myUid,
      'callerName': callerName,
      'callerPic': callerPic,
      'callType': widget.callType ?? 'Video',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('groupCalls')
        .doc(docID)
        .set(groupCallData);

    await FirebaseFirestore.instance
        .collection('groupCalls')
        .doc(docID)
        .collection('participants')
        .doc(myUid)
        .set({
      'uid': myUid,
      'name': callerName,
      'pic': callerPic,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final roomData = {
      'offer': {},
      'offerFrom': myUid,
      'roomId': docID,
      'callerName': callerName,
      'callerPic': callerPic,
      'callType': widget.callType ?? 'Video',
      'isGroup': true,
    };

    for (final memberId in _groupMemberIds) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('Room')
          .doc(docID)
          .set(roomData);
    }

    _isRoomInitialized = true;
    _logCallHistory();

    _subscribeToGroupParticipants();
  }

  void _joinGroupCallSignaling() async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    String myName = 'Someone';
    String myPic = '';

    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        myName = myDoc.data()?['displayName'] ?? myDoc.data()?['username'] ?? 'Someone';
        myPic = myDoc.data()?['profilePic'] ?? '';
      }
    } catch (e) {
    }

    await FirebaseFirestore.instance
        .collection('groupCalls')
        .doc(docID)
        .collection('participants')
        .doc(myUid)
        .set({
      'uid': myUid,
      'name': myName,
      'pic': myPic,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    _subscribeToGroupParticipants();
  }

  void _subscribeToGroupParticipants() {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    _groupParticipantsSubscription = FirebaseFirestore.instance
        .collection('groupCalls')
        .doc(docID)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final otherUid = data['uid'] as String?;
        final otherName = data['name'] as String? ?? 'Someone';
        if (otherUid != null && otherUid != myUid) {
          participantNames[otherUid] = otherName;
          
          if (!peerConnections.containsKey(otherUid)) {
            if (myUid.compareTo(otherUid) < 0) {
              _initiateOffer(otherUid);
            } else {
              _listenForOffer(otherUid);
            }
          }
        }
      }
    });
  }

  void _initiateOffer(String otherUid) async {
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final pc = await _setupPeerConnection(otherUid);
      
      final sdpConstraints = {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': []
      };
      
      RTCSessionDescription offer = await pc.createOffer(sdpConstraints);
      await pc.setLocalDescription(offer);
      
      final signalRef = FirebaseFirestore.instance
          .collection('groupCalls')
          .doc(docID)
          .collection('signals')
          .doc('${myUid}_to_${otherUid}');
          
      await signalRef.set({
        'offer': offer.toMap(),
        'sender': myUid,
        'receiver': otherUid,
      });
      
      final subAnswer = signalRef.snapshots().listen((snapshot) async {
        try {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data['answer'] != null && await pc.getRemoteDescription() == null) {
              var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
              await pc.setRemoteDescription(answer);
              
              // Process queued candidates
              final candidates = _queuedRemoteCandidates[otherUid];
              if (candidates != null && candidates.isNotEmpty) {
                for (var cand in candidates) {
                  try {
                    await pc.addCandidate(cand);
                  } catch (candErr) {
                  }
                }
                candidates.clear();
              }
            }
          }
        } catch (e, stack) {
        }
      });
      _groupSignalSubscriptions.add(subAnswer);
      
      final subCandidates = signalRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        try {
          snapshot.docChanges.forEach((change) async {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final sdpIndex = data['sdpMLineIndex'] ?? data['sdpMlineIndex'];
                var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], sdpIndex);
                
                final currentPc = peerConnections[otherUid];
                if (currentPc != null && await currentPc.getRemoteDescription() != null) {
                  await currentPc.addCandidate(candidate);
                } else {
                  _queuedRemoteCandidates.putIfAbsent(otherUid, () => []).add(candidate);
                }
              }
            }
          });
        } catch (e) {
        }
      });
      _groupSignalSubscriptions.add(subCandidates);
    } catch (e, stack) {
    }
  }

  void _listenForOffer(String otherUid) async {
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final signalRef = FirebaseFirestore.instance
          .collection('groupCalls')
          .doc(docID)
          .collection('signals')
          .doc('${otherUid}_to_${myUid}');
          
      final subOffer = signalRef.snapshots().listen((snapshot) async {
        try {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data['offer'] != null) {
              var pc = peerConnections[otherUid];
              if (pc == null) {
                pc = await _setupPeerConnection(otherUid);
              }
              
              if (await pc.getRemoteDescription() == null) {
                var offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
                await pc.setRemoteDescription(offer);
                
                final sdpConstraints = {
                  'mandatory': {
                    'OfferToReceiveAudio': true,
                    'OfferToReceiveVideo': true,
                  },
                  'optional': []
                };
                var answer = await pc.createAnswer(sdpConstraints);
                await pc.setLocalDescription(answer);
                
                await signalRef.update({
                  'answer': answer.toMap(),
                });
                
                // Process queued candidates
                final candidates = _queuedRemoteCandidates[otherUid];
                if (candidates != null && candidates.isNotEmpty) {
                  for (var cand in candidates) {
                    try {
                      await pc.addCandidate(cand);
                    } catch (candErr) {
                    }
                  }
                  candidates.clear();
                }
              }
            }
          }
        } catch (e, stack) {
        }
      });
      _groupSignalSubscriptions.add(subOffer);
      
      final subCandidates = signalRef.collection('callerCandidates').snapshots().listen((snapshot) {
        try {
          snapshot.docChanges.forEach((change) async {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final sdpIndex = data['sdpMLineIndex'] ?? data['sdpMlineIndex'];
                var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], sdpIndex);
                
                final currentPc = peerConnections[otherUid];
                if (currentPc != null && await currentPc.getRemoteDescription() != null) {
                  await currentPc.addCandidate(candidate);
                } else {
                  _queuedRemoteCandidates.putIfAbsent(otherUid, () => []).add(candidate);
                }
              }
            }
          });
        } catch (e) {
        }
      });
      _groupSignalSubscriptions.add(subCandidates);
    } catch (e, stack) {
    }
  }

  Future<RTCPeerConnection> _setupPeerConnection(String otherUid) async {
    try {
      Map<String, dynamic> offerSdpConstraints = {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': []
      };
      
      final pc = await createPeerConnection(iceConfiguration, offerSdpConstraints);
      
      if (_localStream != null) {
        try {
          _localStream!.getTracks().forEach((track) {
            pc.addTrack(track, _localStream!);
          });
        } catch (e) {
        }
      }
      
      pc.onConnectionState = (RTCPeerConnectionState state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _removePeer(otherUid);
        }
      };
      
      pc.onAddStream = (MediaStream stream) {
        _addRemoteStream(otherUid, stream);
      };
      
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _addRemoteStream(otherUid, event.streams[0]);
        }
      };
      
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final isCaller = myUid.compareTo(otherUid) < 0;
      final signalDocId = isCaller ? '${myUid}_to_${otherUid}' : '${otherUid}_to_${myUid}';
      final candidateCol = isCaller ? 'callerCandidates' : 'calleeCandidates';
      
      pc.onIceCandidate = (RTCIceCandidate candidate) async {
        if (candidate.candidate != null) {
          try {
            await FirebaseFirestore.instance
                .collection('groupCalls')
                .doc(docID)
                .collection('signals')
                .doc(signalDocId)
                .collection(candidateCol)
                .add(candidate.toMap());
          } catch (e) {
          }
        }
      };
      
      peerConnections[otherUid] = pc;
      return pc;
    } catch (e, stack) {
      rethrow;
    }
  }

  void _addRemoteStream(String otherUid, MediaStream stream) async {
    if (remoteStreams.containsKey(otherUid)) return;
    
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    renderer.srcObject = stream;
    
    setState(() {
      remoteStreams[otherUid] = stream;
      remoteRenderers[otherUid] = renderer;
    });
  }

  void _removePeer(String otherUid) {
    if (peerConnections.containsKey(otherUid)) {
      peerConnections[otherUid]?.close();
      peerConnections.remove(otherUid);
    }
    if (remoteStreams.containsKey(otherUid)) {
      remoteStreams.remove(otherUid);
    }
    if (remoteRenderers.containsKey(otherUid)) {
      remoteRenderers[otherUid]?.dispose();
      remoteRenderers.remove(otherUid);
    }
    setState(() {});
  }

  void _toggleMic() {
    setState(() {
      _isMuted = !_isMuted;
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = !_isMuted;
      });
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCamOff = !_isCamOff;
      _localStream?.getVideoTracks().forEach((track) {
        track.enabled = !_isCamOff;
      });
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (e) {
    }
  }

  void _switchCamera() async {
    if (_localStream != null) {
      try {
        _localStream!.getVideoTracks().forEach((track) async {
          // ignore: deprecated_member_use
          await Helper.switchCamera(track);
        });
      } catch (e) {
      }
    }
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double iconSize = 22,
    double padding = 10,
  }) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildRingingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.35),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: NeonAvatar(
                    displayName: widget.name ?? 'Someone',
                    imageUrl: widget.callerPic,
                    size: 120,
                    isOnline: false,
                    isGroup: widget.isGroup == true,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  widget.name ?? 'Someone',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.callType == 'Video'
                      ? 'Incoming Video Call...'
                      : 'Incoming Audio Call...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      _buildCircleButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () => hangUp(docID, shouldPop: true),
                        iconSize: 30,
                        padding: 16,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      _buildCircleButton(
                        icon: Icons.phone,
                        color: Colors.green,
                        onPressed: _answerCall,
                        iconSize: 30,
                        padding: 16,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Answer',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateVideoView() {
    return _remoteStream == null
        ? Container(
            color: const Color(0xFF1C1C1E),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonAvatar(
                  displayName: widget.name ?? 'Someone',
                  imageUrl: widget.callerPic,
                  size: 100,
                  isOnline: false,
                  isGroup: widget.isGroup == true,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.name ?? 'Connecting...',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Calling...',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          )
        : RTCVideoView(
            _remoteVideoRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          );
  }

  Widget _buildGroupVideoGrid() {
    final List<Widget> remoteViews = [];

    // Add Remote video views
    remoteRenderers.forEach((uid, renderer) {
      final name = participantNames[uid] ?? 'Someone';
      remoteViews.add(
        Container(
          color: const Color(0xFF1C1C1E),
          child: Stack(
            children: [
              Positioned.fill(
                child: RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    int remoteCount = remoteViews.length;

    if (remoteCount == 0) {
      // Waiting for others to join screen
      return Container(
        color: const Color(0xFF1C1C1E),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeonAvatar(
              displayName: widget.name ?? 'Someone',
              imageUrl: widget.callerPic,
              size: 100,
              isOnline: false,
              isGroup: widget.isGroup == true,
            ),
            const SizedBox(height: 20),
            Text(
              widget.name ?? 'Connecting...',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for others to join...',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
          ],
        ),
      );
    } else if (remoteCount == 1) {
      // 1 Remote User: Renders full screen background
      return remoteViews[0];
    } else if (remoteCount == 2) {
      // 2 Remote Users: Split screen into two (one on top, one at bottom)
      return Column(
        children: [
          Expanded(child: remoteViews[0]),
          Expanded(child: remoteViews[1]),
        ],
      );
    } else if (remoteCount == 3) {
      // 3 Remote Users: Split screen into 4 (the fourth is black)
      return GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          remoteViews[0],
          remoteViews[1],
          remoteViews[2],
          Container(color: Colors.black),
        ],
      );
    } else {
      // 4 or more Remote Users: Grid of 4
      return GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          remoteViews[0],
          remoteViews[1],
          remoteViews[2],
          remoteViews[3],
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnswered) {
      return Scaffold(
        body: _buildRingingScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video grids or single 1-to-1 view
          Positioned.fill(
            child: widget.isGroup == true
                ? _buildGroupVideoGrid()
                : _buildPrivateVideoView(),
          ),

          // Floating local camera PIP
          Positioned(
            top: 50,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isCamOff
                    ? const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white70, size: 28),
                      )
                    : RTCVideoView(
                        _localVideoRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),

          // Control overlay panel at bottom center
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white12, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio Toggle (Mic)
                      _buildCircleButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.redAccent : Colors.white12,
                        onPressed: _toggleMic,
                      ),
                      const SizedBox(width: 16),
                      // Video Toggle (Camera)
                      _buildCircleButton(
                        icon: _isCamOff ? Icons.videocam_off : Icons.videocam,
                        color: _isCamOff ? Colors.redAccent : Colors.white12,
                        onPressed: _toggleCamera,
                      ),
                      const SizedBox(width: 16),
                      // Speaker Toggle
                      _buildCircleButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeakerOn ? Colors.blueAccent.shade400 : Colors.white12,
                        onPressed: _toggleSpeaker,
                      ),
                      const SizedBox(width: 16),
                      // Switch Camera
                      _buildCircleButton(
                        icon: Icons.switch_camera,
                        color: Colors.white12,
                        onPressed: _switchCamera,
                      ),
                      const SizedBox(width: 25),
                      // Hang Up Button
                      _buildCircleButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () => hangUp(docID, shouldPop: true),
                        iconSize: 28,
                        padding: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  initLocalCamera() async {
    try {
      _localStream = await navigator.mediaDevices
          .getUserMedia({'video': true, 'audio': true});
      _localVideoRenderer.srcObject = _localStream;
    } catch (e) {
      try {
        // Fallback to audio-only
        _localStream = await navigator.mediaDevices
            .getUserMedia({'video': false, 'audio': true});
        _localVideoRenderer.srcObject = _localStream;
      } catch (e2) {
        _localStream = null;
      }
    }
    setState(() {});
  }

  void createOffer() async {
    var roomId = _roomRef.id;
    docID = roomId;
    _listenForRoomDeletion();

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    String callerName = 'Someone';
    String callerPic = '';

    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        callerName = myDoc.data()?['displayName'] ?? myDoc.data()?['username'] ?? 'Someone';
        callerPic = myDoc.data()?['profilePic'] ?? '';
      }
    } catch (e) {
    }

    if (widget.isGroup == true) {
      try {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.contactId)
            .get();
        if (chatDoc.exists) {
          final List<dynamic> users = chatDoc.data()?['users'] ?? [];
          _groupMemberIds = users.where((uid) => uid != myUid).cast<String>().toList();
        }
      } catch (e) {
      }
    }

    final _contactRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.contactId)
        .collection('Room')
        .doc(roomId);
    Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': []
    };
    peerConnection =
        await createPeerConnection(iceConfiguration, offerSdpConstraints);

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, _localStream!);
      });
    }


    // registerPeerConnectionListeners();
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      // onAddRemoteStream?.call(stream);
      _remoteStream = stream;
      _remoteVideoRenderer.srcObject = _remoteStream;
      setState(() {});
    };

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate != null) {
        /// PROBABLY SHOULD UPLOAD THIS TO FIREBASE
        final ref = await _roomRef
            .collection('callerCandidates')
            .add(candidate.toMap());
        
        if (widget.isGroup == true) {
          for (final memberId in _groupMemberIds) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(memberId)
                .collection('Room')
                .doc(roomId)
                .collection('callerCandidates')
                .doc(ref.id)
                .set(candidate.toMap());
          }
        } else {
          await _contactRef
              .collection('callerCandidates')
              .doc(ref.id)
              .set(candidate.toMap());
        }
        // showing it locally
      }
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    final roomData = {
      'offer': offer.toMap(),
      'offerFrom': myUid,
      'roomId': roomId,
      'callerName': callerName,
      'callerPic': callerPic,
      'callType': widget.callType ?? 'Video',
    };

    await _roomRef.set(roomData);
    
    if (widget.isGroup == true) {
      for (final memberId in _groupMemberIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .collection('Room')
            .doc(roomId)
            .set(roomData);
      }
    } else {
      await _contactRef.set(roomData);
    }
    _isRoomInitialized = true;
    _logCallHistory();


    /// Tracks
    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteVideoRenderer.srcObject = _remoteStream;
        setState(() {});
      }
    };

    /// setting up  a listener for remote sdp
    /// i really dont lnow if we should do the below for contacts also
    _roomRef.snapshots().listen((snapShot) async {
      Map<String, dynamic> data = snapShot.data() as Map<String, dynamic>;
      if (data['answer'] != null) {
        var answer = RTCSessionDescription(
            data['answer']['sdp'], data['answer']['type']);

        await peerConnection!.setRemoteDescription(answer);
      }
    });

    /// listening on remote ICE candidates
    _roomRef.collection('calleeCandidates').snapshots().listen((snapShot) {
      snapShot.docs.forEach((element) {
        Map<String, dynamic> data = element.data() as Map<String, dynamic>;
        var remoteCandidate = RTCIceCandidate(
            data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
        peerConnection!.addCandidate(remoteCandidate);
      });
      // snapShot.docChanges.forEach((element) {
      //   if (element.type == DocumentChangeType.added) {
      //     Map<String, dynamic> data =
      //         element.doc.data() as Map<String, dynamic>;
      //     var remoteCandidate = RTCIceCandidate(
      //         data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      //     peerConnection!.addCandidate(remoteCandidate);
      //   }
      // });
    });
  }

  void createAnswer(String docId) async {
    final _myRoomRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Room')
        .doc(docId);
    final _contactsRoomRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.contactId)
        .collection('Room')
        .doc(docId);
    Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': []
    };
    var roomSnapshot = await _myRoomRef.get();
    // var roomSnapshot2 = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('Room').get();
    // var roomSnapshot = roomSnapshot2.docs[0];
    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(iceConfiguration, offerSdpConstraints);
      
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          peerConnection!.addTrack(track, _localStream!);
        });
      }

      peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      };

      peerConnection?.onAddStream = (MediaStream stream) {
        // onAddRemoteStream?.call(stream);
        _remoteStream = stream;
        _remoteVideoRenderer.srcObject = _remoteStream;
        setState(() {});
      };
      // registerPeerConnectionListeners();

      // _localStream?.getTracks().forEach((track) {
      //   peerConnection?.addTrack(track, _localStream!);
      // });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection =
          _myRoomRef.collection('calleeCandidates');
      var contactCalleeCandidateCollection =
          _contactsRoomRef.collection('calleeCandidates');

      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        if (candidate == null) {
          return;
        }
        calleeCandidatesCollection.add(candidate.toMap()).then((value) =>
            contactCalleeCandidateCollection
                .doc(value.id)
                .set(candidate.toMap()));
        // contactCalleeCandidateCollection.doc(ref.id).set(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      ///TRACKS THING
      peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteVideoRenderer.srcObject = _remoteStream;
          setState(() {});
        }
      };
      // peerConnection?.onTrack = (RTCTrackEvent event) {
      //   event.streams[0].getTracks().forEach((track) {
      //     _remoteStream?.addTrack(track);
      //   });
      // };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await _myRoomRef.update(roomWithAnswer);
      await _contactsRoomRef.update(roomWithAnswer);

      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      _myRoomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        snapshot.docs.forEach((element) {
          var data = element.data() as Map<String, dynamic>;
          final candidate = RTCIceCandidate(
              data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
          peerConnection!.addCandidate(candidate);
        });
        // snapshot.docChanges.forEach((document) {
        //   var data = document.doc.data() as Map<String, dynamic>;
        //   final candidate = RTCIceCandidate(
        //       data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
        //   peerConnection!.addCandidate(candidate);
        // });
      });
    }
  }

  @override
  void dispose() {
    hangUp(docID, shouldPop: false);
    super.dispose();
  }
  
  void hangUp(String docId, {required bool shouldPop}) async {
    _stopRinging();
    if (_isExited) return;
    _isExited = true;

    _groupParticipantsSubscription?.cancel();
    for (var sub in _groupSignalSubscriptions) {
      sub.cancel();
    }

    if (_localStream != null) {
      _localStream!.getTracks().forEach((element) {
        element.stop();
      });
    }
    _localStream?.dispose();

    for (var stream in remoteStreams.values) {
      stream.getTracks().forEach((track) {
        track.stop();
      });
      stream.dispose();
    }

    for (var pc in peerConnections.values) {
      pc.close();
    }
    peerConnections.clear();

    _localVideoRenderer.dispose();
    for (var renderer in remoteRenderers.values) {
      renderer.dispose();
    }
    remoteRenderers.clear();
    remoteStreams.clear();

    if (widget.isGroup != true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('Room')
            .doc(docId)
            .delete();
      } catch (_) {}
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.contactId)
            .collection('Room')
            .doc(docId)
            .delete();
      } catch (_) {}
    } else {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      try {
        await FirebaseFirestore.instance
            .collection('groupCalls')
            .doc(docId)
            .collection('participants')
            .doc(myUid)
            .delete();
      } catch (_) {}

      if (widget.isOffering == true) {
        for (final memberId in _groupMemberIds) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(memberId)
                .collection('Room')
                .doc(docId)
                .delete();
          } catch (_) {}
        }
        try {
          await FirebaseFirestore.instance
              .collection('groupCalls')
              .doc(docId)
              .delete();
        } catch (_) {}
      } else {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(myUid)
              .collection('Room')
              .doc(docId)
              .delete();
        } catch (_) {}
      }
    }
    
    if (mounted && shouldPop) {
      Navigator.of(context).pop();
    }
  }
  void _logCallHistory() async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    String myName = 'Someone';
    String myPic = '';
    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        myName = myDoc.data()?['displayName'] ?? myDoc.data()?['username'] ?? 'Someone';
        myPic = myDoc.data()?['profilePic'] ?? '';
      }
    } catch (e) {
    }
    
    final bool isGroupCall = widget.isGroup == true;

    // Log outgoing for the caller
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('calls')
        .add({
      'contactId': widget.contactId,
      'contactName': widget.name ?? 'Someone',
      'contactPic': widget.callerPic ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'callType': widget.callType ?? 'Video',
      'direction': 'Outgoing',
      'isGroup': isGroupCall,
    });

    // Log incoming for the callee(s)
    if (isGroupCall) {
      // Loop over other group members and log an incoming group call for each of them
      for (final memberId in _groupMemberIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .collection('calls')
            .add({
          'contactId': widget.contactId, // Group ID so they can view/join the group
          'contactName': widget.name ?? 'Someone', // Group Name
          'contactPic': widget.callerPic ?? '', // Group Pic
          'timestamp': FieldValue.serverTimestamp(),
          'callType': widget.callType ?? 'Video',
          'direction': 'Incoming',
          'isGroup': true,
          'callerName': myName, // The specific group member who initiated the call
        });
      }
    } else {
      if (widget.contactId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.contactId)
            .collection('calls')
            .add({
          'contactId': myUid,
          'contactName': myName,
          'contactPic': myPic,
          'timestamp': FieldValue.serverTimestamp(),
          'callType': widget.callType ?? 'Video',
          'direction': 'Incoming',
          'isGroup': false,
        });
      }
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      // onAddRemoteStream?.call(stream);
      setState(() {});
      _remoteStream = stream;
      _remoteVideoRenderer.srcObject = _remoteStream;
    };
  }
}

class CallTimer extends StatefulWidget {
  @override
  _CallTimerState createState() => _CallTimerState();
}

class _CallTimerState extends State<CallTimer> {
  late Timer _timer;
  int _timeExpandedBySeconds = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeExpandedBySeconds += 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_timeExpandedBySeconds');
  }
}
