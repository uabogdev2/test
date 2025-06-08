// Fichier pour exécuter les tests de débogage
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'test_join_lobby.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialisé avec succès');
    
    // Exécuter le test de jointure à un lobby
    debugPrint('⏳ Démarrage du test de jointure...');
    await TestJoinLobby.run();
    
  } catch (e) {
    debugPrint('❌ ERREUR: $e');
  }
} 