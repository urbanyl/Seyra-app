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
    return Container(
      width: 300,
      color: theme.scaffoldBackgroundColor,
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<dynamic> asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.colorScheme.onSurface),
              );
            }
            
            final userData = asyncSnapshot.data?.data();
            final bool isAnonymous = userData?['isAnonymous'] ?? false;
            final String displayName = isAnonymous ? 'Anonyme' : (userData?['displayName'] ?? '');
            final String userUsername = isAnonymous ? '' : (userData?['username'] ?? '');
            final String profilePic = isAnonymous ? '' : (userData?['profilePic'] ?? '');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/splash_logo.png',
                        height: 48,
                        alignment: Alignment.centerLeft,
                        color: theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : null,
                      ),
                      Text(
                        'SECURE MESSENGER',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            NeonAvatar(
                              displayName: displayName.isNotEmpty ? displayName : (userUsername.isNotEmpty ? userUsername : 'User'),
                              size: 52,
                              isOnline: true,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName.isNotEmpty ? displayName : 'New User',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                   if (userUsername.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                       userUsername,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1, color: theme.dividerColor),
                ),
                
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ListTile(
                        leading: Icon(Icons.tune, color: theme.colorScheme.onSurface),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          t.appSettings,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pushNamed(AppSettingsScreen.routeName),
                      ),
                      ListTile(
                        leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          t.accountSettings,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pushNamed(
                            AccountSettingPage.ROUTE_NAME,
                            arguments: MyUser(
                                username: userUsername,
                                userId: FirebaseAuth.instance.currentUser!.uid,
                                profilepic: profilePic,
                                displayName: displayName)),
                      ),
                      ListTile(
                        leading: Icon(Icons.security_outlined, color: theme.colorScheme.onSurface),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          t.securityInfo,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pushNamed(SecurityInfoScreen.routeName),
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
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
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
}
