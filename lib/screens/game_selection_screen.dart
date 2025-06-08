import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/animated_background.dart';
import '../widgets/theme_toggle_button.dart';
import '../services/auth_service.dart';
import '../theme/theme_constants.dart';
import 'create_lobby_screen.dart';
import 'join_lobby_screen.dart';
import '../debug/test_join_lobby.dart';
import 'profile_screen.dart';

class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  int _titleTapCount = 0;
  bool _isDebugging = false;

  void _handleTitleTap() {
    setState(() {
      _titleTapCount++;
      if (_titleTapCount == 3) {
        _runDebugTests();
        _titleTapCount = 0;
      }
    });
  }

  Future<void> _runDebugTests() async {
    setState(() {
      _isDebugging = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Démarrage des tests de débogage...'),
          backgroundColor: Colors.orange,
        ),
      );
      
      await TestJoinLobby.run();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tests terminés, vérifiez les logs'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDebugging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final authService = ref.watch(authServiceProvider);
    final user = ref.watch(userProvider);
    
    final userName = user?.displayName ?? 'Mystique';

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Boutons en haut à droite
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        color: isDark ? Colors.white : primaryColor,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      tooltip: 'Profil',
                    ),
                    const SizedBox(width: 8),
                    const ThemeToggleButton(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: isDark ? Colors.white : primaryColor,
                        size: 28,
                      ),
                      onPressed: () async {
                        await authService.signOut();
                      },
                      tooltip: 'Déconnexion',
                    ),
                  ],
                ),
              ),
              
              if (_isDebugging)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              // Contenu principal
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre (avec gesture detector pour débogage)
                    GestureDetector(
                      onTap: _handleTitleTap,
                      child: Text(
                        'Cercle Mystique',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontFamily: ThemeConstants.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // En-tête avec accueil personnalisé
                    Card(
                      elevation: 8,
                      shadowColor: isDark 
                        ? Colors.black.withOpacity(0.4) 
                        : primaryColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDark 
                        ? ThemeConstants.nightCardColor
                        : ThemeConstants.dayCardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              'Bienvenue $userName',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark ? Colors.white : primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Créez ou rejoignez une partie pour commencer l\'aventure',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Boutons principaux
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isDark 
                          ? ThemeConstants.nightPrimaryGradient
                          : ThemeConstants.dayPrimaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.black : primaryColor).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateLobbyScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Créer une partie',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isDark 
                            ? [ThemeConstants.nightSecondaryGradient.colors.first, ThemeConstants.nightSecondaryGradient.colors.last]
                            : [ThemeConstants.daySecondaryGradient.colors.first, ThemeConstants.daySecondaryGradient.colors.last],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinLobbyScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Rejoindre une partie',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Options supplémentaires
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRoundButton(
                          context,
                          isDark,
                          primaryColor,
                          Icons.help_outline,
                          'Aide',
                          () {
                            // TODO: Afficher l'aide
                          },
                        ),
                        _buildRoundButton(
                          context,
                          isDark,
                          primaryColor,
                          Icons.settings,
                          'Paramètres',
                          () {
                            // TODO: Ouvrir les paramètres
                          },
                        ),
                        _buildRoundButton(
                          context,
                          isDark,
                          primaryColor,
                          Icons.star_border,
                          'À propos',
                          () {
                            // TODO: Afficher à propos
                          },
                        ),
                      ],
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
  
  Widget _buildRoundButton(
    BuildContext context, 
    bool isDark, 
    Color primaryColor, 
    IconData icon, 
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.indigo.shade800, Colors.indigo.shade900]
                : [Colors.orange.shade300, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : primaryColor).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            iconSize: 26,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 