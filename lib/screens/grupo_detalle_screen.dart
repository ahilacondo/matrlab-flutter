import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import 'confirmacion_screen.dart';

class GrupoDetalleScreen extends StatelessWidget {
  const GrupoDetalleScreen({super.key, required this.grupoId});

  final String grupoId;

  TableRow _fila(BuildContext context, IconData icono, String etiqueta,
      String valor) {
    final scheme = Theme.of(context).colorScheme;
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icono, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(etiqueta),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _matricular(
      BuildContext context, MatrLabState e, GrupoLab g) async {
    final curso = e.cursoDeGrupo(g);
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.servicioDisponible ? 'Confirmar matrícula' : 'Guardar solicitud',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(curso.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${g.nombre} · ${g.horario.texto} · ${g.aula}'),
              const SizedBox(height: 4),
              Text('Cupos libres: ${g.cuposLibres} de ${g.cuposTotales}'),
              if (!e.servicioDisponible) ...[
                const SizedBox(height: 8),
                const Text(
                  'El servicio no está disponible. Guardaremos tu solicitud y, '
                  'al restablecerse, se confirmará solo si aún hay cupo.',
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('btn-cancelar-sheet'),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('btn-confirmar-sheet'),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(e.servicioDisponible ? 'Confirmar' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final resultado = e.matricular(g.id);
    if (resultado == ResultadoMatricula.ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmacionScreen(grupoId: g.id),
        ),
      );
    } else {
      final mensaje = switch (resultado) {
        ResultadoMatricula.sinCupo => 'El grupo se llenó mientras confirmabas.',
        ResultadoMatricula.cruceHorario => 'El horario se cruza con otro grupo.',
        ResultadoMatricula.yaMatriculado =>
          'Ya estás matriculado en este curso.',
        ResultadoMatricula.fueraDeTurno => 'Tu turno aún no inicia.',
        ResultadoMatricula.pendiente =>
          'Solicitud guardada. Se procesará cuando el servicio se restablezca.',
        ResultadoMatricula.yaPendiente =>
          'Ya tienes una solicitud pendiente para este curso.',
        ResultadoMatricula.ok => '',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _cancelar(
      BuildContext context, MatrLabState e, GrupoLab g) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar matrícula?'),
        content: const Text('Liberarás tu cupo en este grupo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (seguro == true) e.cancelarMatricula(g.id);
  }

  Widget _accion(BuildContext context, MatrLabState e, GrupoLab g) {
    const clave = ValueKey('accion-grupo');
    if (e.esAdmin) {
      return const SizedBox.shrink();
    }
    if (e.estaMatriculado(g.id)) {
      return OutlinedButton.icon(
        key: clave,
        onPressed: () => _cancelar(context, e, g),
        icon: const Icon(Icons.event_busy),
        label: const Text('Cancelar matrícula'),
      );
    }
    if (e.tienePendiente(g.id)) {
      return const FilledButton(
        key: clave,
        onPressed: null,
        child: Text('Solicitud pendiente de procesar'),
      );
    }
    if (!e.turnoAbierto) {
      return const FilledButton(
        key: clave,
        onPressed: null,
        child: Text('Fuera de tu turno'),
      );
    }
    if (e.tienePendienteDeCurso(g.cursoCodigo)) {
      return const FilledButton(
        key: clave,
        onPressed: null,
        child: Text('Ya tienes una solicitud para este curso'),
      );
    }
    if (e.tieneCursoMatriculado(g.cursoCodigo)) {
      return const FilledButton(
        key: clave,
        onPressed: null,
        child: Text('Ya tienes un grupo de este curso'),
      );
    }
    if (e.conflictoCon(g) != null) {
      return const FilledButton(
        key: clave,
        onPressed: null,
        child: Text('Cruce de horario'),
      );
    }
    if (g.cuposLibres <= 0) {
      if (e.enListaEspera(g.id)) {
        return const FilledButton(
          key: clave,
          onPressed: null,
          child: Text('Ya estás en la lista de espera'),
        );
      }
      return FilledButton.tonal(
        key: clave,
        onPressed: () => e.unirseAListaEspera(g.id),
        child: const Text('Unirme a la lista de espera'),
      );
    }
    return FilledButton(
      key: clave,
      onPressed: () => _matricular(context, e, g),
      child: Text(e.servicioDisponible ? 'Matricularme' : 'Guardar solicitud'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final g = e.grupoPorId(grupoId);
    final curso = e.cursoDeGrupo(g);
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final conflicto = e.conflictoCon(g);
    final otroGrupo = e.grupoMatriculadoDe(g.cursoCodigo);

    return Scaffold(
      appBar: AppBar(title: Text('${curso.sigla} · ${g.nombre}')),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    curso.nombre,
                    style: tema.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                EstadoChip(estado: g.estado),
              ],
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(124),
                1: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _fila(context, Icons.groups_outlined, 'Grupo', g.nombre),
                _fila(context, Icons.schedule, 'Horario', g.horario.texto),
                _fila(context, Icons.meeting_room_outlined, 'Aula', g.aula),
                _fila(context, Icons.person_outline, 'Docente', curso.docente),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CupoBar(grupo: g, grande: true),
              ),
            ),
            if (!e.esAdmin && !e.turnoAbierto)
              Aviso(
                icono: Icons.schedule,
                color: const Color(0xFF9A5B00),
                texto: e.motivoBloqueo(g) ?? '',
              )
            else if (e.tienePendiente(g.id))
              Aviso(
                icono: Icons.hourglass_top,
                color: scheme.primary,
                texto: 'Tu solicitud quedó guardada. Se procesará por orden de '
                    'llegada cuando el servicio se restablezca.',
              )
            else if (otroGrupo != null && otroGrupo.id != g.id)
              Aviso(
                icono: Icons.info_outline,
                color: scheme.primary,
                texto: 'Ya estás matriculado en ${otroGrupo.nombre} de este '
                    'curso (${otroGrupo.horario.texto}).',
              )
            else if (conflicto != null)
              Aviso(
                icono: Icons.warning_amber_rounded,
                color: const Color(0xFF9A5B00),
                texto: 'Se cruza con ${e.cursoDeGrupo(conflicto).nombre} · '
                    '${conflicto.nombre} (${conflicto.horario.texto}). '
                    'Elige otro grupo.',
              )
            else if (g.cuposLibres <= 0)
              Aviso(
                icono: Icons.hourglass_top,
                color: const Color(0xFFB3261E),
                texto: 'Este grupo no tiene cupos. Únete a la lista de espera '
                    'y te avisaremos cuando se libere uno.',
              )
            else if (!e.esAdmin && !e.servicioDisponible)
              Aviso(
                icono: Icons.cloud_off_outlined,
                color: const Color(0xFFB3261E),
                texto: 'El servicio no está disponible. Guardaremos tu solicitud '
                    'y se confirmará por orden de llegada cuando se restablezca, '
                    'solo si aún hay cupo.',
              )
            else if (!e.esAdmin)
              Aviso(
                icono: Icons.lock_clock,
                color: scheme.primary,
                texto: 'Al confirmar, el cupo se reserva de inmediato para ti.',
              ),
          ],
        ),
      ),
      bottomNavigationBar: e.esAdmin
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _accion(context, e, g),
                ),
              ),
            ),
    );
  }
}
