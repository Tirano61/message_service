import 'package:flutter/material.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';

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

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scale animation (0.5s - 1.2s)
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Logo fade animation (0s - 0.8s)
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Text fade animation (0.6s - 1.4s)
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate to login after animation completes
    Future.delayed(const Duration(milliseconds: 3200), () {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
