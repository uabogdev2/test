import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_constants.dart';
import '../theme/theme_controller.dart';
import '../constants/strings.dart';
import 'dart:math' as math;

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeControllerProvider);

    return Tooltip(
      message: isDarkMode ? Strings.themeToggleLight : Strings.themeToggleDark,
      child: GestureDetector(
        onTap: () {
          // Ajouter un léger feedback haptique
          HapticFeedback.mediumImpact();
          ref.read(themeControllerProvider.notifier).toggleTheme();
        },
        child: AnimatedContainer(
          duration: ThemeConstants.animationDuration,
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isDarkMode 
              ? ThemeConstants.nightSecondaryGradient
              : ThemeConstants.daySecondaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode 
                  ? ThemeConstants.nightAccent
                  : ThemeConstants.dayAccent).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Effet de glow autour de l'icône
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                          ? ThemeConstants.nightAccent.withOpacity(0.6)
                          : ThemeConstants.dayAccent.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Icône animée
              Center(
                child: AnimatedSwitcher(
                  duration: ThemeConstants.animationDuration,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    key: ValueKey<bool>(isDarkMode),
                    color: Colors.white,
                    size: 32,
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