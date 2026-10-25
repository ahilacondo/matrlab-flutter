import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';

class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  String _etiqueta(MatrLabState e, GrupoLab g) =>
      '${e.cursoDeGrupo(g).sigla} · ${g.nombre.split(' ').last}';

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final tema = Theme.of(context).textTheme;
    final ranking = e.gruposPorOcupacion();
    final masPresionado = ranking.first;

    return ContenidoCentrado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              StatTile(valor: '${e.cuposTotales}', etiqueta: 'cupos totales'),
              StatTile(valor: '${e.cuposOcupados}', etiqueta: 'cupos ocupados'),
              StatTile(
                valor: '${(e.ocupacionGlobal * 100).round()} %',
                etiqueta: 'ocupación global',
              ),
            ],
          ),
          Aviso(
            icono: Icons.trending_up,
            color: colorEstado(masPresionado.estado),
            texto: 'Mayor presión: ${_etiqueta(e, masPresionado)} con '
                '${(masPresionado.ocupacion * 100).round()} % de ocupación.',
          ),
          const SizedBox(height: 20),
          Text(
            'Ocupación por grupo',
            style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final g in ranking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 74, child: Text(_etiqueta(e, g))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.ocupacion.clamp(0.0, 1.0).toDouble(),
                        minHeight: 10,
                        color: colorEstado(g.estado),
                        backgroundColor: colorEstado(g.estado).withAlpha(40),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${g.cuposOcupados}/${g.cuposTotales}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Gestión de cupos',
            style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final g in e.grupos)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text('${_etiqueta(e, g)} · ${g.horario.texto}'),
                subtitle: Text('${g.cuposLibres} libres de ${g.cuposTotales}'),
                trailing: SizedBox(
                  width: 128,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Quitar un cupo',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: g.cuposLibres > 0
                            ? () => e.ajustarCupos(g.id, -1)
                            : null,
                      ),
                      Text('${g.cuposTotales}'),
                      IconButton(
                        key: ValueKey('mas-${g.id}'),
                        tooltip: 'Agregar un cupo',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => e.ajustarCupos(g.id, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
