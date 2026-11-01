// Pruebas de interfaz del Laboratorio 05: cada una recorre una historia de
// usuario con widgets reales (turno, número de atención, contingencia,
// comprobante y legibilidad con texto grande).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/app.dart';
import 'package:matrlab/datos_demo.dart';
import 'package:matrlab/estado.dart';
import 'package:matrlab/models.dart';
import 'package:matrlab/screens/confirmacion_screen.dart';
import 'package:matrlab/screens/grupo_detalle_screen.dart';

import 'fuentes_prueba.dart';

final DateTime _base = DateTime(2026, 11, 9, 8, 0);

MatrLabState _estudiante({int ciclo = 10}) {
  final e = MatrLabState(reloj: () => _base);
  e.iniciarSesion('20241234', Rol.estudiante, ciclo: ciclo);
  return e;
}

MatrLabState _admin() {
  final e = MatrLabState(reloj: () => _base);
  e.iniciarSesion('admin', Rol.administrador);
  return e;
}

/// Monta la app a tamaño de teléfono (360 x 780 dp) y espera el primer cuadro.
Future<void> _montar(
  WidgetTester tester,
  MatrLabState estado, {
  double ancho = 360,
  double alto = 780,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = Size(ancho * 3, alto * 3);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MatrLabApp(estado: estado));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  final navegador =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  unawaited(navegador.push(MaterialPageRoute<void>(builder: (_) => pantalla)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _avanzar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Desmonta la app para que no queden temporizadores (por ejemplo de SnackBar).
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUpAll(cargarFuentesDePrueba);

  group('HU-08 y HU-12: turno y motivo del bloqueo', () {
    testWidgets('fuera de turno el botón queda bloqueado y se explica',
        (tester) async {
      final e = _estudiante(ciclo: 5);
      await _montar(tester, e);
      await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));

      expect(find.text('Fuera de tu turno'), findsOneWidget);
      final boton = tester
          .widget<FilledButton>(find.byKey(const ValueKey('accion-grupo')));
      expect(boton.onPressed, isNull);
      expect(find.textContaining('Turno 3'), findsWidgets);
    });

    testWidgets('el aviso de turno aparece en la lista de cursos',
        (tester) async {
      await _montar(tester, _estudiante(ciclo: 5));
      expect(find.textContaining('Turno 3'), findsWidgets);
      expect(find.textContaining('inicia en 2 d 0 h'), findsOneWidget);
    });

    testWidgets('con el turno abierto el botón permite matricularse',
        (tester) async {
      await _montar(tester, _estudiante());
      await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
      final boton = tester
          .widget<FilledButton>(find.byKey(const ValueKey('accion-grupo')));
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('el inicio de sesión guarda el ciclo elegido', (tester) async {
      final estado = MatrLabState(reloj: () => _base);
      await _montar(tester, estado);

      await tester.tap(find.byKey(const ValueKey('menu-ciclo')));
      await _avanzar(tester);
      await tester.tap(find.text('Ciclo 5').last);
      await _avanzar(tester);

      await tester.enterText(find.byType(TextFormField).at(0), '20241234');
      await tester.enterText(find.byType(TextFormField).at(1), 'clave');
      await tester.tap(find.text('Ingresar'));
      await _avanzar(tester);

      expect(estado.sesionIniciada, isTrue);
      expect(estado.cicloEstudiante, 5);
      expect(estado.turnoAbierto, isFalse);
    });
  });

  group('HU-09: número de atención virtual', () {
    testWidgets('el estudiante pide un número y lo ve en pantalla',
        (tester) async {
      final e = _estudiante()..irAPestana(3);
      await _montar(tester, e);

      expect(find.text('Mi turno de matrícula'), findsOneWidget);
      final boton = find.byKey(const ValueKey('btn-pedir-numero'));
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await _avanzar(tester);

      await tester.tap(find.text(motivosTicket.first));
      await _avanzar(tester);

      expect(e.ticketActivo, isNotNull);
      expect(find.text('A-021'), findsOneWidget);
    });

    testWidgets('el estudiante puede cancelar su número', (tester) async {
      final e = _estudiante()..irAPestana(3);
      e.solicitarTicket(motivosTicket.first);
      await _montar(tester, e);

      final cancelar = find.byKey(const ValueKey('btn-cancelar-numero'));
      await tester.ensureVisible(cancelar);
      await tester.tap(cancelar);
      await _avanzar(tester);

      expect(e.ticketActivo, isNull);
      expect(find.byKey(const ValueKey('btn-pedir-numero')), findsOneWidget);
    });

    testWidgets('el administrador atiende al siguiente de la cola',
        (tester) async {
      final e = _admin()..irAPestana(2);
      await _montar(tester, e);
      expect(e.enEspera, 4);

      final atender = find.byKey(const ValueKey('btn-atender'));
      await tester.ensureVisible(atender);
      await tester.tap(atender);
      await _avanzar(tester);

      expect(e.enEspera, 3);
    });
  });

  group('HU-11: modo contingencia', () {
    testWidgets('con el servicio caído la solicitud se guarda y luego se confirma',
        (tester) async {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      await _montar(tester, e);
      expect(find.textContaining('Servicio no disponible'), findsWidgets);

      await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
      await tester.tap(find.byKey(const ValueKey('accion-grupo')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.byKey(const ValueKey('btn-confirmar-sheet')));
      await _avanzar(tester);

      expect(e.pendientes, hasLength(1));
      expect(e.estaMatriculado('PE-B'), isFalse);
      expect(find.text('Solicitud pendiente de procesar'), findsOneWidget);

      e.cambiarServicio(disponible: true);
      await _avanzar(tester);
      expect(e.estaMatriculado('PE-B'), isTrue);
      expect(e.pendientes, isEmpty);
      await _cerrar(tester);
    });

    testWidgets('el administrador simula la caída desde el panel de operación',
        (tester) async {
      final e = _admin()..irAPestana(2);
      await _montar(tester, e);
      expect(e.servicioDisponible, isTrue);

      await tester.tap(find.byKey(const ValueKey('sw-servicio')));
      await _avanzar(tester);

      expect(e.servicioDisponible, isFalse);
      expect(find.textContaining('modo contingencia'), findsWidgets);
    });
  });

  group('HU-10: comprobante', () {
    testWidgets('el comprobante se copia al portapapeles', (tester) async {
      final copiado = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall llamada) async {
          if (llamada.method == 'Clipboard.setData') {
            final datos = llamada.arguments as Map<Object?, Object?>;
            copiado.add(datos['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final e = _estudiante();
      e.matricular('PE-B');
      await _montar(tester, e);
      await _abrir(tester, const ConfirmacionScreen(grupoId: 'PE-B'));

      expect(find.text(e.matriculas.first.codigo), findsOneWidget);
      final copiar = find.byKey(const ValueKey('btn-copiar-comprobante'));
      await tester.ensureVisible(copiar);
      await tester.tap(copiar);
      await _avanzar(tester);

      expect(copiado, [e.matriculas.first.codigo]);
      expect(find.text('Comprobante copiado'), findsOneWidget);
      await _cerrar(tester);
    });
  });

  group('Accesibilidad: texto grande (RNF de legibilidad)', () {
    void escalar(WidgetTester tester, double factor) {
      tester.platformDispatcher.textScaleFactorTestValue = factor;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('Ayuda con texto al 150 % no se desborda', (tester) async {
      escalar(tester, 1.5);
      await _montar(tester, _estudiante()..irAPestana(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Operación con texto al 150 % no se desborda', (tester) async {
      escalar(tester, 1.5);
      await _montar(tester, _admin()..irAPestana(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Grupo fuera de turno con texto al 150 % no se desborda',
        (tester) async {
      escalar(tester, 1.5);
      await _montar(tester, _estudiante(ciclo: 5));
      await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
      expect(tester.takeException(), isNull);
    });
  });
}
