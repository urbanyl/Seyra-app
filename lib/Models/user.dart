import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MyUser {
  String username;
  String? displayName;
  String userId;
  String profilepic = '';
  MyUser(
      {required this.username,
      this.displayName = '',
      required this.userId,
      required this.profilepic});

  static String usernameToEmail(String username) {
    final clean = username.replaceFirst('@', '').toLowerCase().trim();
    return 'seyra_${clean}@seyra.auth';
  }

  static bool isValidUsername(String username) {
    if (!username.startsWith('@')) return false;
    if (username.length < 4) return false;
    final afterAt = username.substring(1);
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(afterAt);
  }
}

class UserManager with ChangeNotifier {
  late MyUser _currentUser;
  List<MyUser> _currentUserContacts = [];
  List<Contact> _phoneContacts = [];

  List<String> _groupUserIds = [];

  void addtogroupdUserIds(String userId){
    _groupUserIds.add(userId);
    notifyListeners();
  }

  List<String> get groupUserIds{
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return List.from(_groupUserIds);
    final ids = <String>{..._groupUserIds, myUid};
    return ids.toList();
  }

  Future<List<MyUser>> getUserContacts() async {
    _currentUserContacts.clear();
    await setContacts();
    return List.from(_currentUserContacts);
  }

  void createUser(String username, String userId, String? displayName,
      String profilePic) async {
    _currentUser = MyUser(
        username: username,
        userId: userId,
        displayName: displayName,
        profilepic: profilePic);
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'username': username,
      'displayName': displayName ?? username,
      'profilePic': profilePic.isEmpty ? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80' : profilePic,
      'chats': [],
      'channels': []
    }, SetOptions(merge: true));
  }

  MyUser get currentUser {
    return _currentUser;
  }

  Future<void> setContacts() async {
    _currentUserContacts.clear();
    var firestore = FirebaseFirestore.instance.collection('users');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final res = await firestore.get();
    for (var doc in res.docs) {
      if (doc.id != currentUid) {
        _currentUserContacts.add(MyUser(
            username: doc.data()['username'] ?? '@unknown',
            userId: doc.id,
            profilepic: doc.data()['profilePic'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
            displayName: doc.data()['displayName'] ?? doc.data()['username'] ?? 'User'));
      }
    }
    notifyListeners();
  }

  Future<void> setUpContacts() async {
  }

  void createCurrentUserContact(
      Map<String, dynamic> data, String userId, String displayName) {
    _currentUserContacts.add(MyUser(
        username: data['username'] ?? '@unknown',
        profilepic: data['profilePic'] ?? '',
        userId: userId,
        displayName: displayName));
    notifyListeners();
  }

  String? getDisplayNameForUsername(String username) {
    if (username.isEmpty) return null;
    final lowerUsername = username.toLowerCase().trim();

    for (final element in _currentUserContacts) {
      final String elementUsername = (element.username).toLowerCase().trim();
      if (elementUsername.isEmpty) continue;

      if (elementUsername == lowerUsername) {
        return element.displayName;
      }
    }
    return null;
  }
}
