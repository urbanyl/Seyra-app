import 'package:seyra/Models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AuthState { Login, Register }

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  AuthState _authState = AuthState.Login;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        
                        Image.asset(
                          'assets/images/splash_logo.png',
                          height: 70,
                          width: 70,
                        ),

                        const SizedBox(height: 20),
                        
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _authState == AuthState.Login
                                      ? 'SECURE LOGIN'
                                      : 'CREATE ACCOUNT',
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                TextField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.text,
                                  cursorColor: const Color(0xFF111111),
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    hintText: '@username',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111111).withOpacity(0.25),
                                    ),
                                    labelStyle: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111111).withOpacity(0.5),
                                    ),
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF111111)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF111111), width: 2.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  cursorColor: const Color(0xFF111111),
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111111).withOpacity(0.5),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF111111)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF111111), width: 2.0),
                                    ),
                                  ),
                                ),

                                if (_authState == AuthState.Register) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    cursorColor: const Color(0xFF111111),
                                    style: const TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111111),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      labelStyle: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF111111).withOpacity(0.5),
                                      ),
                                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF111111)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: const Color(0xFF111111).withOpacity(0.15), width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF111111), width: 2.0),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 20),
                                
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF111111),
                                      foregroundColor: const Color(0xFFFFFFFF),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _handleAuthAction,
                                    child: _isLoading 
                                      ? const SizedBox(
                                          height: 20, 
                                          width: 20, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        )
                                      : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _authState == AuthState.Login ? 'LOGIN' : 'SIGN UP',
                                          style: const TextStyle(
                                            fontFamily: 'Hanken Grotesk',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color(0xFF2B54ED),
                                          size: 18,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF111111),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _authState = _authState == AuthState.Login 
                                          ? AuthState.Register 
                                          : AuthState.Login;
                                      _passwordController.clear();
                                      _confirmPasswordController.clear();
                                    });
                                  },
                                  child: Text(
                                    _authState == AuthState.Login 
                                        ? 'Create an account' 
                                        : 'Already have an account? Login',
                                    style: const TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const Spacer(flex: 3),
                        
                        Text(
                          'AES-256 TUNNEL ACTIVE\nDECENTRALIZED CRYPTOGRAPHY PROTOCOL',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 9,
                            color: const Color(0xFF111111).withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
        ),
      ),
    );
  }

  String _normalizeUsername(String input) {
    String trimmed = input.trim();
    if (!trimmed.startsWith('@')) {
      trimmed = '@$trimmed';
    }
    return trimmed.toLowerCase();
  }

  Future<void> _handleAuthAction() async {
    String username = _normalizeUsername(_usernameController.text);
    final password = _passwordController.text.trim();

    if (!MyUser.isValidUsername(username)) {
      _showErrorSnackBar('Username must start with @ and have at least 4 characters (e.g. @john).');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fakeEmail = MyUser.usernameToEmail(username);

      if (_authState == AuthState.Login) {
        final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: fakeEmail,
          password: password,
        );
        if (mounted) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).get();
          final storedUsername = doc.data()?['username'] ?? username;
          Provider.of<UserManager>(context, listen: false).createUser(
            storedUsername,
            result.user!.uid,
            doc.data()?['displayName'] ?? username,
            doc.data()?['profilePic'] ?? '',
          );
        }
      } else {
        final confirmPassword = _confirmPasswordController.text.trim();
        if (password != confirmPassword) {
          _showErrorSnackBar('Passwords do not match.');
          setState(() { _isLoading = false; });
          return;
        }

        final existingUser = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty) {
          _showErrorSnackBar('This username is already taken.');
          setState(() { _isLoading = false; });
          return;
        }

        final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: fakeEmail,
          password: password,
        );
        if (mounted) {
          Provider.of<UserManager>(context, listen: false).createUser(
            username,
            result.user!.uid,
            username,
            '',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No account found with that username.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that username.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid username or password.';
      } else {
        message = e.message ?? message;
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
