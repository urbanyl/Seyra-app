import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings with ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  static const _keyLocale = 'app.locale';
  static const _keyNotificationsEnabled = 'app.notifications.enabled';
  static const _keyNotificationsPreview = 'app.notifications.preview';
  static const _keyLockEnabled = 'app.lock.enabled';
  static const _keyLockBiometric = 'app.lock.biometric';

  static const _secureKeyPasscode = 'app.lock.passcode';

  static const String panicCode = '0000';
  static const String _defaultPasscode = '1234';

  Locale? _locale;
  bool _notificationsEnabled = true;
  bool _notificationsPreview = true;
  bool _lockEnabled = true;
  bool _lockBiometricEnabled = true;

  Locale? get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notificationsPreview => _notificationsPreview;
  bool get lockEnabled => _lockEnabled;
  bool get lockBiometricEnabled => _lockBiometricEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_keyLocale);
    _locale = (localeCode == null || localeCode.isEmpty) ? null : Locale(localeCode);
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _notificationsPreview = prefs.getBool(_keyNotificationsPreview) ?? true;
    _lockEnabled = prefs.getBool(_keyLockEnabled) ?? true;
    _lockBiometricEnabled = prefs.getBool(_keyLockBiometric) ?? true;
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    _locale = locale;
    if (locale == null) {
      await prefs.remove(_keyLocale);
    } else {
      await prefs.setString(_keyLocale, locale.languageCode);
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = value;
    await prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setNotificationsPreview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsPreview = value;
    await prefs.setBool(_keyNotificationsPreview, value);
    notifyListeners();
  }

  Future<void> setLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = value;
    await prefs.setBool(_keyLockEnabled, value);
    notifyListeners();
  }

  Future<void> setLockBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _lockBiometricEnabled = value;
    await prefs.setBool(_keyLockBiometric, value);
    notifyListeners();
  }

  Future<void> ensureDefaultPasscode() async {
    final current = await _storage.read(key: _secureKeyPasscode);
    if (current == null || current.isEmpty) {
      await _storage.write(key: _secureKeyPasscode, value: _defaultPasscode);
    }
  }

  Future<void> setPasscode(String passcode) async {
    await _storage.write(key: _secureKeyPasscode, value: passcode);
  }

  Future<bool> verifyPasscode(String passcode) async {
    final current = await _storage.read(key: _secureKeyPasscode);
    return (current ?? _defaultPasscode) == passcode;
  }

  Future<void> panicWipe() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await Hive.deleteFromDisk();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    try {
      await _storage.deleteAll();
    } catch (_) {}

    await load();
    notifyListeners();
  }
}

