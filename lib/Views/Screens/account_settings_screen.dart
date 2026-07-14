import 'dart:io';
import 'package:seyra/Models/theme.dart';
import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AccountSettingPage extends StatefulWidget {
  static const ROUTE_NAME = '/account_settings';

  @override
  State<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  late MyUser user;
  XFile? xFile;
  final _controller = TextEditingController();
  bool _isSaving = false;
  bool _isFirst = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirst) {
      user = ModalRoute.of(context)!.settings.arguments as MyUser;
      _controller.text = user.displayName ?? '';
      _isFirst = false;
    }
  }

  Future<void> _autoSaveProfilePicture(XFile file) async {
    setState(() {
      _isSaving = true;
    });
    try {
      var uploadTask = await FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.userId)
          .child('profile_pictures')
          .child(file.name)
          .putData(await file.readAsBytes());
      String photoUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.userId)
          .update({'profilePic': photoUrl});

      setState(() {
        user.profilepic = photoUrl;
        xFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile picture updated successfully.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to upload profile picture. Please try again.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    setState(() {
      _isSaving = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.userId)
          .update({'displayName': newName});

      setState(() {
        user.displayName = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Display name updated successfully.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update display name. Please check your connection and try again.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // void changeUserProfile(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: const Color(0xFFFFFFFF),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(32),
  //         topRight: Radius.circular(32),
  //       ),
  //     ),
  //     builder: (context) => SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 48,
  //                 height: 5,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFEEEEEE),
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 24),
  //             const Text(
  //               'UPDATE CAMERA SOURCE',
  //               style: TextStyle(
  //                 fontFamily: 'Hanken Grotesk',
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 1.0,
  //                 color: Color(0xFF111111),
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 24),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton.icon(
  //                     style: OutlinedButton.styleFrom(
  //                       side: const BorderSide(color: Color(0xFF111111), width: 1.5),
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  //                       padding: const EdgeInsets.symmetric(vertical: 14),
  //                     ),
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                       pickImage(ImageSource.camera, context);
  //                     },
  //                     icon: const Icon(Icons.photo_camera_outlined, color: Color(0xFF111111)),
  //                     label: const Text('Camera', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.bold)),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: OutlinedButton.icon(
  //                     style: OutlinedButton.styleFrom(
  //                       side: const BorderSide(color: Color(0xFF111111), width: 1.5),
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  //                       padding: const EdgeInsets.symmetric(vertical: 14),
  //                     ),
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                       pickImage(ImageSource.gallery, context);
  //                     },
  //                     icon: const Icon(Icons.image_outlined, color: Color(0xFF111111)),
  //                     label: const Text('Gallery', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.bold)),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  pickImage(ImageSource imageSource, BuildContext context) async {
    var imagePicker = ImagePicker();
    try {
      var file = await imagePicker.pickImage(source: imageSource);
      if (file != null) {
        _autoSaveProfilePicture(file);
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to access camera or gallery. Please check your app permissions.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditProfileSheet(BuildContext context) {
    _controller.text = user.displayName ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Edit Profile Name',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Profile Display Name',
                  labelStyle: TextStyle(
                    color: const Color(0xFF111111).withOpacity(0.5),
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.1), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2B54ED), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF111111)),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final newName = _controller.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.of(context).pop();
                    _updateDisplayName(newName);
                  }
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save Name',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showSecuritySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_outlined, color: theme.colorScheme.tertiary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Security & Keys',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'CRYPTOGRAPHIC NODE IDENTITY',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unique Node ID:',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.userId,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This node has a verified encryption identity. All communication is encrypted end-to-end using post-quantum cryptography standards.',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Are you sure you want to sign out?',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to verify your credentials again to synchronize your encryption keys.',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myTheme = Provider.of<MyTheme>(context);
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.userId).snapshots(),
      builder: (context, snapshot) {
        bool isAnonymous = false;
        String resolvedDisplayName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : (user.username.trim().isNotEmpty ? user.username : 'Someone');
        String displayUsername = user.username;
        String? profilePicUrl = user.profilepic.isNotEmpty == true ? user.profilepic : null;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          isAnonymous = data?['isAnonymous'] ?? false;
          if (isAnonymous) {
            resolvedDisplayName = 'Anonyme';
            displayUsername = '';
            profilePicUrl = null;
          } else {
            final String? fsDisplayName = data?['displayName'];
            if (fsDisplayName != null && fsDisplayName.trim().isNotEmpty) {
              resolvedDisplayName = fsDisplayName;
            }
            final String? fsProfilePic = data?['profilePic'];
            if (fsProfilePic != null && fsProfilePic.trim().isNotEmpty) {
              profilePicUrl = fsProfilePic;
            }
          }
        }

        return Scaffold(
          backgroundColor: theme.brightness == Brightness.dark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isSaving)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: theme.colorScheme.onSurface, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
            shape: const Border(),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beautiful Custom Avatar Display
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.tertiary,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : const Color(0xFF111111),
                                ),
                                child: ClipOval(
                                  child: xFile == null
                                      ? NeonAvatar(
                                          displayName: resolvedDisplayName,
                                          imageUrl: profilePicUrl,
                                          size: 110,
                                        )
                                      : Image.file(
                                          File(xFile!.path),
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          resolvedDisplayName,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isAnonymous ? Colors.grey : theme.colorScheme.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAnonymous ? 'ANONYME ACTIVE' : 'VERIFIED ENCRYPTION',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Menu Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.dividerColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark ? Colors.transparent : const Color(0xFF111111).withOpacity(0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile',
                            onTap: () => _showEditProfileSheet(context),
                          ),
                          Divider(color: theme.dividerColor, height: 1),
                          _buildMenuItem(
                            icon: Icons.visibility_off_outlined,
                            title: 'Anonymous Mode',
                            trailing: Switch.adaptive(
                              value: isAnonymous,
                              activeColor: theme.colorScheme.tertiary,
                              onChanged: (val) async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.userId)
                                    .update({'isAnonymous': val});
                              },
                            ),
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.userId)
                                  .update({'isAnonymous': !isAnonymous});
                            },
                          ),
                          Divider(color: theme.dividerColor, height: 1),
                          _buildMenuItem(
                            icon: myTheme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            title: 'Dark Mode',
                            trailing: Switch.adaptive(
                              value: myTheme.isDarkMode,
                              activeColor: theme.colorScheme.tertiary,
                              onChanged: (val) {
                                myTheme.setDarkMode(val);
                              },
                            ),
                            onTap: () {
                              myTheme.setDarkMode(!myTheme.isDarkMode);
                            },
                          ),
                          Divider(color: theme.dividerColor, height: 1),
                          _buildMenuItem(
                            icon: Icons.vpn_key_outlined,
                            title: 'Security & Keys',
                            onTap: () => _showSecuritySheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => _confirmSignOut(context),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.brightness == Brightness.dark ? Colors.transparent : const Color(0xFF111111).withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : const Color(0xFFFFFFFF), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : const Color(0xFFFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Version Footer
                  const Center(
                    child: Text(
                      'V.2.4.0 SECURE BETA',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB1B5B8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
