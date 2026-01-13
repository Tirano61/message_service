import 'package:flutter/material.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';
import 'package:message_service/feactures/auth/data/datasources/user_login_data_sourse.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/conversation/presentation/ui/pages/conversation_page.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    // Inicializar animaciones ANTES de cualquier await
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );
    // Cargar sesión persistente antes de animar
    SessionManager().loadSession().then((_) {
      setState(() { _ready = true; });
      _controller.forward();
      // Cambia aquí: validación de token
      Future.delayed(const Duration(milliseconds: 3200), () async {
        if (!mounted) return;
        final token = SessionManager().sessionToken;
        if (token != null && token.isNotEmpty) {
          final user = await UserLoginDataSourceImpl().validateToken(token);
          if (user != null && mounted) {
            // Rehidratar AuthBloc
            if (context.mounted) {
              context.read<AuthBloc>().emit(AuthAuthenticatedState(user: user));
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ConversationPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            }
            return;
          }
        }
        // Si no hay token o no es válido, ir a login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => Login(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(
                              0.15 * _logoFadeAnimation.value,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: screenHeight * 0.2,
                        width: screenHeight * 0.2,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: screenHeight * 0.06),
            
            // Animated Text
            AnimatedBuilder(
              animation: _textFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'AI Tech Support',
                        style: TextStyle(
                          fontSize: screenWidth * 0.085,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E), // Azul oscuro profesional
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        'Balanzas Hook',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1565C0),
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF1565C0).withOpacity(
                              _textFadeAnimation.value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
