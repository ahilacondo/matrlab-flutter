import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estado.dart';
import '../models.dart';

class ConfirmacionScreen extends StatelessWidget {
  const ConfirmacionScreen({super.key, required this.grupoId});

  final String grupoId;

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(etiqueta)),
          Expanded(
            flex: 3,
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final g = e.grupoPorId(grupoId);
    final curso = e.cursoDeGrupo(g);
    final matricula = e.matriculas.firstWhere((m) => m.grupoId == grupoId);
    final tema = Theme.of(context).textTheme;
    const verde = Color(0xFF2E7D32);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: verde.withAlpha(28),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.check_rounded, size: 64, color: verde),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Matrícula confirmada!',
                    textAlign: TextAlign.center,
                    style: tema.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu cupo quedó reservado.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _fila('Curso', curso.nombre),
                          const Divider(height: 1),
                          _fila('Grupo', g.nombre),
                          const Divider(height: 1),
                          _fila('Horario', g.horario.texto),
                          const Divider(height: 1),
                          _fila('Aula', g.aula),
                          const Divider(height: 1),
                          _fila('Estado', matricula.estado),
                          const Divider(height: 1),
                          _fila('Comprobante', matricula.codigo),
                          const Divider(height: 1),
                          _fila('Registrado', formatoFechaHora(matricula.fecha)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('btn-copiar-comprobante'),
                    onPressed: () async {
                      final mensajero = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                          ClipboardData(text: matricula.codigo));
                      mensajero.showSnackBar(
                        const SnackBar(content: Text('Comprobante copiado')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar comprobante'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('btn-ver-horario'),
                    onPressed: () {
                      final estado = MatrLabScope.leer(context);
                      estado.irAPestana(1);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('Ver mi horario'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      MatrLabScope.leer(context).irAPestana(0);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
