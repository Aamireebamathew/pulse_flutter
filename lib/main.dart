import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard/main_dashboard.dart';
import 'screens/dashboard/overview_screen.dart';
import 'screens/dashboard/registered_objects_screen.dart';
import 'screens/dashboard/add_object_screen.dart';
import 'screens/dashboard/live_camera_screen.dart';
import 'screens/dashboard/alerts_history_screen.dart';
import 'screens/dashboard/phone_recovery_screen.dart';
import 'screens/dashboard/bluetooth_devices_screen.dart';
import 'screens/dashboard/settings_screen.dart';
import 'screens/dashboard/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await SupabaseService.initialize();
  await NotificationService.instance.init();
   
  runApp(const NearDearApp());
}

class NearDearApp extends StatefulWidget {
  const NearDearApp({super.key});

  @override
  State<NearDearApp> createState() => _NearDearAppState();
}

class _NearDearAppState extends State<NearDearApp> {
  @override
  void initState() {
    super.initState();
    // ── Handle email confirmation redirect on web ──────────────────────────
    // When a user clicks the confirmation link in their email, Supabase
    // redirects to your Site URL with a #access_token=... fragment.
    // The Supabase Flutter web client detects this automatically via
    // onAuthStateChange — no extra code needed here.
    // But we listen explicitly so we can navigate to /dashboard once confirmed.
    if (kIsWeb) {
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        // SIGNED_IN fires when the token from the confirmation link is consumed
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          // GoRouter's redirect logic will handle navigation automatically
          // because AuthProvider notifies listeners when _user changes
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          return MaterialApp.router(
            title: 'NearDear',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            routerConfig: _buildRouter(auth),
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/dashboard',
      // ── Auth redirect guard ──────────────────────────────────────────────
      // Also handles /auth/confirm route that Supabase may redirect to
      redirect: (context, state) {
        final isLoggedIn  = auth.isAuthenticated;
        final location    = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/register';

        // If Supabase redirected with a token fragment, the onAuthStateChange
        // listener will update AuthProvider automatically — just let it land
        // on /dashboard once auth is confirmed
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn  &&  isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        ShellRoute(
          builder: (context, state, child) => MainDashboard(child: child),
          routes: [
            GoRoute(path: '/dashboard',
                builder: (_, __) => const OverviewScreen()),
            GoRoute(path: '/dashboard/objects',
                builder: (_, __) => const RegisteredObjectsScreen()),
            GoRoute(path: '/dashboard/add-object',
                builder: (_, __) => const AddObjectScreen()),
            GoRoute(path: '/dashboard/camera',
                builder: (_, __) => const LiveCameraScreen()),
            GoRoute(path: '/dashboard/alerts',
                builder: (_, __) => const AlertsHistoryScreen()),
            GoRoute(path: '/dashboard/phone-recovery',
                builder: (_, __) => const PhoneRecoveryScreen()),
            GoRoute(path: '/dashboard/bluetooth',
                builder: (_, __) => const BluetoothDevicesScreen()),
            GoRoute(path: '/dashboard/settings',
                builder: (_, __) => const SettingsScreen()),
            GoRoute(path: '/dashboard/notifications',
                builder: (_, __) => const NotificationsScreen()),
          ],
        ),
      ],
    );
  }
}