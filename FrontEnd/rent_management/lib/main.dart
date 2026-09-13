import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/signin_screen.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const RentalApp());
}

class RentalApp extends StatelessWidget {
  const RentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient();
    final authRepository = AuthRepository(
      apiClient: apiClient,
      secureStorage: secureStorage,
    );

    return BlocProvider(
      create: (_) => AuthBloc(authRepository: authRepository),
      child: MaterialApp(
        title: 'Rental Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        initialRoute: '/signin',
        routes: {
          '/signin': (_) => const SignInScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
