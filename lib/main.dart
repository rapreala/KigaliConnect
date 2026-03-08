import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/data/repositories/firebase_auth_repository.dart';
import 'package:kigali_connect/data/repositories/firebase_listings_repository.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/blocs/settings/settings_cubit.dart';
import 'package:kigali_connect/presentation/screens/auth/auth_gate.dart';
import 'package:kigali_connect/presentation/screens/shell/app_shell.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const KigaliConnectApp());
}

class KigaliConnectApp extends StatelessWidget {
  const KigaliConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = FirebaseAuthRepository();
    final listingsRepo = FirebaseListingsRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository: authRepo)),
        BlocProvider(create: (_) => ListingsBloc(listingsRepository: listingsRepo)),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: MaterialApp(
        title: 'KigaliConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(authenticatedChild: AppShell()),
      ),
    );
  }
}
