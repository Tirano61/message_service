import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/feactures/auth/data/datasources/user_login_data_sourse.dart';
import 'package:message_service/feactures/auth/data/repositories/user_reository_impl.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/auth/domain/use_cases/login_use_case.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';
import 'package:message_service/feactures/categories/data/datasourse/category_remote_datasourse.dart';
import 'package:message_service/feactures/categories/data/repository_impl/category_repository_imol.dart';
import 'package:message_service/feactures/categories/domain/repository/category_repository.dart';
import 'package:message_service/feactures/categories/domain/use_case/get_categiry_usecase.dart';
import 'package:message_service/feactures/categories/presentation/bloc/category_bloc.dart';
import 'package:message_service/feactures/message/data/datasource/message_datasource.dart';
import 'package:message_service/feactures/message/presentation/bloc/message_bloc.dart';


void main() {
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
            return MessageBloc(
              messageDataSource: MessageDataSourceImpl(socketService: SocketService()),
              userEntity: UserEntity(id: '', email: '', token: '', fullName: '')
            );
          }
        ),
        BlocProvider<CategoryBloc>(
          create: (_) {
            return CategoryBloc(
              getCategoriesUseCase: GetCategoriesUseCase(
                categoryRepository: CategoryRepositoryImpl(
                  categoryRemoteDataSource: CategoryRemoteDataSourceImpl()
                )
              ),
              userEntity: UserEntity(id: '', email: '', token: '', fullName: '')
            );
          }
        ),
      ],
      child: MaterialApp( 
        title: 'Message Service',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 132, 0, 255)),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 76, 0, 255),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
            ),
          ),
        ),
        home: Login(),
      ),
    );
  }
}


