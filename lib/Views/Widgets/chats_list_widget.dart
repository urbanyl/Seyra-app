import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Widgets/chat_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatList extends StatefulWidget {
  final String? filter;
  ChatList({this.filter});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ScrollController _scrollController = ScrollController();
  int _limit = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Search state variables
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // local memory cache for user profiles to enable instant filter searching
  final Map<String, Map<String, dynamic>> _chatUsersCache = {};
  bool _isFetchingUsers = false;

  Future<void> _handleRefresh() async {
    setState(() {
      _limit = 15;
      _hasMore = true;
      _chatUsersCache.clear();
    });
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMore) {
      setState(() {
        _isLoadingMore = true;
        _limit += 15;
      });
    }
  }

  Future<void> _fetchMissingUsers(List<dynamic> docs) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    List<String> contactUidsToFetch = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['type'] == 'Private') {
        final users = List<String>.from(data['users'] ?? []);
        final otherUid = users.firstWhere((id) => id != myUid, orElse: () => '');
        if (otherUid.isNotEmpty && !_chatUsersCache.containsKey(otherUid)) {
          contactUidsToFetch.add(otherUid);
        }
      }
    }

    if (contactUidsToFetch.isEmpty || _isFetchingUsers) return;

    _isFetchingUsers = true;
    try {
      final futures = contactUidsToFetch.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get());
      final snapshots = await Future.wait(futures);

      for (var snap in snapshots) {
        if (snap.exists && snap.data() != null) {
          _chatUsersCache[snap.id] = snap.data()!;
        }
      }
      if (mounted) {
        setState(() {}); // Refresh to reflect loaded user cache in filter matches
      }
    } catch (e) {

    } finally {
      _isFetchingUsers = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    var query = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .limit(_limit);

    switch (widget.filter) {
      case 'Private':
        query = query.where('type', isEqualTo: 'Private');
        break;
      case 'Group':
        query = query.where('type', isEqualTo: 'Group');
        break;
      case 'Channel':
        query = query.where('type', isEqualTo: 'Channel');
        break;
    }

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, AsyncSnapshot<dynamic> asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting && _limit == 15) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (!asyncSnapshot.hasData || asyncSnapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        var docs = asyncSnapshot.data.docs;

        // Sync device profiles of private chat contacts in the background
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchMissingUsers(docs);
        });

        // If loaded documents is less than our current limit, we have reached the end
        if (docs.length < _limit) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }

        _isLoadingMore = false;

        var list = docs
            .map((doc) => <String, dynamic>{
                  'id': doc.id,
                  'type': doc.data()['type'],
                  'chatPic': doc.data()['chatPic'],
                  'users': doc.data()['users'],
                  'displayName': doc.data()['displayName'] ?? '',
                  'lastMessageAt': doc.data()['lastMessageAt'],
                })
            .toList();

        // Sort client-side by lastMessageAt from recent to oldest
        list.sort((a, b) {
          final Timestamp? timeA = a['lastMessageAt'] as Timestamp?;
          final Timestamp? timeB = b['lastMessageAt'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        // Perform client-side fast search filtering
        if (_searchQuery.trim().isNotEmpty) {
          final myUid = FirebaseAuth.instance.currentUser!.uid;
          final queryLower = _searchQuery.trim().toLowerCase();

          list = list.where((chat) {
            if (chat['type'] == 'Private') {
              final otherUid = List<String>.from(chat['users'] ?? [])
                  .firstWhere((id) => id != myUid, orElse: () => '');

              final cachedUserData = _chatUsersCache[otherUid];
              if (cachedUserData != null) {
                final userUsername = cachedUserData['username'] ?? '';
                final firebaseName = (cachedUserData['displayName'] ?? '').toString().toLowerCase();

                final localContactName = Provider.of<UserManager>(context, listen: false)
                        .getDisplayNameForUsername(userUsername)
                        ?.toLowerCase() ??
                    '';

                return userUsername.contains(queryLower) ||
                    firebaseName.contains(queryLower) ||
                    localContactName.contains(queryLower);
              }
              // Keep it visible temporarily or matching by default if profile is fetching
              return false;
            } else {
              // Group or Channel matching
              final groupName = (chat['displayName'] ?? '').toString().toLowerCase();
              return groupName.contains(queryLower);
            }
          }).toList();
        }

        final count = list.length;

        Widget contentWidget;
            if (list.isEmpty) {
              contentWidget = RefreshIndicator(
                color: theme.colorScheme.primary,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: theme.iconTheme.color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No active conversations' : 'No matching chats found',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              contentWidget = RefreshIndicator(
                color: theme.colorScheme.primary,
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < list.length) {
                      return ChatItem(ValueKey(list[index]['id']), list[index]);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }
                  },
                ),
              );
            }

            return Column(
              children: [
                // Premium Adaptive Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search chats, names, numbers...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF111111)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF111111)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color ?? const Color(0xFF111111),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : const Color(0xFF111111).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$count Messages',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color ?? const Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: contentWidget),
                    ],
                  ),
                ),
              ],
            );
      },
    );
  }
}
