import 'dart:async';
import 'package:seyra/Views/Screens/call_screen.dart';
import 'package:seyra/Models/app_settings.dart';
import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Screens/contacts_screen.dart';
import 'package:seyra/Views/Screens/create_group.dart';
import 'package:seyra/Views/Widgets/chats_list_widget.dart';
import 'package:seyra/Views/Widgets/calls_list_widget.dart';
import 'package:seyra/Views/Widgets/my_drawer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seyra/Services/notification_service.dart';
import 'package:seyra/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _callSubscription;
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _chatMessageSubscriptions = {};
  final Set<String> _notifiedMessageIds = {};
  bool _isCallPageOpen = false;
  TabController? _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCallListener();
    _startMessageNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserManager>(context, listen: false).setContacts();
    });
  }

  void _startCallListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    _callSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('Room')
        .where('offerFrom', isNotEqualTo: myUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_isCallPageOpen) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        final roomId = data['roomId'] ?? doc.id;
        final contactId = data['offerFrom'];
        final callerName = data['callerName'] ?? 'Incoming Call';
        final callType = data['callType'] ?? 'Video';
        final callerPic = data['callerPic'] ?? '';
        final isGroup = data['isGroup'] == true;

        setState(() {
          _isCallPageOpen = true;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallPage(
              name: callerName,
              callType: callType,
              isOffering: false,
              contactId: contactId,
              roomId: roomId,
              callerPic: callerPic,
              isGroup: isGroup,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isCallPageOpen = false;
            });
          }
        });
      }
    });
  }

  void _startMessageNotifications() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    _chatsSubscription?.cancel();
    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: myUid)
        .snapshots()
        .listen((snapshot) {
      final settings = context.read<AppSettings>();
      if (!settings.notificationsEnabled) return;

      final currentIds = snapshot.docs.map((d) => d.id).toSet();

      final toRemove = _chatMessageSubscriptions.keys
          .where((id) => !currentIds.contains(id))
          .toList();
      for (final chatId in toRemove) {
        _chatMessageSubscriptions.remove(chatId)?.cancel();
      }

      for (final chatDoc in snapshot.docs) {
        if (_chatMessageSubscriptions.containsKey(chatDoc.id)) continue;

        final sub = chatDoc.reference
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnapshot) async {
          if (msgSnapshot.docs.isEmpty) return;
          final msgDoc = msgSnapshot.docs.first;
          if (_notifiedMessageIds.contains(msgDoc.id)) return;
          _notifiedMessageIds.add(msgDoc.id);

          final data = msgDoc.data() as Map<String, dynamic>;
          final senderId = (data['senderId'] ?? '').toString();
          if (senderId == myUid) return;

          final t = AppLocalizations.of(context);
          final settings = context.read<AppSettings>();
          if (!settings.notificationsEnabled) return;

          final text = (data['textMessage'] ?? '').toString().trim();
          final media = (data['mediaMessage'] ?? '').toString().trim();
          final body = settings.notificationsPreview
              ? (text.isNotEmpty
                  ? text
                  : (media.isNotEmpty ? 'Media' : t.newMessageHidden))
              : t.newMessageHidden;

          final title = t.newMessage;
          final id = msgDoc.id.hashCode & 0x7fffffff;
          await NotificationService.instance.showMessageNotification(
            id: id,
            title: title,
            body: body,
          );
        });

        _chatMessageSubscriptions[chatDoc.id] = sub;
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _chatsSubscription?.cancel();
    for (final sub in _chatMessageSubscriptions.values) {
      sub.cancel();
    }
    _chatMessageSubscriptions.clear();
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null) return;
    if (controller.indexIsChanging) return;
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return ChatList();
      case 1:
        return ChatList(filter: 'Private');
      case 2:
        return ChatList(filter: 'Group');
      case 3:
        return CallsListWidget();
      default:
        return ChatList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Builder(builder: (context) {
        final t = AppLocalizations.of(context);
        final tabController = DefaultTabController.of(context);
        if (_tabController != tabController) {
          _tabController?.removeListener(_handleTabChange);
          _tabController = tabController;
          _tabController?.addListener(_handleTabChange);
        }

        final theme = Theme.of(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return _buildWideLayout(t, theme, tabController);
            } else {
              return _buildMobileLayout(t, theme, tabController);
            }
          },
        );
      }),
    );
  }

  Widget _buildWideLayout(AppLocalizations t, ThemeData theme, TabController tabController) {
    final isGroupsTab = _selectedIndex == 2;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/splash_logo.png',
                        height: 28,
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.onSurface
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SEYRA',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                ),
                const SizedBox(height: 8),
                // Navigation items
                _buildSidebarItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: t.tabAll,
                  index: 0,
                  theme: theme,
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    tabController.index = 0;
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.person_outline_rounded,
                  label: t.tabPv,
                  index: 1,
                  theme: theme,
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    tabController.index = 1;
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.people_outline_rounded,
                  label: t.tabGroups,
                  index: 2,
                  theme: theme,
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    tabController.index = 2;
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.phone_outlined,
                  label: t.tabCalls,
                  index: 3,
                  theme: theme,
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    tabController.index = 3;
                  },
                ),
                const Spacer(),
                // New chat / group button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B54ED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (isGroupsTab) {
                          Navigator.of(context).pushNamed(CreateGroupPage.ROUTE_NAME);
                        } else {
                          Navigator.of(context).pushNamed(ContactsPage.ROUTE_NAME);
                        }
                      },
                      icon: Icon(
                        isGroupsTab ? Icons.group_add_outlined : Icons.add,
                        size: 18,
                      ),
                      label: Text(
                        isGroupsTab ? 'New Group' : 'New Chat',
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                // Drawer button
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                        side: BorderSide(color: theme.dividerColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openDrawer(context),
                      icon: const Icon(Icons.menu_rounded, size: 18),
                      label: const Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _buildTabContent(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? const Color(0xFF2B54ED).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF2B54ED)
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF2B54ED)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            height: double.infinity,
            child: MyDrawer(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AppLocalizations t, ThemeData theme, TabController tabController) {
    final isGroupsTab = tabController.index == 2;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: Image.asset(
          'assets/images/splash_logo.png',
          height: 32,
          fit: BoxFit.contain,
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.onSurface
              : null,
        ),
        centerTitle: true,
        primary: true,
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2B54ED),
        foregroundColor: const Color(0xFF111111),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF111111), width: 1.5),
        ),
        onPressed: () {
          if (isGroupsTab) {
            Navigator.of(context).pushNamed(CreateGroupPage.ROUTE_NAME);
          } else {
            Navigator.of(context).pushNamed(ContactsPage.ROUTE_NAME);
          }
        },
        child: Icon(
          isGroupsTab ? Icons.group_add_outlined : Icons.add,
          size: 26,
        ),
      ),
      body: TabBarView(
        children: [
          ChatList(),
          ChatList(filter: 'Private'),
          ChatList(filter: 'Group'),
          CallsListWidget(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: TabBar(
              indicatorColor: const Color(0xFF2B54ED),
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: theme.textTheme.bodyLarge?.color ??
                  const Color(0xFF111111),
              unselectedLabelColor:
                  (theme.textTheme.bodyLarge?.color ?? const Color(0xFF111111))
                      .withOpacity(0.4),
              labelStyle: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                  text: t.tabAll,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: const Icon(Icons.person_outline_rounded, size: 22),
                  text: t.tabPv,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: const Icon(Icons.people_outline_rounded, size: 22),
                  text: t.tabGroups,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  icon: const Icon(Icons.phone_outlined, size: 22),
                  text: t.tabCalls,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
