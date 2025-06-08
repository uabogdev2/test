import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/animated_background.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/lobby_service.dart';
import '../models/lobby.dart';
import 'lobby_screen.dart';
import '../theme/theme_constants.dart';

class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _isRefreshing = true);
        ref.refresh(publicLobbiesProvider);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _isRefreshing = false);
          }
        });
      }
    });
  }

  void _joinLobbyByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    debugPrint('🔍 Tentative de rejoindre avec le code: $code');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ Erreur: Utilisateur non connecté');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Utilisateur non connecté')),
        );
      }
      return;
    }
    debugPrint('👤 Utilisateur connecté: ${user.uid}');

    setState(() => _isJoining = true);

    try {
      final lobbyService = ref.read(lobbyServiceProvider);
      debugPrint('🔍 Recherche du lobby avec le code: $code');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lobbies')
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'waiting')
          .get()
          .catchError((error) {
            debugPrint('❌ Erreur Firestore: $error');
            throw Exception('Erreur lors de la recherche du lobby: $error');
          });

      debugPrint('📋 Résultats trouvés: ${querySnapshot.docs.length}');
      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Aucun lobby trouvé avec le code: $code');
        throw Exception('Aucune partie trouvée avec ce code');
      }

      final lobbyDoc = querySnapshot.docs.first;
      final lobby = Lobby.fromFirestore(lobbyDoc);
      debugPrint('✅ Lobby trouvé: ${lobby.id} avec ${lobby.playerIds.length} joueurs');

      if (lobby.isFull()) {
        debugPrint('❌ Le lobby est complet: ${lobby.playerIds.length}/${lobby.maxPlayers}');
        throw Exception('La partie est complète');
      }

      debugPrint('🔄 Tentative de rejoindre le lobby: ${lobby.id}');
      await lobbyService.joinLobby(
        lobbyId: lobby.id,
        playerName: user.displayName ?? 'Invité',
      );
      debugPrint('✅ Lobby rejoint avec succès');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(lobbyId: lobby.id),
          ),
        );
        debugPrint('🔄 Navigation vers l\'écran du lobby');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la jointure du lobby: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _joinPublicLobby(Lobby lobby) async {
    if (_isJoining) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isJoining = true);

    try {
      final lobbyService = ref.read(lobbyServiceProvider);
      await lobbyService.joinLobby(
        lobbyId: lobby.id,
        playerName: user.displayName ?? 'Invité',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(lobbyId: lobby.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final publicLobbies = ref.watch(publicLobbiesProvider);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Bouton retour en haut à gauche
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : primaryColor,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              
              // Bouton thème en haut à droite (profil et déconnexion supprimés)
              Positioned(
                top: 16,
                right: 16,
                child: const ThemeToggleButton(),
              ),
              
              // Titre et contenu principal
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Rejoindre une partie',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: ThemeConstants.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? ThemeConstants.nightCardColor
                            : ThemeConstants.dayCardColor,
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Code de la partie',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Entrez le code...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: isDark 
                                ? ThemeConstants.nightPrimaryGradient
                                : ThemeConstants.dayPrimaryGradient,
                            ),
                            child: ElevatedButton(
                              onPressed: _isJoining ? null : _joinLobbyByCode,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isJoining
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Rejoindre',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Parties publiques',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: publicLobbies.when(
                        data: (lobbies) {
                          if (lobbies.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Aucune partie publique disponible',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  if (_isRefreshing)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              setState(() => _isRefreshing = true);
                              ref.refresh(publicLobbiesProvider);
                              await Future.delayed(const Duration(seconds: 1));
                              if (mounted) {
                                setState(() => _isRefreshing = false);
                              }
                            },
                            child: ListView.builder(
                              itemCount: lobbies.length,
                              itemBuilder: (context, index) {
                                final lobby = lobbies[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: isDark
                                      ? ThemeConstants.nightCardColor
                                      : ThemeConstants.dayCardColor,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      'Partie de ${lobby.playerNames.first}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${lobby.playerIds.length}/${lobby.maxPlayers} joueurs',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: lobby.isFull() 
                                          ? LinearGradient(
                                              colors: [Colors.grey.shade600, Colors.grey.shade800],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : isDark 
                                            ? ThemeConstants.nightPrimaryGradient
                                            : ThemeConstants.dayPrimaryGradient,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isJoining || lobby.isFull()
                                            ? null
                                            : () => _joinPublicLobby(lobby),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          lobby.isFull() ? 'Complet' : 'Rejoindre',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Erreur de chargement',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              TextButton(
                                onPressed: () => ref.refresh(publicLobbiesProvider),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 