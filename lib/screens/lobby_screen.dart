import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/lobby_service.dart';
import '../models/lobby.dart';
import '../widgets/animated_background.dart';
import '../widgets/lobby_chat.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/theme_constants.dart';
import '../widgets/role_distribution_preview.dart';

class LobbyScreen extends ConsumerWidget {
  final String lobbyId;

  const LobbyScreen({
    Key? key,
    required this.lobbyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final lobbyAsync = ref.watch(currentLobbyProvider(lobbyId));
    final currentUser = FirebaseAuth.instance.currentUser;

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
                  onPressed: () {
                    ref.read(lobbyServiceProvider).leaveLobby(
                      lobbyId: lobbyId,
                      playerId: currentUser?.uid ?? '',
                      playerName: currentUser?.displayName ?? 'Invité',
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
              
              // Boutons en haut à droite
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    lobbyAsync.when(
                      data: (lobby) => lobby != null 
                        ? IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: isDark ? Colors.white : primaryColor,
                              size: 28,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: lobby.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copié !')),
                              );
                            },
                            tooltip: 'Copier le code',
                          )
                        : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
              
              // Titre et contenu principal
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                child: lobbyAsync.when(
                  data: (lobby) {
                    if (lobby == null) {
                      return const Center(
                        child: Text('Lobby introuvable'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Salle d\'attente',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontFamily: ThemeConstants.fontFamily,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : primaryColor,
                              ),
                            ),
                            if (lobby.isHost(currentUser?.uid ?? '')) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  color: isDark ? Colors.white : primaryColor,
                                  size: 24,
                                ),
                                onPressed: () {
                                  // Ouvrir les paramètres du lobby
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Paramètres de la partie'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // TODO: Ajouter les paramètres ici
                                          Text('Paramètres à venir...'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Fermer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'Paramètres',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Code de la partie',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 36,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        ref.read(lobbyServiceProvider).leaveLobby(
                                          lobbyId: lobbyId,
                                          playerId: currentUser?.uid ?? '',
                                          playerName: currentUser?.displayName ?? 'Invité',
                                        );
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 18),
                                      label: const Text(
                                        'Quitter',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lobby.code,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Joueurs (${lobby.playerIds.length}/${lobby.maxPlayers})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                lobby.playerNames.length,
                                (index) => ListTile(
                                  leading: Icon(
                                    lobby.playerIds[index] == lobby.hostId
                                        ? Icons.star
                                        : Icons.person,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  title: Text(
                                    lobby.playerNames[index],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  trailing: lobby.isHost(currentUser?.uid ?? '') &&
                                          lobby.playerIds[index] != lobby.hostId
                                      ? IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: Colors.red,
                                          onPressed: () {
                                            ref.read(lobbyServiceProvider).leaveLobby(
                                              lobbyId: lobbyId,
                                              playerId: lobby.playerIds[index],
                                              playerName: lobby.playerNames[index],
                                            );
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              
                              // Affichage de la répartition des rôles si la partie n'a pas commencé
                              if (lobby.status == 'waiting' && lobby.roleDistribution.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Répartition des rôles',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RoleDistributionPreview(
                                  playerCount: lobby.maxPlayers,
                                  isDarkMode: isDark,
                                  roleDistribution: lobby.roleDistribution,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: LobbyChat(
                            lobbyId: lobbyId,
                            userId: currentUser?.uid ?? '',
                            userName: currentUser?.displayName ?? 'Invité',
                          ),
                        ),
                        if (lobby.isHost(currentUser?.uid ?? ''))
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: lobby.playerIds.length >= 4
                                  ? isDark 
                                    ? ThemeConstants.nightPrimaryGradient
                                    : ThemeConstants.dayPrimaryGradient
                                  : LinearGradient(
                                      colors: [Colors.grey.shade400, Colors.grey.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              ),
                              child: ElevatedButton(
                                onPressed: lobby.playerIds.length >= 4
                                  ? () {
                                      ref.read(lobbyServiceProvider).startGame(lobbyId);
                                    }
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Démarrer la partie',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Erreur: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 