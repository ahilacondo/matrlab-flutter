import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import 'curso_detalle_screen.dart';

enum _Filtro { todos, conCupos, misCursos }

String _nombreFiltro(_Filtro f) => switch (f) {
      _Filtro.todos => 'Todos',
      _Filtro.conCupos => 'Con cupos',
      _Filtro.misCursos => 'Mis cursos',
    };

class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  String _consulta = '';
  _Filtro _filtro = _Filtro.todos;

  List<Curso> _filtrar(MatrLabState e) {
    final q = _consulta.trim().toLowerCase();
    return e.cursos.where((c) {
      final coincide = q.isEmpty ||
          c.nombre.toLowerCase().contains(q) ||
          c.codigo.toLowerCase().contains(q) ||
          c.docente.toLowerCase().contains(q);
      final pasaFiltro = switch (_filtro) {
        _Filtro.todos => true,
        _Filtro.conCupos => e.cuposLibresDe(c.codigo) > 0,
        _Filtro.misCursos => e.tieneCursoMatriculado(c.codigo),
      };
      return coincide && pasaFiltro;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final cursos = _filtrar(e);

    return ContenidoCentrado(
      anchoMaximo: 1000,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchBar(
              hintText: 'Buscar curso, código o docente',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _consulta = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    valor: '${e.cuposLibres}',
                    etiqueta: 'cupos libres',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    valor: '${e.grupos.length}',
                    etiqueta: 'grupos de laboratorio',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    valor: '${(e.ocupacionGlobal * 100).round()} %',
                    etiqueta: 'ocupación total',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final f in _Filtro.values)
                    FilterChip(
                      label: Text(_nombreFiltro(f)),
                      selected: _filtro == f,
                      onSelected: (_) => setState(() => _filtro = f),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: cursos.isEmpty
                ? const Center(
                    child: EstadoVacio(
                      icono: Icons.search_off,
                      mensaje: 'No hay cursos que coincidan con tu búsqueda.',
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      mainAxisExtent: 128,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: cursos.length,
                    itemBuilder: (context, i) => _CursoCard(curso: cursos[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CursoCard extends StatelessWidget {
  const _CursoCard({required this.curso});

  final Curso curso;

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    final grupos = e.gruposDe(curso.codigo);
    final libres = e.cuposLibresDe(curso.codigo);
    final matriculado = e.tieneCursoMatriculado(curso.codigo);
    final estado = libres == 0
        ? EstadoCupo.lleno
        : (libres <= 4 ? EstadoCupo.casiLleno : EstadoCupo.disponible);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CursoDetalleScreen(codigoCurso: curso.codigo),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(curso.icono, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                curso.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (matriculado)
                              const Icon(Icons.check_circle,
                                  size: 18, color: Color(0xFF2E7D32)),
                          ],
                        ),
                        Text(
                          '${curso.codigo} · ${curso.docente}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 18),
                        const SizedBox(width: 4),
                        Text('${grupos.length} grupos',
                            style: tema.bodySmall),
                        const Spacer(),
                        EstadoChip(
                          estado: estado,
                          etiqueta: libres == 0
                              ? 'Sin cupos'
                              : '$libres cupos libres',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
