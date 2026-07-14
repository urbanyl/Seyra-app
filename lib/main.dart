import 'package:seyra/Models/theme.dart';
import 'package:seyra/Models/app_settings.dart';
import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Screens/account_settings_screen.dart';
import 'package:seyra/Views/Screens/app_settings_screen.dart';
import 'package:seyra/Views/Screens/auth_screen.dart';
import 'package:seyra/Views/Screens/call_screen.dart';
import 'package:seyra/Views/Screens/chat_screen.dart';
import 'package:seyra/Views/Screens/contacts_screen.dart';
import 'package:seyra/Views/Screens/create_group.dart';
import 'package:seyra/Views/Screens/group_members_screen.dart';
import 'package:seyra/Views/Screens/lock_screen.dart';
import 'package:seyra/Views/Screens/security_info_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart' as sysPath;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:seyra/firebase_options.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:seyra/Services/notification_service.dart';
import 'package:seyra/l10n/app_localizations.dart';

import 'Views/Screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDir = await sysPath.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb && kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FirebaseAuth.instance.setSettings(forceRecaptchaFlow: true);
    } catch (_) {}
  }

  await NotificationService.instance.initialize();
  final appSettings = AppSettings();
  await appSettings.load();
  await appSettings.ensureDefaultPasscode();

  runApp(MyApp(appSettings: appSettings));
}

class MyApp extends StatelessWidget {
  final AppSettings appSettings;

  const MyApp({super.key, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserManager()),
        ChangeNotifierProvider(create: (context) => MyTheme()),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: Builder(builder: (context) {
        return FutureBuilder(
          future: Provider.of<MyTheme>(context, listen: false).setTheme(),
          builder: (context, asyncSnapshot) => asyncSnapshot.connectionState ==
                  ConnectionState.waiting
              ? Center()
              : Consumer<MyTheme>(
                  builder: (context, myTheme, child) => MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Seyra',
                    theme: myTheme.getTheme,
                    locale: context.watch<AppSettings>().locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: StreamBuilder(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, userSnapshot) {
                          return userSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                )
                              : userSnapshot.hasData
                                  ? const _LockGate(child: HomePage())
                                  : AuthPage();
                        }),
                    routes: {
                      ContactsPage.ROUTE_NAME: (context) => ContactsPage(),
                      ChatScreen.ROUTE_NAME: (context) => ChatScreen(),
                      AccountSettingPage.ROUTE_NAME: (context) =>
                          AccountSettingPage(),
                      CreateGroupPage.ROUTE_NAME: (context) =>
                          CreateGroupPage(),
                      CallPage.ROUTE_NAME: (context) => CallPage(),
                      GroupMembersPage.ROUTE_NAME: (context) => const GroupMembersPage(),
                      AppSettingsScreen.routeName: (context) => const AppSettingsScreen(),
                      SecurityInfoScreen.routeName: (context) => const SecurityInfoScreen(),
                    },
                  ),
                ),
        );
      }),
    );
  }
}

class _LockGate extends StatefulWidget {
  final Widget child;

  const _LockGate({required this.child});

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  bool _unlocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<AppSettings>();
    if (!settings.lockEnabled && !_unlocked) {
      _unlocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    if (!settings.lockEnabled) return widget.child;
    if (_unlocked) return widget.child;
    return LockScreen(
      onUnlocked: () {
        if (!mounted) return;
        setState(() => _unlocked = true);
      },
    );
  }
}
