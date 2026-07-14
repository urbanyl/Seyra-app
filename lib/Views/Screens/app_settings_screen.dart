import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seyra/Models/app_settings.dart';
import 'package:seyra/Models/theme.dart';
import 'package:seyra/l10n/app_localizations.dart';

class AppSettingsScreen extends StatelessWidget {
  static const routeName = '/app-settings';

  const AppSettingsScreen({Key? key}) : super(key: key);

  Future<void> _showChangePasscodeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final controller2 = TextEditingController();
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Changer le code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau code',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller2,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final a = controller.text.trim();
                final b = controller2.text.trim();
                if (a.isEmpty || a != b) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Codes non identiques'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                await context.read<AppSettings>().setPasscode(a);
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: theme.colorScheme.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();
    final myTheme = context.watch<MyTheme>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appSettings),
      ),
      body: ListView(
        children: [
          _sectionTitle(context, t.lock.toUpperCase()),
          SwitchListTile(
            value: settings.lockEnabled,
            onChanged: (v) => context.read<AppSettings>().setLockEnabled(v),
            title: Text(
              t.lockEnable,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            value: settings.lockBiometricEnabled,
            onChanged: settings.lockEnabled
                ? (v) => context.read<AppSettings>().setLockBiometricEnabled(v)
                : null,
            title: Text(
              t.lockBiometric,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            enabled: settings.lockEnabled,
            title: Text(
              t.lockChangeCode,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: settings.lockEnabled ? () => _showChangePasscodeDialog(context) : null,
          ),

          _sectionTitle(context, t.notifications.toUpperCase()),
          SwitchListTile(
            value: settings.notificationsEnabled,
            onChanged: (v) => context.read<AppSettings>().setNotificationsEnabled(v),
            title: Text(
              t.notificationsEnable,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            value: settings.notificationsPreview,
            onChanged: settings.notificationsEnabled
                ? (v) => context.read<AppSettings>().setNotificationsPreview(v)
                : null,
            title: Text(
              t.notificationsPreview,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
          ),

          _sectionTitle(context, t.language.toUpperCase()),
          ListTile(
            title: Text(
              t.language,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Locale?>(
                value: settings.locale,
                onChanged: (loc) => context.read<AppSettings>().setLocale(loc),
                items: [
                  const DropdownMenuItem<Locale?>(
                    value: null,
                    child: Text('Auto'),
                  ),
                  DropdownMenuItem<Locale?>(
                    value: const Locale('fr'),
                    child: Text(t.languageFr),
                  ),
                  DropdownMenuItem<Locale?>(
                    value: const Locale('en'),
                    child: Text(t.languageEn),
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle(context, t.appearance.toUpperCase()),
          SwitchListTile(
            value: myTheme.isDarkMode,
            onChanged: (v) => context.read<MyTheme>().setDarkMode(v),
            title: Text(
              t.darkMode,
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surface
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.themeColor,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ThemePreDifendColors.values.map((c) {
                      final color = context.read<MyTheme>().appPreDefinedColors[c]!;
                      final isSelected = myTheme.selectedMainColorValue?.value == color.value;
                      return InkWell(
                        onTap: () => context.read<MyTheme>().selectedMainColor(c),
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 40 : 34,
                          height: isSelected ? 40 : 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.onSurface : theme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

