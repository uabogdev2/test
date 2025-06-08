import 'package:flutter/material.dart';
import '../utils/role_distribution.dart';

class RoleDistributionPreview extends StatelessWidget {
  final int playerCount;
  final bool isDarkMode;
  final Map<String, int>? roleDistribution;

  const RoleDistributionPreview({
    Key? key,
    required this.playerCount,
    required this.isDarkMode,
    this.roleDistribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utiliser la répartition fournie ou calculer une nouvelle
    final Map<String, int> distribution = roleDistribution ?? RoleDistribution.calculateRoles(playerCount);
    
    // Convertir en liste pour l'affichage
    final List<MapEntry<String, int>> activeRoles = distribution.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        if (a.key == 'loup_garou') return -1;
        if (b.key == 'loup_garou') return 1;
        if (a.key == 'villageois') return 1;
        if (b.key == 'villageois') return -1;
        return 0;
      });
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withOpacity(0.2) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Répartition des rôles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.blue.shade800 
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$playerCount joueurs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          
          // Affichage horizontal avec Wrap pour éviter les débordements
          // Optimisé pour un meilleur espacement
          Wrap(
            spacing: 6, // Espacement horizontal réduit
            runSpacing: 6, // Espacement vertical réduit
            alignment: WrapAlignment.start,
            children: activeRoles.map((roleEntry) => 
              _buildRoleChip(roleEntry.key, roleEntry.value)
            ).toList(),
          ),
        ],
      ),
    );
  }

  // Widget de rôle compact pour l'affichage horizontal
  Widget _buildRoleChip(String roleId, int count) {
    final role = RoleDistribution.roles[roleId];
    if (role == null) return const SizedBox.shrink();
    
    // Réduire la taille des puces pour améliorer l'affichage
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: role.color.withOpacity(isDarkMode ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: role.color.withOpacity(isDarkMode ? 0.6 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role.icon,
            size: 14, // Taille d'icône réduite
            color: isDarkMode ? Colors.white : role.color,
          ),
          const SizedBox(width: 3), // Espacement réduit
          Text(
            role.name,
            style: TextStyle(
              fontSize: 11, // Police plus petite
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 3), // Espacement réduit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: role.color.withOpacity(isDarkMode ? 0.6 : 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 9, // Police plus petite
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : role.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 