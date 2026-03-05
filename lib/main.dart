import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
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
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

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
            title: 'Pulse',
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
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
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