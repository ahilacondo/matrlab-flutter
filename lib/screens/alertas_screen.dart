import 'package:flutter/material.dart';

import '../estado.dart';
import '../models.dart';
import '../widgets/comunes.dart';

IconData _icono(TipoNotificacion t) => switch (t) {
      TipoNotificacion.matricula => Icons.check_circle_outline,
      TipoNotificacion.cupoLiberado => Icons.lock_open,
      TipoNotificacion.listaEspera => Icons.hourglass_top,
      TipoNotificacion.aviso => Icons.campaign_outlined,
      TipoNotificacion.ticket => Icons.confirmation_number_outlined,
      TipoNotificacion.servicio => Icons.cloud_sync_outlined,
    };

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ContenidoCentrado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (e.listaEspera.isNotEmpty) ...[
            Text(
              'Lista de espera',
              style: tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final id in e.listaEspera)
                  Chip(
                    avatar: const Icon(Icons.hourglass_top, size: 16),
                    label: Text(
                      '${e.cursoDeGrupo(e.grupoPorId(id)).sigla} · '
                      '${e.grupoPorId(id).nombre}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notificaciones',
                  style:
                      tema.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: e.noLeidas > 0 ? e.marcarLeidas : null,
                child: const Text('Marcar leídas'),
              ),
            ],
          ),
          if (e.notificaciones.isEmpty)
            const EstadoVacio(
              icono: Icons.notifications_off_outlined,
              mensaje: 'No tienes notificaciones.',
            )
          else
            for (final n in e.notificaciones)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  leading: Badge(
                    smallSize: 10,
                    isLabelVisible: !n.leida,
                    child: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Icon(_icono(n.tipo)),
                    ),
                  ),
                  title: Text(
                    n.titulo,
                    style: TextStyle(
                      fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(n.mensaje),
                  trailing: Text(
                    formatoHoraCorta(n.fecha),
                    style: tema.labelSmall,
                  ),
                  isThreeLine: true,
                ),
              ),
        ],
      ),
    );
  }
}
