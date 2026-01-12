import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/presentation/ui/pages/conversation_page.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticatedState) {
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
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AI Tech Support',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Image.asset(
                    'assets/images/logo.png',
                    height: screenHeight * 0.15,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthRequestEvent(
                            email: _emailController.text,
                            password: _passwordController.text,
                          ),
                        );
                      },
                      child: const Text('Ingresar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Directly navigate to the anonymous conversations list.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ConversationPage()),
                        );
                      },
                      child: const Text('Entrar como invitado'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
