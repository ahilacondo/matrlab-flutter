import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import '../widgets/turno_widgets.dart';

/// Pestaña «Operación» del administrador: simulación de caída del servicio
/// (HU-11), turnos escalonados (HU-08) y cola de atención virtual (HU-09).
class OperacionScreen extends StatelessWidget {
  const OperacionScreen({super.key});

  Widget _titulo(BuildContext context, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _filaTurno(BuildContext context, MatrLabState e, TurnoMatricula t) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    final estado = t.estadoEn(e.ahora);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.nombre} · ${t.rangoCiclos}',
                  style: tema.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Etiqueta(
                texto: estado,
                icono: iconoTurno(estado),
                color: colorTurno(estado),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatoFechaHora(t.inicio)} → ${formatoFechaHora(t.fin)}',
            style: tema.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _filaTicket(BuildContext context, TicketAtencion t) {
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              t.etiqueta,
              style: tema.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(t.motivo)),
          const SizedBox(width: 8),
          Text(formatoHoraCorta(t.creado), style: tema.labelSmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final enEspera = e.tickets
        .where((t) => t.estado == EstadoTicket.esperando)
        .toList();
    final atendidos =
        e.tickets.where((t) => t.estado == EstadoTicket.atendido).length;

    return ContenidoCentrado(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo(context, 'Estado del servicio'),
            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                key: const ValueKey('sw-servicio'),
                title: const Text('Simular caída del servicio'),
                subtitle: Text(
                  'Simulación para demostrar el modo contingencia. '
                  'Solicitudes pendientes: ${e.pendientes.length}.',
                ),
                value: !e.servicioDisponible,
                onChanged: (v) => e.cambiarServicio(disponible: !v),
              ),
            ),
            _titulo(context, 'Turnos de matrícula'),
            for (final t in e.turnos) _filaTurno(context, e, t),
            _titulo(context, 'Cola de atención virtual'),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    valor: '${enEspera.length}',
                    etiqueta: 'en espera',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    valor: '$atendidos',
                    etiqueta: 'atendidos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (enEspera.isEmpty)
              const EstadoVacio(
                icono: Icons.done_all,
                mensaje: 'No hay nadie en espera.',
              )
            else
              for (final t in enEspera.take(6)) _filaTicket(context, t),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('btn-atender'),
                onPressed: enEspera.isEmpty ? null : e.atenderSiguiente,
                icon: const Icon(Icons.record_voice_over_outlined),
                label: const Text('Atender siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
