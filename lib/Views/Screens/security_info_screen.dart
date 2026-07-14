import 'package:flutter/material.dart';

class SecurityInfoScreen extends StatelessWidget {
  static const routeName = '/security-info';

  const SecurityInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Informations de sécurité',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Verrouillage au démarrage: tu peux activer un code et Face ID / empreinte.\n'
            '• Code “leurre”: si ce code est saisi, l’application efface les données locales (cache, préférences) et déconnecte le compte.\n'
            '• Médias: les images/fichiers sont envoyés via Firebase Storage et les messages via Firestore.\n'
            '• Confidentialité: évite d’activer l’aperçu des messages si tu veux que la notification ne montre pas le contenu.\n',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13.5,
              height: 1.45,
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'Important: le code leurre efface uniquement les données stockées sur ce téléphone. '
              'Les données distantes (Firestore/Storage) ne sont pas automatiquement supprimées.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

