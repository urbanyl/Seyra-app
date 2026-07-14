import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_settings': 'App Settings',
      'account_settings': 'Account Settings',
      'security': 'Security',
      'security_info': 'Security Information',
      'lock': 'App Lock',
      'lock_enable': 'Require unlock at startup',
      'lock_biometric': 'Use Face ID / Fingerprint',
      'lock_change_code': 'Change passcode',
      'notifications': 'Notifications',
      'notifications_enable': 'Enable notifications',
      'notifications_preview': 'Show message preview',
      'language': 'Language',
      'language_fr': 'French',
      'language_en': 'English',
      'appearance': 'Appearance',
      'dark_mode': 'Dark mode',
      'theme_color': 'Theme color',
      'chat_hint': 'Type a message...',
      'attach': 'Attach',
      'send_file': 'Send File',
      'send_gif': 'Send GIF',
      'use_camera': 'Use Camera',
      'use_gallery': 'Use Gallery',
      'new_message': 'New message',
      'new_message_hidden': 'New message received',
      'tab_all': 'All',
      'tab_pv': 'PV',
      'tab_groups': 'Groups',
      'tab_calls': 'Calls',
    },
    'fr': {
      'app_settings': 'Paramètres',
      'account_settings': 'Paramètres du compte',
      'security': 'Sécurité',
      'security_info': 'Informations de sécurité',
      'lock': 'Verrouillage',
      'lock_enable': 'Demander un déverrouillage au démarrage',
      'lock_biometric': 'Utiliser Face ID / Empreinte',
      'lock_change_code': 'Changer le code',
      'notifications': 'Notifications',
      'notifications_enable': 'Activer les notifications',
      'notifications_preview': 'Afficher le contenu',
      'language': 'Langue',
      'language_fr': 'Français',
      'language_en': 'Anglais',
      'appearance': 'Apparence',
      'dark_mode': 'Mode sombre',
      'theme_color': 'Couleur du thème',
      'chat_hint': 'Écrire un message...',
      'attach': 'Joindre',
      'send_file': 'Envoyer un fichier',
      'send_gif': 'Envoyer un GIF',
      'use_camera': 'Caméra',
      'use_gallery': 'Galerie',
      'new_message': 'Nouveau message',
      'new_message_hidden': 'Nouveau message reçu',
      'tab_all': 'Tous',
      'tab_pv': 'PV',
      'tab_groups': 'Groupes',
      'tab_calls': 'Appels',
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    return _strings[lang]?[key] ?? _strings['en']![key] ?? key;
  }

  String get appSettings => _t('app_settings');
  String get accountSettings => _t('account_settings');
  String get security => _t('security');
  String get securityInfo => _t('security_info');
  String get lock => _t('lock');
  String get lockEnable => _t('lock_enable');
  String get lockBiometric => _t('lock_biometric');
  String get lockChangeCode => _t('lock_change_code');
  String get notifications => _t('notifications');
  String get notificationsEnable => _t('notifications_enable');
  String get notificationsPreview => _t('notifications_preview');
  String get language => _t('language');
  String get languageFr => _t('language_fr');
  String get languageEn => _t('language_en');
  String get appearance => _t('appearance');
  String get darkMode => _t('dark_mode');
  String get themeColor => _t('theme_color');
  String get chatHint => _t('chat_hint');
  String get useCamera => _t('use_camera');
  String get useGallery => _t('use_gallery');
  String get sendFile => _t('send_file');
  String get sendGif => _t('send_gif');
  String get newMessage => _t('new_message');
  String get newMessageHidden => _t('new_message_hidden');
  String get tabAll => _t('tab_all');
  String get tabPv => _t('tab_pv');
  String get tabGroups => _t('tab_groups');
  String get tabCalls => _t('tab_calls');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
