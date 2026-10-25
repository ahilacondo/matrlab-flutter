import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';

const List<int> _franjas = [8, 10, 12, 14, 16];
const List<String> _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];

class HorarioScreen extends StatelessWidget {
  const HorarioScreen({super.key});

  /// Grupo matriculado que ocupa la franja [hora] del [dia] (1 = lunes).
  GrupoLab? _grupoEn(MatrLabState e, int dia, int hora) {
    for (final m in e.matriculas) {
      final g = e.grupoPorId(m.grupoId);
      final h = g.horario;
      if (h.dia == dia && h.inicio <= hora && hora < h.fin) return g;
    }
    return null;
  }

  Widget _celdaTexto(String texto, {bool negrita = false}) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _celdaCurso(BuildContext context, MatrLabState e, GrupoLab? g) {
    final scheme = Theme.of(context).colorScheme;
    if (g == null) return const SizedBox(height: 56);
    return Container(
      height: 56,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          e.cursoDeGrupo(g).sigla,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    final horas = e.matriculas.fold<int>(0, (s, m) {
      final h = e.grupoPorId(m.grupoId).horario;
      return s + (h.fin - h.inicio);
    });

    return ContenidoCentrado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  valor: '${e.matriculas.length}',
                  etiqueta: 'laboratorios matriculados',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  valor: '$horas h',
                  etiqueta: 'de laboratorio por semana',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Horario semanal',
            style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {0: FixedColumnWidth(46)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(color: scheme.outlineVariant),
            children: [
              TableRow(
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
                children: [
                  _celdaTexto(''),
                  for (final d in _dias) _celdaTexto(d, negrita: true),
                ],
              ),
              for (final hora in _franjas)
                TableRow(
                  children: [
                    _celdaTexto('${hora.toString().padLeft(2, '0')}:00'),
                    for (var dia = 1; dia <= 5; dia++)
                      _celdaCurso(context, e, _grupoEn(e, dia, hora)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Mis matrículas',
            style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (e.matriculas.isEmpty)
            EstadoVacio(
              icono: Icons.event_note_outlined,
              mensaje: 'Aún no tienes laboratorios matriculados.',
              etiquetaAccion: 'Explorar cursos',
              alAccionar: () => e.irAPestana(0),
            )
          else
            for (final m in e.matriculas)
              _MatriculaTile(matricula: m),
        ],
      ),
    );
  }
}

class _MatriculaTile extends StatelessWidget {
  const _MatriculaTile({required this.matricula});

  final Matricula matricula;

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final g = e.grupoPorId(matricula.grupoId);
    final curso = e.cursoDeGrupo(g);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(curso.sigla, style: const TextStyle(fontSize: 12)),
        ),
        title: Text(curso.nombre),
        subtitle: Text('${g.nombre} · ${g.horario.texto}\n${g.aula}'),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Cancelar matrícula',
          icon: const Icon(Icons.event_busy_outlined),
          onPressed: () => e.cancelarMatricula(g.id),
        ),
      ),
    );
  }
}
