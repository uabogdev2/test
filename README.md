# mystic

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 🎮 Plan de Développement - Cercle Mystique

## Table des Matières
- [Phase 1: Foundation + Splash Animé + Thème Système](#phase-1-foundation--splash-animé--thème-système)
- [Phase 2: Authentification + Design Avancé + Chat Foundation](#phase-2-authentification--design-avancé--chat-foundation)
- [Phase 3: Lobby Système + Chat Lobby + Répartition Intelligente](#phase-3-lobby-système--chat-lobby--répartition-intelligente)
- [Phase 4: Logique de Jeu + Chat Contextuel + Animations de Phase](#phase-4-logique-de-jeu--chat-contextuel--animations-de-phase)
- [Phase 5: Polish + Chat Premium + Expérience Complète](#phase-5-polish--chat-premium--expérience-complète)
- [Architecture Technique](#architecture-technique-optimisée)
- [Responsive et Accessibilité](#responsive-et-accessibilité)
- [Optimisations Performances](#optimisations-performances)

## Phase 1: Foundation + Splash Animé + Thème Système
**Durée estimée : 3-4 jours**

### Livrables Core
- ✅ Configuration Firebase complète avec projet cercle-mystic
- ✅ Structure projet organisée (MVC + Services + Widgets)
- ✅ Navigation avec go_router et routes typées
- ✅ State Management avec Provider/Riverpod

### Livrables Design
#### Splash Screen Premium
- Logo lune (Icons.nightlight_round) → soleil (Icons.wb_sunny)
- Animation rotation 360° avec changement d'icône fluide
- Barre de progression circulaire animée
- Dégradé de fond nuit → jour
- Texte "Cercle Mystique" en animated_text_kit
- Durée totale : 3 secondes

#### Système de Thème Jour/Nuit
- Provider ThemeController pour gestion globale
- AnimatedContainer pour transitions fluides
- AnimatedTheme pour changements automatiques
- Bouton toggle avec animation lune ↔ soleil
- Sauvegarde préférence utilisateur

#### Design System de Base
- Typographie : Google Fonts Poppins
- Composants de base thématiques
- Système de spacing et borders cohérent
- Micro-animations interactives

### Tests Phase 1
- [ ] Splash screen avec animations complètes
- [ ] Transition lune → soleil fluide
- [ ] Barre de progression sans lag
- [ ] Toggle jour/nuit instantané
- [ ] Dégradés animés fluides
- [ ] Firebase connecté
- [ ] Navigation opérationnelle
- [ ] Préférences thème sauvegardées

[Suite du contenu formaté de manière similaire pour les autres phases...]

## Architecture Technique Optimisée

### Structure de Projet
```text
lib/
├── core/                    # Configuration et utilitaires
│   ├── themes/             # Système jour/nuit
│   ├── constants/          # Couleurs, tailles, durées
│   └── utils/              # Helpers et extensions
├── features/               # Fonctionnalités par modules
│   ├── auth/              # Authentification
│   ├── lobby/             # Système de lobby
│   ├── game/              # Logique de jeu
│   └── chat/              # Système de chat
├── shared/                # Composants partagés
│   ├── widgets/           # Widgets réutilisables
│   ├── animations/        # Animations communes
│   └── services/          # Services Firebase
└── presentation/          # Écrans et controllers
```

### Services Principaux
- ThemeService : Gestion jour/nuit avec animations
- ChatService : Communication temps réel adaptative
- GameService : Logique de jeu et synchronisation
- AnimationService : Orchestration des transitions
- AudioService : Effets sonores contextuels

[Le reste du contenu suit le même format...]
