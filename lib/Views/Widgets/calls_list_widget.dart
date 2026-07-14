import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CallsListWidget extends StatefulWidget {
  const CallsListWidget({Key? key}) : super(key: key);

  @override
  State<CallsListWidget> createState() => _CallsListWidgetState();
}

class _CallsListWidgetState extends State<CallsListWidget> {
  final ScrollController _scrollController = ScrollController();
  int _limit = 15;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        setState(() {
          _isLoadingMore = true;
          _limit += 15;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _limit = 15;
      _hasMore = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
  }

  String _formatCallTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minuteStr = minute < 10 ? '0$minute' : '$minute';
    final timeStr = '$hour:$minuteStr $period';

    if (difference.inDays == 0 && dateTime.day == now.day) {
      return 'Today, $timeStr';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && dateTime.day == now.day - 1)) {
      return 'Yesterday, $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $timeStr';
    }
  }

  Widget _buildCallItem({
    required ThemeData theme,
    required String displayName,
    required String contactPic,
    required String direction,
    required String callType,
    required bool isIncoming,
    required Timestamp? timestamp,
    required bool isGroup,
    String callerName = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Neon Avatar for cohesive styling
          NeonAvatar(
            displayName: displayName,
            imageUrl: contactPic.isEmpty ? null : contactPic,
            size: 44,
            isGroup: isGroup,
          ),
          const SizedBox(width: 14),

          // User Details and Call Type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Direction Arrow (green for incoming, red for outgoing)
                    Icon(
                      isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                      size: 14,
                      color: isIncoming ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIncoming && isGroup && callerName.isNotEmpty
                          ? 'From $callerName'
                          : direction,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCallTime(timestamp),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12.5,
                        color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icon representing call medium (audio or video call)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              callType == 'Video' ? Icons.videocam_outlined : Icons.phone_outlined,
              size: 20,
              color: theme.textTheme.bodyLarge?.color ?? const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final userManager = Provider.of<UserManager>(context);

    if (myUid == null) {
      return const Center(child: Text('Not authenticated.'));
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('calls')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _limit == 15) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.length < _limit) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }

        _isLoadingMore = false;

        if (docs.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF2B54ED),
            backgroundColor: const Color(0xFF111111),
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_missed_rounded,
                        size: 48,
                        color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No call history yet',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF2B54ED),
          backgroundColor: const Color(0xFF111111),
          onRefresh: _handleRefresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length + (_hasMore ? 1 : 0),
            separatorBuilder: (context, index) => Divider(
              color: (theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111)).withOpacity(0.06),
              height: 1,
            ),
            itemBuilder: (context, index) {
              if (index == docs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              final callData = docs[index].data() as Map<String, dynamic>;
              final String contactId = callData['contactId'] ?? '';
              final String fallbackName = callData['contactName'] ?? 'Someone';
              final String contactPic = callData['contactPic'] ?? '';
              final callType = callData['callType'] ?? 'Video';
              final direction = callData['direction'] ?? 'Incoming';
              final timestamp = callData['timestamp'] as Timestamp?;
              final isIncoming = direction == 'Incoming';
              final bool isGroup = callData['isGroup'] == true;
              final String callerName = callData['callerName'] ?? '';

              if (isGroup) {
                return _buildCallItem(
                  theme: theme,
                  displayName: fallbackName.trim().isNotEmpty ? fallbackName : 'Group Call',
                  contactPic: contactPic,
                  direction: direction,
                  callType: callType,
                  isIncoming: isIncoming,
                  timestamp: timestamp,
                  isGroup: true,
                  callerName: callerName,
                );
              }

              if (contactId.isEmpty) {
                return _buildCallItem(
                  theme: theme,
                  displayName: fallbackName.trim().isNotEmpty ? fallbackName : 'Someone',
                  contactPic: contactPic,
                  direction: direction,
                  callType: callType,
                  isIncoming: isIncoming,
                  timestamp: timestamp,
                  isGroup: false,
                );
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(contactId).snapshots(),
                builder: (context, userSnapshot) {
                  String displayName = fallbackName;
                  String imageUrl = contactPic;

                  if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      final String userUsername = userData['username'] ?? '';
                      imageUrl = userData['profilePic'] ?? userData['profileImage'] ?? contactPic;

                      final String? localName = userManager.getDisplayNameForUsername(userUsername);

                      if (localName != null && localName.trim().isNotEmpty) {
                        displayName = localName;
                      } else {
                        // Check firestore name
                        final String fsName = userData['displayName'] ?? '';
                        if (fsName.trim().isNotEmpty) {
                          displayName = fsName;
                        } else {
                          displayName = userUsername.trim().isNotEmpty ? userUsername : fallbackName;
                        }
                      }
                    }
                  }

                  if (displayName.trim().isEmpty) {
                    displayName = 'Someone';
                  }

                  return _buildCallItem(
                    theme: theme,
                    displayName: displayName,
                    contactPic: imageUrl,
                    direction: direction,
                    callType: callType,
                    isIncoming: isIncoming,
                    timestamp: timestamp,
                    isGroup: false,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
