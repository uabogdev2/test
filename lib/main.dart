import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/game_selection_screen.dart';
import 'services/auth_service.dart';
import 'widgets/theme_toggle_button.dart';
import 'widgets/animated_background.dart';
import 'constants/strings.dart';
import 'services/lobby_service.dart';
import 'dart:async';

// Classe pour les messages courts en français
class FrShortMessages implements timeago.LookupMessages {
  @override String prefixAgo() => 'il y a';
  @override String prefixFromNow() => 'dans';
  @override String suffixAgo() => '';
  @override String suffixFromNow() => '';
  @override String lessThanOneMinute(int seconds) => 'à l\'instant';
  @override String aboutAMinute(int minutes) => '1 min';
  @override String minutes(int minutes) => '$minutes min';
  @override String aboutAnHour(int minutes) => '1h';
  @override String hours(int hours) => '${hours}h';
  @override String aDay(int hours) => '1j';
  @override String days(int days) => '${days}j';
  @override String aboutAMonth(int days) => '1m';
  @override String months(int months) => '${months}m';
  @override String aboutAYear(int year) => '1a';
  @override String years(int years) => '${years}a';
  @override String wordSeparator() => ' ';
}

void main() {
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('🚀 Démarrage de l\'application...');

      // Initialiser Firebase
      try {
        debugPrint('🔥 Tentative d\'initialisation de Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialisé avec succès');
      } catch (firebaseError) {
        debugPrint('❌ Erreur Firebase: $firebaseError');
        throw Exception('Erreur d\'initialisation Firebase: $firebaseError');
      }

      // Initialiser timeago en français
      timeago.setLocaleMessages('fr', timeago.FrMessages());
      timeago.setDefaultLocale('fr');
      
      // Ajouter un locale court en français
      timeago.setLocaleMessages('fr_short', FrShortMessages());
      debugPrint('🌍 Localisation initialisée');

      debugPrint('🎯 Lancement de l\'application principale...');
      runApp(const ProviderScope(child: MyApp()));
      debugPrint('✅ Application principale lancée');

    } catch (e, stack) {
      debugPrint('❌ ERREUR CRITIQUE: $e');
      debugPrint('📚 Stack trace: $stack');

      runApp(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Erreur de démarrage',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('🔄 Tentative de redémarrage...');
                      main();
                    },
                    child: const Text('Redémarrer l\'application'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    debugPrint('💥 ERREUR NON GÉRÉE: $error');
    debugPrint('📚 Stack trace: $stack');
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Construction de MyApp');
    try {
      final isDarkMode = ref.watch(themeControllerProvider);
      final authState = ref.watch(authStateProvider);
      debugPrint('👤 État d\'authentification récupéré');

      return MaterialApp(
        title: 'Cercle Mystique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: _showSplash 
          ? SplashScreen(onComplete: _onSplashComplete) 
          : authState.when(
              data: (user) {
                debugPrint(user != null ? '✅ Utilisateur connecté' : '❌ Utilisateur non connecté');
                return user != null 
                  ? const GameSelectionScreen() 
                  : const AuthScreen();
              },
              loading: () {
                debugPrint('⏳ Chargement de l\'état d\'authentification');
                return Scaffold(
                  body: AnimatedBackground(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Cercle Mystique',
                            style: TextStyle(
                              fontFamily: ThemeConstants.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              error: (error, stack) {
                debugPrint('❌ Erreur d\'authentification: $error');
                return const AuthScreen();
              },
            ),
      );
    } catch (e, stack) {
      debugPrint('❌ Erreur dans MyApp.build: $e');
      debugPrint('📚 Stack trace: $stack');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erreur: $e'),
          ),
        ),
      );
    }
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
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
                        // TODO: Naviguer vers le profil
                      },
                      tooltip: 'Profil',
                    ),
                    const SizedBox(width: 8),
                    const ThemeToggleButton(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: isDark ? Colors.white : primaryColor,
                        size: 28,
                      ),
                      onPressed: () {
                        // TODO: Ouvrir les paramètres
                      },
                      tooltip: 'Paramètres',
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      Strings.appTitle,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontFamily: ThemeConstants.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDark 
                              ? ThemeConstants.nightCardColor
                              : ThemeConstants.dayCardColor,
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                  ? Colors.black.withOpacity(0.3) 
                                  : Colors.grey.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 56,
                                color: isDark ? Colors.white70 : primaryColor,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                Strings.welcome,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Votre voyage dans le royaume mystique commence ici',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isDark 
                                    ? ThemeConstants.nightPrimaryGradient
                                    : ThemeConstants.dayPrimaryGradient,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Commencer l'aventure
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Commencer l\'aventure',
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
