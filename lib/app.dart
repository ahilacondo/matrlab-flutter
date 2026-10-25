import 'package:flutter/material.dart';

import 'estado.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

ThemeData temaMatrLab() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8C1D2F)),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}

class MatrLabApp extends StatelessWidget {
  const MatrLabApp({super.key, required this.estado});

  final MatrLabState estado;

  @override
  Widget build(BuildContext context) {
    return MatrLabScope(
      estado: estado,
      child: MaterialApp(
        title: 'MatrLab',
        debugShowCheckedModeBanner: false,
        theme: temaMatrLab(),
        home: const _Raiz(),
      ),
    );
  }
}

/// Decide qué mostrar según haya o no una sesión iniciada.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final estado = MatrLabScope.of(context);
    return estado.sesionIniciada ? const ShellScreen() : const LoginScreen();
  }
}
