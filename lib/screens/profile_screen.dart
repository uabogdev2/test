import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/animated_background.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../theme/theme_constants.dart';
import '../widgets/theme_toggle_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final newName = _displayNameController.text.trim();
      if (newName.isEmpty) {
        throw Exception('Le nom ne peut pas être vide');
      }

      await ref.read(authServiceProvider).updateDisplayName(user.uid, newName);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return Scaffold(
        body: AnimatedBackground(
          child: Center(
            child: Text(
              'Utilisateur non connecté',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Bouton de retour en haut à gauche
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              
              // Bouton thème en haut au centre
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: const ThemeToggleButton(),
                ),
              ),
              
              // Bouton d'édition en haut à droite
              Positioned(
                top: 16,
                right: 16,
                child: !_isEditing 
                  ? IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: isDark ? Colors.white : Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      tooltip: 'Modifier le profil',
                    )
                  : const SizedBox.shrink(),
              ),
              
              Consumer(
                builder: (context, ref, child) {
                  final userProfileAsync = ref.watch(userProfileProvider(user.uid));
                  
                  return userProfileAsync.when(
                    data: (userProfile) {
                      if (userProfile == null) {
                        return const Center(
                          child: Text('Profil non trouvé'),
                        );
                      }

                      if (!_isEditing && _displayNameController.text != userProfile.displayName) {
                        _displayNameController.text = userProfile.displayName;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 80.0),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              // Titre de la page
                              Text(
                                'Profil Utilisateur',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: ThemeConstants.fontFamily,
                                  color: isDark ? Colors.white : Theme.of(context).primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // Avatar
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: isDark 
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.secondary,
                                child: Text(
                                  userProfile.displayName.isNotEmpty 
                                      ? userProfile.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Nom d'utilisateur
                              if (_isEditing) ...[
                                TextField(
                                  controller: _displayNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom d\'utilisateur',
                                    hintText: 'Entrez votre nouveau nom',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    errorText: _errorMessage,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _updateDisplayName,
                                      icon: _isLoading 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: const Text('Enregistrer'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton.icon(
                                      onPressed: _isLoading 
                                          ? null 
                                          : () {
                                              setState(() {
                                                _isEditing = false;
                                                _errorMessage = null;
                                                _displayNameController.text = userProfile.displayName;
                                              });
                                            },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Annuler'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  userProfile.displayName,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              
                              // Informations de base
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Informations',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Divider(),
                                      ListTile(
                                        leading: const Icon(Icons.email),
                                        title: const Text('Email'),
                                        subtitle: Text(
                                          userProfile.email ?? 'Non spécifié',
                                          style: TextStyle(
                                            fontStyle: userProfile.email == null 
                                                ? FontStyle.italic 
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.verified_user),
                                        title: const Text('Type de compte'),
                                        subtitle: Text(
                                          userProfile.isAnonymous 
                                              ? 'Compte invité' 
                                              : 'Compte connecté',
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.calendar_today),
                                        title: const Text('Membre depuis'),
                                        subtitle: Text(
                                          '${userProfile.createdAt.day}/${userProfile.createdAt.month}/${userProfile.createdAt.year}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Statistiques
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Statistiques',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Divider(),
                                      ListTile(
                                        leading: const Icon(Icons.videogame_asset),
                                        title: const Text('Parties jouées'),
                                        trailing: Text(
                                          '${userProfile.stats['gamesPlayed'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.emoji_events),
                                        title: const Text('Victoires'),
                                        trailing: Text(
                                          '${userProfile.stats['gamesWon'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erreur: $error'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
