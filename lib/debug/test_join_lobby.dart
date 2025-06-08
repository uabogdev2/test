// Un utilitaire de test pour déboguer la fonctionnalité de jointure à un lobby
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/lobby.dart';

class TestJoinLobby {
  static Future<void> run() async {
    try {
      // Assurez-vous que Firebase est initialisé
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialisé avec succès');
      
      // Vérifier l'authentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Erreur: Utilisateur non connecté');
        return;
      }
      debugPrint('👤 Utilisateur connecté: ${user.uid}');
      
      // Rechercher des lobbies publics pour tester
      debugPrint('🔍 Recherche de lobbies publics...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lobbies')
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Aucun lobby public trouvé');
        return;
      }
      
      final lobbyDoc = querySnapshot.docs.first;
      final lobby = Lobby.fromFirestore(lobbyDoc);
      debugPrint('✅ Lobby trouvé: ${lobby.id} (${lobby.code})');
      debugPrint('📊 Joueurs actuels: ${lobby.playerIds.length}/${lobby.maxPlayers}');
      debugPrint('👑 Hôte: ${lobby.hostId}');
      
      // Tester si l'utilisateur peut rejoindre ce lobby
      if (lobby.playerIds.contains(user.uid)) {
        debugPrint('! Vous êtes déjà dans ce lobby');
        // Si l'utilisateur est déjà dans le lobby, on n'essaie pas de le rejoindre à nouveau
        return;
      }
      
      if (lobby.playerIds.length >= lobby.maxPlayers) {
        debugPrint('⚠️ Le lobby est complet');
        return;
      }
      
      // Tenter de rejoindre le lobby
      debugPrint('🔄 Tentative de rejoindre le lobby...');
      try {
        await FirebaseFirestore.instance
            .collection('lobbies')
            .doc(lobby.id)
            .update({
          'playerIds': FieldValue.arrayUnion([user.uid]),
          'playerNames': FieldValue.arrayUnion([user.displayName ?? 'Invité']),
        });
        
        debugPrint('✅ Lobby rejoint avec succès!');
        
        // Ajouter un message système
        await FirebaseFirestore.instance
            .collection('lobbies')
            .doc(lobby.id)
            .collection('messages')
            .add({
          'senderId': 'system',
          'senderName': 'Système',
          'content': '${user.displayName ?? 'Invité'} a rejoint la partie',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
        });
        
        // Vérifier que la jointure a fonctionné
        final updatedLobbyDoc = await FirebaseFirestore.instance
            .collection('lobbies')
            .doc(lobby.id)
            .get();
        
        final updatedLobby = Lobby.fromFirestore(updatedLobbyDoc);
        debugPrint('📊 Joueurs après jointure: ${updatedLobby.playerIds.length}/${updatedLobby.maxPlayers}');
        debugPrint('✅ TEST TERMINÉ AVEC SUCCÈS');
      } catch (e) {
        debugPrint('❌ Erreur lors de la tentative de rejoindre le lobby: $e');
      }
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE: $e');
    }
  }
} 