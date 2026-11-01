import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import 'comunes.dart';

const Color _verde = Color(0xFF1B5E20);
const Color _ambar = Color(0xFF9A5B00);

/// Etiqueta con icono, texto y color (nunca solo color), para estados de
/// turno, de servicio o de la cola de atención.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.icono,
    required this.color,
  });

  final String texto;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Color e icono del estado de un turno («Programado», «En curso», …).
Color colorTurno(String estado) => switch (estado) {
      'En curso' => _verde,
      'Programado' => _ambar,
      _ => const Color(0xFF5F5F5F),
    };

IconData iconoTurno(String estado) => switch (estado) {
      'En curso' => Icons.play_circle_outline,
      'Programado' => Icons.schedule,
      _ => Icons.check_circle_outline,
    };

/// Aviso compacto con el turno del estudiante (HU-08). No muestra nada al
/// administrador. Se coloca al inicio de la lista de cursos.
class AvisoTurno extends StatelessWidget {
  const AvisoTurno({super.key});

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    if (e.esAdmin) return const SizedBox.shrink();
    final t = e.turnoDelEstudiante;
    final abierto = e.turnoAbierto;
    final String texto;
    if (t == null) {
      texto = 'Tu ciclo no tiene un turno asignado.';
    } else if (abierto) {
      texto = '${t.nombre} · ${t.rangoCiclos}: tu turno está abierto.';
    } else {
      texto = '${t.nombre} · ${t.rangoCiclos}: inicia en '
          '${formatoFaltante(t.inicio.difference(e.ahora))} '
          '(${formatoFechaHora(t.inicio)}).';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Aviso(
        icono: abierto ? Icons.event_available : Icons.schedule,
        color: abierto ? _verde : _ambar,
        texto: texto,
      ),
    );
  }
}

/// Banner que avisa que el servicio no está disponible (modo contingencia).
class BannerServicio extends StatelessWidget {
  const BannerServicio({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Servicio no disponible. Modo contingencia activo.',
      child: Container(
        width: double.infinity,
        color: scheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Servicio no disponible · modo contingencia: guardamos tus '
                'solicitudes y las procesamos al restablecerse.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
