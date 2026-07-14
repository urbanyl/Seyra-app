import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:seyra/Models/app_settings.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  final _auth = LocalAuthentication();

  bool _isSubmitting = false;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricIfEnabled();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricIfEnabled() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;

    final settings = context.read<AppSettings>();
    if (!settings.lockBiometricEnabled) return;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return;
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Seyra',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) widget.onUnlocked();
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final settings = context.read<AppSettings>();
      final code = _controller.text.trim();
      if (code == AppSettings.panicCode) {
        await settings.panicWipe();
        if (!mounted) return;
        return;
      }

      final ok = await settings.verifyPasscode(code);
      if (!mounted) return;
      if (ok) {
        widget.onUnlocked();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code incorrect'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Text(
                'Seyra',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verrouillage',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? theme.colorScheme.surface
                      : Colors.white,
                  hintText: 'Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.colorScheme.tertiary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _isSubmitting ? '...' : 'Déverrouiller',
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _tryBiometricIfEnabled,
                child: const Text('Utiliser Face ID / Empreinte'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

