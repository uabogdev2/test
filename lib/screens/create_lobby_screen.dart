import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/lobby_service.dart';
import '../services/auth_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/theme_constants.dart';
import '../widgets/role_distribution_preview.dart';
import 'lobby_screen.dart';

class CreateLobbyScreen extends ConsumerStatefulWidget {
  const CreateLobbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends ConsumerState<CreateLobbyScreen> {
  int _selectedPlayers = 6;
  bool _isPublic = true;
  bool _isLoading = false;

  void _createLobby() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final lobby = await ref.read(lobbyServiceProvider).createLobby(
        hostName: user.displayName ?? 'Invité',
        maxPlayers: _selectedPlayers,
        isPublic: _isPublic,
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
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barre de navigation supérieure
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton retour
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : primaryColor,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    
                    // Titre centré
                    Text(
                      'Créer une partie',
                      style: TextStyle(
                        fontFamily: ThemeConstants.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    
                    // Bouton thème uniquement (profil supprimé)
                    const ThemeToggleButton(),
                  ],
                ),
              ),
              
              // Contenu principal avec défilement
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section nombre de joueurs
                      _buildSection(
                        context,
                        title: 'Nombre de joueurs',
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge nombre de joueurs
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isDark 
                                  ? Colors.blue.shade900.withOpacity(0.6) 
                                  : Colors.blue.shade100,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: isDark ? Colors.white : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_selectedPlayers joueurs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Contrôles
                            Row(
                              children: [
                                _buildCounterButton(
                                  icon: Icons.remove,
                                  onPressed: _selectedPlayers > 6
                                      ? () => setState(() => _selectedPlayers--)
                                      : null,
                                  isDark: isDark,
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$_selectedPlayers',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                _buildCounterButton(
                                  icon: Icons.add,
                                  onPressed: _selectedPlayers < 24
                                      ? () => setState(() => _selectedPlayers++)
                                      : null,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Section visibilité
                      _buildSection(
                        context,
                        title: 'Visibilité',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Colonne avec texte et limites de largeur pour éviter le débordement
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Partie publique',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isPublic
                                            ? 'Accessible à tous'
                                            : 'Accessible uniquement avec le code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Espace pour séparer le texte du switch
                                const SizedBox(width: 16),
                                // Switch sur la droite
                                Switch(
                                  value: _isPublic,
                                  onChanged: (value) => setState(() => _isPublic = value),
                                  activeColor: isDark ? Colors.blue.shade300 : primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Section répartition des rôles
                      _buildSection(
                        context,
                        title: 'Répartition des rôles',
                        titleBadge: '$_selectedPlayers joueurs',
                        content: RoleDistributionPreview(
                          playerCount: _selectedPlayers,
                          isDarkMode: isDark,
                        ),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Bouton de création
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isDark 
                      ? ThemeConstants.nightPrimaryGradient
                      : ThemeConstants.dayPrimaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createLobby,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Créer la partie',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour créer un bouton d'ajustement du nombre de joueurs
  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.blue.shade800.withOpacity(0.4)
            : Colors.blue.shade100,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isDark ? Colors.white : Colors.blue.shade800,
        iconSize: 20,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  // Widget pour créer une section avec un titre et un contenu
  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? titleBadge,
    required Widget content,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? ThemeConstants.nightCardColor.withOpacity(0.9)
            : ThemeConstants.dayCardColor,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (titleBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    titleBadge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
} 