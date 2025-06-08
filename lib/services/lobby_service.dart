import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lobby.dart';
import '../models/user_profile.dart';
import '../utils/role_distribution.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';

final lobbyServiceProvider = Provider((ref) => LobbyService());

// Provider pour les lobbies publics
final publicLobbiesProvider = StreamProvider<List<Lobby>>((ref) {
  return ref.read(lobbyServiceProvider).publicLobbies;
});

// Provider pour le lobby courant
final currentLobbyProvider = StreamProvider.family<Lobby?, String>((ref, lobbyId) {
  return ref.read(lobbyServiceProvider).lobbyStream(lobbyId);
});

class LobbyService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _random = Random();

  // Générer un code unique à 6 chiffres
  String _generateUniqueCode() {
    return (_random.nextInt(900000) + 100000).toString();
  }

  // Créer un nouveau lobby
  Future<Lobby> createLobby({
    required String hostName,
    required int maxPlayers,
    required bool isPublic,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // S'assurer que le profil utilisateur existe
    await _ensureUserProfile(user.uid, hostName);

    // Générer un code unique pour le lobby
    String code;
    bool isCodeUnique = false;
    do {
      code = _generateLobbyCode();
      final existingLobbies = await _firestore
          .collection('lobbies')
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'waiting')
          .get();
      isCodeUnique = existingLobbies.docs.isEmpty;
    } while (!isCodeUnique);

    // Calculer la répartition des rôles en fonction du nombre de joueurs
    final roleDistribution = RoleDistribution.calculateRoles(maxPlayers);

    final lobby = Lobby.create(
      hostId: user.uid,
      hostName: hostName,
      maxPlayers: maxPlayers.clamp(2, 24),  // Augmenté à 24 joueurs max
      isPublic: isPublic,
      code: code,
      roleDistribution: roleDistribution,
    );

    final lobbyRef = _firestore.collection('lobbies').doc(lobby.id);
    
    // Créer le document du lobby avec la répartition des rôles
    await lobbyRef.set(lobby.toFirestore());

    // Ajouter un message système pour la création du lobby
    await lobbyRef.collection('messages').add({
      'senderId': 'system',
      'senderName': 'Système',
      'content': 'Partie créée par $hostName',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'system',
    });

    return lobby;
  }

  // Générer un code de lobby unique
  String _generateLobbyCode() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    final codeLength = 6;
    return List.generate(codeLength, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Assurer que le profil utilisateur existe
  Future<void> _ensureUserProfile(String userId, String displayName) async {
    try {
      debugPrint('🔍 Vérification du profil utilisateur: $userId');
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get().catchError((error) {
        debugPrint('❌ Erreur lors de la récupération du profil: $error');
        throw Exception('Erreur lors de la récupération du profil: $error');
      });

      if (!userDoc.exists) {
        debugPrint("➕ Création d'un nouveau profil pour: $userId");
        // Créer un nouveau profil
        final profile = UserProfile(
          id: userId,
          displayName: displayName,
          photoURL: null,
          email: null,
          isAnonymous: true,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          stats: {
            'gamesPlayed': 0,
            'gamesWon': 0,
            'totalKills': 0,
          },
        );

        await userRef.set(profile.toFirestore()).catchError((error) {
          debugPrint('❌ Erreur lors de la création du profil: $error');
          throw Exception('Erreur lors de la création du profil: $error');
        });
        debugPrint('✅ Nouveau profil créé avec succès');
      } else {
        debugPrint('🔄 Mise à jour du lastSeen pour: $userId');
        // Mettre à jour le lastSeen
        await userRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((error) {
          debugPrint('⚠️ Erreur lors de la mise à jour de lastSeen: $error');
          // Ne pas propager cette erreur, c'est moins critique
        });
        debugPrint('✅ lastSeen mis à jour');
      }
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE lors de la gestion du profil: $e');
      rethrow;
    }
  }

  // Rejoindre un lobby
  Future<void> joinLobby({
    required String lobbyId,
    required String playerName,
  }) async {
    try {
      debugPrint('🔄 Tentative de rejoindre le lobby: $lobbyId avec le nom: $playerName');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Erreur: Utilisateur non connecté');
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('👤 Utilisateur connecté: ${user.uid}');

      // S'assurer que le profil utilisateur existe
      try {
        await _ensureUserProfile(user.uid, playerName);
        debugPrint('✅ Profil utilisateur vérifié/créé');
      } catch (e) {
        debugPrint('❌ Erreur lors de la vérification du profil: $e');
        throw Exception('Erreur lors de la vérification du profil: $e');
      }

      final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
      debugPrint('📋 Récupération des données du lobby: $lobbyId');
      
      final lobbyDoc = await lobbyRef.get().catchError((error) {
        debugPrint('❌ Erreur lors de la récupération du lobby: $error');
        throw Exception('Erreur lors de la récupération du lobby: $error');
      });
      
      if (!lobbyDoc.exists) {
        debugPrint('❌ Lobby introuvable: $lobbyId');
        throw Exception('Lobby introuvable');
      }

      final lobby = Lobby.fromFirestore(lobbyDoc);
      debugPrint('📋 Données du lobby récupérées: ${lobby.code} avec ${lobby.playerIds.length} joueurs');
      
      // Vérifier si le lobby est plein
      if (lobby.playerIds.length >= lobby.maxPlayers) {
        debugPrint('❌ Le lobby est complet: ${lobby.playerIds.length}/${lobby.maxPlayers}');
        throw Exception('Le lobby est complet');
      }

      // Vérifier si le joueur n'est pas déjà dans le lobby
      if (lobby.playerIds.contains(user.uid)) {
        debugPrint('❌ Le joueur est déjà dans ce lobby');
        throw Exception('Vous êtes déjà dans ce lobby');
      }

      // Vérifier si le lobby est en attente
      if (lobby.status != 'waiting') {
        debugPrint('❌ La partie a déjà commencé');
        throw Exception('La partie a déjà commencé');
      }

      // Ajouter le joueur au lobby
      debugPrint('➕ Ajout du joueur au lobby');
      await lobbyRef.update({
        'playerIds': FieldValue.arrayUnion([user.uid]),
        'playerNames': FieldValue.arrayUnion([playerName]),
      }).catchError((error) {
        debugPrint('❌ Erreur lors de l\'ajout du joueur: $error');
        throw Exception('Erreur lors de l\'ajout du joueur: $error');
      });

      // Ajouter un message système
      debugPrint('💬 Ajout du message système');
      await lobbyRef.collection('messages').add({
        'senderId': 'system',
        'senderName': 'Système',
        'content': '$playerName a rejoint la partie',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      }).catchError((error) {
        debugPrint('⚠️ Erreur lors de l\'ajout du message système: $error');
        // Ne pas propager cette erreur, c'est moins critique
      });
      
      debugPrint('✅ Joueur ajouté au lobby avec succès');
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE lors de l\'ajout au lobby: $e');
      rethrow;
    }
  }

  // Quitter un lobby
  Future<void> leaveLobby({
    required String lobbyId,
    required String playerId,
    required String playerName,
  }) async {
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    final lobbyDoc = await lobbyRef.get();
    
    if (!lobbyDoc.exists) return;
    
    final lobby = Lobby.fromFirestore(lobbyDoc);

    // Si c'est l'hôte qui quitte, supprimer le lobby
    if (lobby.isHost(playerId)) {
      try {
        // Ajouter d'abord le message système
        await lobbyRef.collection('messages').add({
          'senderId': 'system',
          'senderName': 'Système',
          'content': 'L\'hôte a quitté la partie. La partie a été fermée.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
        });
        
        // Supprimer le lobby
        await lobbyRef.delete();
      } catch (e) {
        print('Erreur lors de la suppression du lobby: $e');
        // Réessayer la suppression
        await Future.delayed(const Duration(milliseconds: 500));
        await lobbyRef.delete();
      }
    } else {
      try {
        // Ajouter d'abord le message système
        await lobbyRef.collection('messages').add({
          'senderId': 'system',
          'senderName': 'Système',
          'content': '$playerName a quitté la partie',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
        });

        // Mettre à jour la liste des joueurs
        await lobbyRef.update({
          'playerIds': FieldValue.arrayRemove([playerId]),
          'playerNames': FieldValue.arrayRemove([playerName]),
        });

        // Vérifier si le lobby est vide après le départ du joueur
        final updatedLobbyDoc = await lobbyRef.get();
        final updatedLobby = Lobby.fromFirestore(updatedLobbyDoc);
        
        if (updatedLobby.playerIds.isEmpty) {
          await lobbyRef.delete();
        }
      } catch (e) {
        print('Erreur lors du départ du joueur: $e');
        rethrow;
      }
    }
  }

  // Stream des lobbies publics
  Stream<List<Lobby>> get publicLobbies {
    return _firestore
        .collection('lobbies')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Erreur lors de la récupération des lobbies publics: $error');
          return [];
        })
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Lobby.fromFirestore(doc))
                .where((lobby) => 
                  lobby.playerIds.isNotEmpty && 
                  !lobby.isFull() &&
                  DateTime.now().difference(lobby.createdAt).inHours < 1
                )
                .toList();
          } catch (e) {
            print('Erreur lors de la conversion des lobbies: $e');
            return [];
          }
        });
  }

  // Stream d'un lobby spécifique
  Stream<Lobby?> lobbyStream(String lobbyId) {
    return _firestore
        .collection('lobbies')
        .doc(lobbyId)
        .snapshots()
        .map((doc) {
          try {
            if (!doc.exists) return null;
            return Lobby.fromFirestore(doc);
          } catch (e) {
            print('Erreur lors de la conversion du lobby: $e');
            return null;
          }
        });
  }

  // Démarrer une partie
  Future<void> startGame(String lobbyId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    final lobby = Lobby.fromFirestore(await lobbyRef.get());

    if (!lobby.isHost(user.uid)) {
      throw Exception('Seul l\'hôte peut démarrer la partie');
    }

    await lobbyRef.update({
      'status': 'playing',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // Assigner les rôles aux joueurs
  Map<String, String> _assignRoles(List<String> playerIds) {
    final int playerCount = playerIds.length;
    final roles = <String, String>{};
    
    // Calculer le nombre de chaque rôle selon l'algorithme du plan
    int wolves = (playerCount * 0.25).floor().clamp(1, playerCount ~/ 3);
    int specialRoles = 0;

    // Ajouter les loups-garous
    final wolfIndices = List.generate(playerCount, (i) => i)..shuffle(_random);
    for (int i = 0; i < wolves; i++) {
      roles[playerIds[wolfIndices[i]]] = 'loup_garou';
    }

    // Ajouter les rôles spéciaux selon le nombre de joueurs
    if (playerCount >= 6) {
      roles[playerIds[wolfIndices[wolves]]] = 'voyant';
      roles[playerIds[wolfIndices[wolves + 1]]] = 'sorciere';
      specialRoles += 2;
    }

    if (playerCount >= 8) {
      roles[playerIds[wolfIndices[wolves + 2]]] = 'chasseur';
      specialRoles += 1;
    }

    // Les joueurs restants sont villageois
    for (final playerId in playerIds) {
      if (!roles.containsKey(playerId)) {
        roles[playerId] = 'villageois';
      }
    }

    return roles;
  }
} 