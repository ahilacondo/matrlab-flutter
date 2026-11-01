import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _clave = TextEditingController();
  Rol _rol = Rol.estudiante;
  int _ciclo = 10;
  bool _ocultar = true;

  @override
  void dispose() {
    _codigo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _ingresar() {
    if (_formKey.currentState!.validate()) {
      MatrLabScope.leer(context)
          .iniciarSesion(_codigo.text.trim(), _rol, ciclo: _ciclo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    final esEstudiante = _rol == Rol.estudiante;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_available,
                          size: 38,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MatrLab',
                      textAlign: TextAlign.center,
                      style: tema.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Matrícula en laboratorios · Ingeniería de Sistemas',
                      textAlign: TextAlign.center,
                      style: tema.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<Rol>(
                      segments: const [
                        ButtonSegment<Rol>(
                          value: Rol.estudiante,
                          icon: Icon(Icons.school_outlined),
                          label: Text('Estudiante'),
                        ),
                        ButtonSegment<Rol>(
                          value: Rol.administrador,
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          label: Text('Administrador'),
                        ),
                      ],
                      selected: {_rol},
                      onSelectionChanged: (s) => setState(() => _rol = s.first),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _codigo,
                      keyboardType: esEstudiante
                          ? TextInputType.number
                          : TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: esEstudiante
                            ? 'Código de estudiante'
                            : 'Usuario institucional',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => validarCodigo(v, _rol),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clave,
                      obscureText: _ocultar,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: validarClave,
                    ),
                    if (esEstudiante) ...[
                      const SizedBox(height: 14),
                      DropdownMenu<int>(
                        key: const ValueKey('menu-ciclo'),
                        expandedInsets: EdgeInsets.zero,
                        label: const Text('Ciclo (define tu turno)'),
                        leadingIcon: const Icon(Icons.event_note_outlined),
                        initialSelection: _ciclo,
                        onSelected: (v) {
                          if (v != null) setState(() => _ciclo = v);
                        },
                        dropdownMenuEntries: [
                          for (var c = 1; c <= 10; c++)
                            DropdownMenuEntry<int>(
                              value: c,
                              label: 'Ciclo $c',
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _ingresar,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Demostración: código de 8 dígitos y cualquier '
                      'contraseña de 4 o más caracteres.',
                      textAlign: TextAlign.center,
                      style: tema.bodySmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
