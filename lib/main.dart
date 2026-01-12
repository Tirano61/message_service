import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/auth/data/datasources/user_login_data_sourse.dart';
import 'package:message_service/feactures/auth/data/repositories/user_reository_impl.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/splash_screen.dart';
import 'package:message_service/feactures/conversation/data/datasource/conversation_remote_datasource.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/conversation/data/repository_impl/conversation_repository_impl.dart';
import 'package:message_service/feactures/message/presentation/bloc/message_bloc.dart';
import 'package:message_service/feactures/message/data/repository_impl/message_repository_impl.dart';
import 'package:message_service/feactures/message/data/datasource/message_remote_datasource.dart';



void main() {
  // Ensure no anonymous session persists on cold start
  SessionManager().sessionToken = null;
  SessionManager().conversationId = null;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) {
          return AuthBloc(
            loginUseCase: LoginUseCase(
              userRepository: UserRepositoryImpl(
                remoteDataSource: UserLoginDataSourceImpl()
              ),
            )
          );
        }),
        BlocProvider<MessageBloc>(
          create: (_) {
            // HTTP-only repository
            final remote = MessageRemoteDataSourceImpl();
            final repo = MessageRepositoryImpl(remoteDataSource: remote);
            return MessageBloc(
              messageRepository: repo,
              userEntity: UserEntity(id: '', email: '', token: '', fullName: '', role: 'user')
            );
          }
        ),
        BlocProvider<ConversationBloc>(
          create: (_) {
            final remote = ConversationRemoteDataSourceImpl();
            final repo = ConversationRepositoryImpl(remoteDataSource: remote);
            return ConversationBloc(conversationRepository: repo);
          }
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Balanzas Electrónicas - Atención',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // Azul corporativo
            primary: const Color(0xFF1565C0),
            secondary: const Color(0xFF2E7D32), // Verde para ventas
            surface: Colors.white,
            background: const Color(0xFFF5F5F5),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 2,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF1565C0)),
            floatingLabelStyle: const TextStyle(color: Color(0xFF1565C0)),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}


