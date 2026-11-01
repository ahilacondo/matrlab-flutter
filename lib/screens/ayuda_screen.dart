import 'package:flutter/material.dart';

import '../datos_demo.dart';
import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import '../widgets/turno_widgets.dart';

const Color _verde = Color(0xFF1B5E20);
const Color _ambar = Color(0xFF9A5B00);

/// Pestaña «Ayuda» del estudiante: turnos de matrícula (HU-08), estado del
/// servicio (HU-11), número de atención virtual (HU-09) y preguntas
/// frecuentes que explican las reglas (HU-12).
class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  Future<void> _pedirNumero(BuildContext context, MatrLabState e) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Por qué necesitas atención?'),
        children: [
          for (final m in motivosTicket)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(m),
            ),
        ],
      ),
    );
    if (motivo != null) e.solicitarTicket(motivo);
  }

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
    final esMio = identical(t, e.turnoDelEstudiante);
    final estado = t.estadoEn(e.ahora);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esMio ? scheme.primaryContainer.withAlpha(110) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esMio ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  esMio
                      ? '${t.nombre} · ${t.rangoCiclos} (tu turno)'
                      : '${t.nombre} · ${t.rangoCiclos}',
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
            '${formatoFechaHora(t.inicio)} a ${formatoFechaHora(t.fin)}',
            style: tema.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _tarjetaServicio(BuildContext context, MatrLabState e) {
    final ok = e.servicioDisponible;
    final color = ok ? _verde : const Color(0xFFB3261E);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Estado del servicio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Etiqueta(
                        texto: ok ? 'Disponible' : 'No disponible',
                        icono: ok ? Icons.check_circle_outline : Icons.block,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ok
                        ? 'Todo funciona con normalidad.'
                        : 'Puedes seguir eligiendo grupos: guardamos tus '
                            'solicitudes (${e.pendientes.length} pendiente(s)) y las '
                            'procesamos por orden de llegada al restablecerse.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaSinTicket(BuildContext context, MatrLabState e) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Si tu matrícula falló y necesitas atención asistida, pide un '
              'número virtual en lugar de esperar en una fila o pasar la noche '
              'en la facultad. Te avisamos en Alertas cuando se acerque tu turno.',
            ),
            const SizedBox(height: 4),
            Text(
              '${e.enEspera} persona(s) en espera ahora.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('btn-pedir-numero'),
                onPressed: () => _pedirNumero(context, e),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Pedir número de atención'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaTicket(
      BuildContext context, MatrLabState e, TicketAtencion t) {
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final delante = e.posicionDe(t) - 1;
    final minutos = e.minutosEstimados(t);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Tu número de atención', style: tema.bodySmall),
                ),
                const Etiqueta(
                  texto: 'En espera',
                  icono: Icons.hourglass_top,
                  color: _ambar,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Semantics(
              label: 'Tu número de atención es ${t.etiqueta}',
              child: ExcludeSemantics(
                child: Text(
                  t.etiqueta,
                  style: tema.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            Text(t.motivo),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    valor: '$delante',
                    etiqueta: 'personas delante',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    valor: minutos == 0 ? 'Ahora' : '$minutos min',
                    etiqueta: 'espera estimada',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estimación: ${MatrLabState.minutosPorAtencion} min por persona '
              '(valor de demostración). Puedes esperar donde estés.',
              style: tema.bodySmall,
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              key: const ValueKey('btn-cancelar-numero'),
              onPressed: e.cancelarTicket,
              icon: const Icon(Icons.close),
              label: const Text('Cancelar mi número'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pregunta(String pregunta, String respuesta,
      {bool abierta = false}) {
    return ExpansionTile(
      initiallyExpanded: abierta,
      title: Text(pregunta),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(respuesta)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final ticket = e.ticketActivo;

    return ContenidoCentrado(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo(context, 'Mi turno de matrícula'),
            for (final t in e.turnos) _filaTurno(context, e, t),
            _titulo(context, 'Estado del servicio'),
            _tarjetaServicio(context, e),
            _titulo(context, 'Atención sin fila'),
            if (ticket == null)
              _tarjetaSinTicket(context, e)
            else
              _tarjetaTicket(context, e, ticket),
            _titulo(context, 'Preguntas frecuentes'),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _pregunta(
                    '¿Por qué no puedo matricularme en un grupo?',
                    'MatrLab te lo explica en la pantalla del grupo: tu turno '
                        'aún no inicia, el horario se cruza con otro grupo, ya '
                        'tienes un grupo de ese curso o el grupo está lleno (en '
                        'ese caso puedes unirte a la lista de espera).',
                    abierta: true,
                  ),
                  _pregunta(
                    '¿Qué pasa si el servicio se cae mientras me matriculo?',
                    'Tu solicitud se guarda como pendiente con un código y se '
                        'procesa por orden de llegada cuando el servicio vuelve. '
                        'Si el grupo se llenó, te avisamos el motivo en Alertas.',
                  ),
                  _pregunta(
                    '¿Debo ir en persona a la dirección de escuela?',
                    'Solo si tu matrícula falló y necesitas atención asistida. '
                        'Pide un número virtual aquí y espera donde estés.',
                  ),
                  _pregunta(
                    '¿Cómo se calcula la espera de mi número?',
                    'Se multiplican las personas delante de ti por '
                        '${MatrLabState.minutosPorAtencion} minutos. Es un valor '
                        'de demostración que el administrador podría ajustar.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
