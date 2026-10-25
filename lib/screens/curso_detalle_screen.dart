import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';
import 'grupo_detalle_screen.dart';

class CursoDetalleScreen extends StatelessWidget {
  const CursoDetalleScreen({super.key, required this.codigoCurso});

  final String codigoCurso;

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final curso = e.cursoPorCodigo(codigoCurso);
    final grupos = e.gruposDe(codigoCurso);
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(curso.codigo)),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabecera: Stack permite superponer el icono decorativo al texto.
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -12,
                      bottom: -16,
                      child: Icon(
                        curso.icono,
                        size: 130,
                        color: Colors.white.withAlpha(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curso.nombre,
                            style: tema.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            curso.docente,
                            style: tema.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(curso.descripcion, style: tema.bodyLarge),
            const SizedBox(height: 20),
            Text(
              'Grupos de laboratorio',
              style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            for (final g in grupos) _GrupoCard(grupo: g),
          ],
        ),
      ),
    );
  }
}

class _GrupoCard extends StatelessWidget {
  const _GrupoCard({required this.grupo});

  final GrupoLab grupo;

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final tema = Theme.of(context).textTheme;
    final matriculado = e.estaMatriculado(grupo.id);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GrupoDetalleScreen(grupoId: grupo.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      grupo.nombre,
                      style: tema.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (matriculado) ...[
                    const EstadoChip(
                      estado: EstadoCupo.disponible,
                      etiqueta: 'Matriculado',
                    ),
                    const SizedBox(width: 6),
                  ],
                  EstadoChip(estado: grupo.estado),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Text(grupo.horario.texto, style: tema.bodyMedium),
                  const SizedBox(width: 16),
                  const Icon(Icons.meeting_room_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      grupo.aula,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CupoBar(grupo: grupo),
            ],
          ),
        ),
      ),
    );
  }
}
