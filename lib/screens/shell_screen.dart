import 'package:flutter/material.dart';

import '../estado.dart';
import '../widgets/turno_widgets.dart';
import 'alertas_screen.dart';
import 'ayuda_screen.dart';
import 'cursos_screen.dart';
import 'horario_screen.dart';
import 'operacion_screen.dart';
import 'panel_screen.dart';

class _Destino {
  const _Destino(this.titulo, this.icono, this.iconoActivo,
      {this.esAlertas = false});

  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  final bool esAlertas;
}

const List<_Destino> _destinosEstudiante = [
  _Destino('Cursos', Icons.menu_book_outlined, Icons.menu_book),
  _Destino('Mi horario', Icons.calendar_month_outlined, Icons.calendar_month),
  _Destino('Alertas', Icons.notifications_outlined, Icons.notifications,
      esAlertas: true),
  _Destino('Ayuda', Icons.help_outline, Icons.help),
];

const List<_Destino> _destinosAdmin = [
  _Destino('Cursos', Icons.menu_book_outlined, Icons.menu_book),
  _Destino('Panel', Icons.insights_outlined, Icons.insights),
  _Destino('Operación', Icons.tune_outlined, Icons.tune),
];

/// Estructura principal: AppBar + navegación adaptable.
/// < 600 dp: barra inferior · >= 600 dp: riel lateral.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  Widget _icono(MatrLabState e, _Destino d, bool activo) {
    final icono = Icon(activo ? d.iconoActivo : d.icono);
    if (d.esAlertas && e.noLeidas > 0) {
      return Badge.count(count: e.noLeidas, child: icono);
    }
    return icono;
  }

  @override
  Widget build(BuildContext context) {
    final e = MatrLabScope.of(context);
    final destinos = e.esAdmin ? _destinosAdmin : _destinosEstudiante;
    final indice = e.pestana.clamp(0, destinos.length - 1).toInt();

    final pantallas = IndexedStack(
      index: indice,
      children: e.esAdmin
          ? const [CursosScreen(), PanelScreen(), OperacionScreen()]
          : const [
              CursosScreen(),
              HorarioScreen(),
              AlertasScreen(),
              AyudaScreen(),
            ],
    );

    // Si el servicio está caído se muestra un banner encima de cualquier pestaña.
    final cuerpo = Column(
      children: [
        if (!e.servicioDisponible) const BannerServicio(),
        Expanded(child: pantallas),
      ],
    );

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth >= 600;
        return Scaffold(
          appBar: AppBar(
            title: Text(destinos[indice].titulo),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    e.codigoUsuario ?? '',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: e.cerrarSesion,
              ),
            ],
          ),
          body: ancho
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: indice,
                      onDestinationSelected: e.irAPestana,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final d in destinos)
                          NavigationRailDestination(
                            icon: _icono(e, d, false),
                            selectedIcon: _icono(e, d, true),
                            label: Text(d.titulo),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: cuerpo),
                  ],
                )
              : cuerpo,
          bottomNavigationBar: ancho
              ? null
              : NavigationBar(
                  selectedIndex: indice,
                  onDestinationSelected: e.irAPestana,
                  destinations: [
                    for (final d in destinos)
                      NavigationDestination(
                        icon: _icono(e, d, false),
                        selectedIcon: _icono(e, d, true),
                        label: d.titulo,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
