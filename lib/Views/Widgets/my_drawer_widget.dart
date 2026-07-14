import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Screens/account_settings_screen.dart';
import 'package:seyra/Views/Screens/app_settings_screen.dart';
import 'package:seyra/Views/Screens/security_info_screen.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyra/l10n/app_localizations.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final accent = theme.colorScheme.tertiary;
    final textPrimary = theme.colorScheme.onSurface;
    return Container(
      width: 320,
      color: theme.scaffoldBackgroundColor,
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder:
              (context, AsyncSnapshot<dynamic> asyncSnapshot) {
            if (asyncSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final userData =
                asyncSnapshot.data?.data();
            final bool isAnonymous =
                userData?['isAnonymous'] ?? false;
            final String displayName = isAnonymous
                ? 'Anonyme'
                : (userData?['displayName'] ?? '');
            final String userUsername = isAnonymous
                ? ''
                : (userData?['username'] ?? '');
            final String profilePic = isAnonymous
                ? ''
                : (userData?['profilePic'] ?? '');

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                      top: 60,
                      left: 24,
                      right: 24,
                      bottom: 24),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/splash_logo.png',
                        height: 48,
                        alignment: Alignment.centerLeft,
                      ),
                      Text(
                        'SECURE MESSENGER',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accent,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme
                              .dialogBackgroundColor,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            NeonAvatar(
                              displayName: displayName
                                      .isNotEmpty
                                  ? displayName
                                  : (userUsername
                                          .isNotEmpty
                                      ? userUsername
                                      : 'User'),
                              size: 52,
                              isOnline: true,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    displayName
                                            .isNotEmpty
                                        ? displayName
                                        : 'New User',
                                    style: TextStyle(
                                      fontFamily:
                                          'Hanken Grotesk',
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),
                                  if (userUsername
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                        height: 2),
                                    Text(
                                      userUsername,
                                      style: TextStyle(
                                        fontFamily:
                                            'Geist',
                                        fontSize: 12,
                                        color: textPrimary
                                            .withOpacity(
                                                0.5),
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: theme.dividerColor),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    children: [
                      _buildMenuItem(
                        icon: Icons.tune,
                        label: t.appSettings,
                        theme: theme,
                        accent: accent,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(
                                    AppSettingsScreen
                                        .routeName),
                      ),
                      _buildMenuItem(
                        icon: Icons
                            .settings_outlined,
                        label: t.accountSettings,
                        theme: theme,
                        accent: accent,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(
                                    AccountSettingPage
                                        .ROUTE_NAME,
                                    arguments: MyUser(
                                        username:
                                            userUsername,
                                        userId: FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid,
                                        profilepic:
                                            profilePic,
                                        displayName:
                                            displayName)),
                      ),
                      _buildMenuItem(
                        icon: Icons
                            .security_outlined,
                        label: t.securityInfo,
                        theme: theme,
                        accent: accent,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(
                                    SecurityInfoScreen
                                        .routeName),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Seyra Secure Messenger v1.1.0\nFully Encrypted Node',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      color: textPrimary
                          .withOpacity(0.3),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final textPrimary = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon,
            color: accent.withOpacity(0.8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
