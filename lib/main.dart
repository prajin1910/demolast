import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_assessment_app/providers/auth_provider.dart';
import 'package:smart_assessment_app/providers/toast_provider.dart';
import 'package:smart_assessment_app/screens/auth/login_screen.dart';
import 'package:smart_assessment_app/screens/auth/register_screen.dart';
import 'package:smart_assessment_app/screens/auth/verify_otp_screen.dart';
import 'package:smart_assessment_app/screens/dashboards/student_dashboard.dart';
import 'package:smart_assessment_app/screens/dashboards/professor_dashboard.dart';
import 'package:smart_assessment_app/screens/dashboards/alumni_dashboard.dart';
import 'package:smart_assessment_app/screens/dashboards/management_dashboard.dart';
import 'package:smart_assessment_app/screens/profile/user_profile_screen.dart';
import 'package:smart_assessment_app/utils/app_theme.dart';
import 'package:smart_assessment_app/widgets/common/toast_widget.dart';

void main() {
  runApp(const SmartAssessmentApp());
}

class SmartAssessmentApp extends StatelessWidget {
  const SmartAssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ToastProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final router = GoRouter(
            initialLocation: authProvider.isAuthenticated ? _getInitialRoute(authProvider.user?.role) : '/login',
            redirect: (context, state) {
              final isAuthenticated = authProvider.isAuthenticated;
              final isAuthRoute = ['/login', '/register', '/verify-otp'].contains(state.location);
              
              if (!isAuthenticated && !isAuthRoute) {
                return '/login';
              }
              
              if (isAuthenticated && isAuthRoute) {
                return _getInitialRoute(authProvider.user?.role);
              }
              
              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/verify-otp',
                builder: (context, state) => VerifyOtpScreen(
                  email: state.extra as String? ?? '',
                ),
              ),
              GoRoute(
                path: '/student',
                builder: (context, state) => const StudentDashboard(),
              ),
              GoRoute(
                path: '/professor',
                builder: (context, state) => const ProfessorDashboard(),
              ),
              GoRoute(
                path: '/alumni',
                builder: (context, state) => const AlumniDashboard(),
              ),
              GoRoute(
                path: '/management',
                builder: (context, state) => const ManagementDashboard(),
              ),
              GoRoute(
                path: '/profile/:userId',
                builder: (context, state) => UserProfileScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'Smart Assessment System',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) {
              return Scaffold(
                body: child,
                bottomSheet: const ToastWidget(),
              );
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute(String? role) {
    switch (role) {
      case 'STUDENT':
        return '/student';
      case 'PROFESSOR':
        return '/professor';
      case 'ALUMNI':
        return '/alumni';
      case 'MANAGEMENT':
        return '/management';
      default:
        return '/login';
    }
  }
}