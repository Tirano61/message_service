import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/presentation/ui/pages/conversation_page.dart';
import 'package:message_service/core/session_manager.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticatedState) {
            // Guardar token en persistencia
            SessionManager().sessionToken = state.user.token;
            await SessionManager().saveSession();
            // After login, go to the Conversation selection page (cards)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ConversationPage()),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            final screenHeight = MediaQuery.of(context).size.height;
            final screenWidth = MediaQuery.of(context).size.width;
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card-like container
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                          child: Column(
                            children: [
                              // Circular logo with orange border
                              Container(
                                width: screenWidth * 0.35,
                                height: screenWidth * 0.35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0E2440),
                                  border: Border.all(color: const Color(0xFFFF8A00), width: 3.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: screenWidth * 0.25,
                                    height: screenWidth * 0.25,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              Text(
                                'AI Tech Support',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0A1B3A),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'Balanzas Hook - Sistema de Soporte',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.036,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              // Usuario
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Usuario',
                                  prefixIcon: const Icon(Icons.person, color: Color(0xFF1565C0)),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Contraseña
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF1565C0)),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF1565C0),
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Ingresar (primary)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2752F3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 6,
                                  ),
                                  onPressed: () {
                                    context.read<AuthBloc>().add(
                                          AuthRequestEvent(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ),
                                        );
                                  },
                                  child: const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Entrar como invitado (secondary)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    backgroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    context.read<AuthBloc>().add(AuthLogoutEvent());
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ConversationPage()),
                                    );
                                  },
                                  child: Text('Entrar como invitado', style: TextStyle(color: Colors.grey[700])),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
