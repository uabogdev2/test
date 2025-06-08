import 'package:flutter/material.dart';

class Role {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  
  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class RoleDistribution {
  // Liste des rôles disponibles
  static const Map<String, Role> roles = {
    'villageois': Role(
      id: 'villageois',
      name: 'Villageois',
      description: 'Doit découvrir et éliminer les loups-garous',
      icon: Icons.home,
      color: Colors.green,
    ),
    'loup_garou': Role(
      id: 'loup_garou',
      name: 'Loup-Garou',
      description: 'Doit éliminer tous les villageois',
      icon: Icons.dark_mode,
      color: Colors.red,
    ),
    'voyant': Role(
      id: 'voyant',
      name: 'Voyant',
      description: 'Peut voir le rôle d\'un joueur chaque nuit',
      icon: Icons.visibility,
      color: Colors.purple,
    ),
    'sorciere': Role(
      id: 'sorciere',
      name: 'Sorcière',
      description: 'Possède deux potions : vie et mort',
      icon: Icons.science,
      color: Colors.deepPurple,
    ),
    'chasseur': Role(
      id: 'chasseur',
      name: 'Chasseur',
      description: 'Peut tuer un joueur en mourant',
      icon: Icons.sports_handball,
      color: Colors.brown,
    ),
    'cupidon': Role(
      id: 'cupidon',
      name: 'Cupidon',
      description: 'Désigne deux amoureux liés par le destin',
      icon: Icons.favorite,
      color: Colors.pink,
    ),
    'garde': Role(
      id: 'garde',
      name: 'Garde',
      description: 'Peut protéger un joueur chaque nuit',
      icon: Icons.shield,
      color: Colors.blue,
    ),
    'petite_fille': Role(
      id: 'petite_fille',
      name: 'Petite Fille',
      description: 'Peut espionner les loups-garous la nuit',
      icon: Icons.face,
      color: Colors.lightBlue,
    ),
    'maire': Role(
      id: 'maire',
      name: 'Maire',
      description: 'Son vote compte double lors des éliminations',
      icon: Icons.stars,
      color: Colors.amber,
    ),
  };

  /// Calcule la répartition des rôles en fonction du nombre de joueurs
  static Map<String, int> calculateRoles(int playerCount) {
    // Nombre de loups-garous basé sur ~25% des joueurs
    int wolves = (playerCount * 0.25).floor().clamp(1, playerCount ~/ 3);
    
    Map<String, int> distribution = {
      'villageois': 0,
      'loup_garou': wolves,
      'voyant': playerCount >= 6 ? 1 : 0,
      'sorciere': playerCount >= 7 ? 1 : 0,
      'chasseur': playerCount >= 8 ? 1 : 0,
      'cupidon': playerCount >= 10 ? 1 : 0,
      'garde': playerCount >= 12 ? 1 : 0,
      'maire': playerCount >= 14 ? 1 : 0,
      'petite_fille': playerCount >= 16 ? 1 : 0,
    };
    
    // Calculer le nombre de villageois (reste des joueurs)
    int specialRoles = 0;
    for (var entry in distribution.entries) {
      if (entry.key != 'villageois') {
        specialRoles += entry.value;
      }
    }
    
    distribution['villageois'] = playerCount - specialRoles;
    
    return distribution;
  }
  
  /// Obtenir une liste ordonnée des rôles actifs avec leur compte
  static List<MapEntry<String, int>> getActiveRolesList(int playerCount) {
    final Map<String, int> distribution = calculateRoles(playerCount);
    
    // Filtrer les rôles avec un compte > 0 et les trier
    List<MapEntry<String, int>> activeRoles = distribution.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    // Tri personnalisé: d'abord les loups, puis les rôles spéciaux, puis les villageois
    activeRoles.sort((a, b) {
      if (a.key == 'loup_garou') return -1;
      if (b.key == 'loup_garou') return 1;
      if (a.key == 'villageois') return 1;
      if (b.key == 'villageois') return -1;
      return 0;
    });
    
    return activeRoles;
  }
} 