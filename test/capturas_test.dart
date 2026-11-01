// Genera las capturas de pantalla del informe (carpeta capturas/).
//
// Cada prueba monta la aplicación real, lleva el estado a un punto concreto
// del flujo y guarda un PNG del árbol de widgets renderizado por el motor de
// Flutter (flutter_test). Las fuentes Roboto se cargan desde el SDK para que
// el texto se vea igual que en un teléfono Android.
//
// Ejecución:  flutter test test/capturas_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/app.dart';
import 'package:matrlab/datos_demo.dart';
import 'package:matrlab/estado.dart';
import 'package:matrlab/models.dart';
import 'package:matrlab/screens/confirmacion_screen.dart';
import 'package:matrlab/screens/curso_detalle_screen.dart';
import 'package:matrlab/screens/grupo_detalle_screen.dart';

import 'fuentes_prueba.dart';

final GlobalKey _raiz = GlobalKey();

/// Monta la app con tamaño de pantalla lógico [ancho] x [alto] (dp).
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
  await tester.pumpWidget(RepaintBoundary(
    key: _raiz,
    child: MatrLabApp(estado: estado),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  final navegador =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  unawaited(navegador.push(MaterialPageRoute<void>(builder: (_) => pantalla)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _capturar(WidgetTester tester, String nombre,
    {double pixelRatio = 2.0}) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final limite = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(_raiz));
    final imagen = await limite.toImage(pixelRatio: pixelRatio);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    final archivo = File('capturas/$nombre.png');
    archivo.parent.createSync(recursive: true);
    archivo.writeAsBytesSync(datos!.buffer.asUint8List());
  });
}

/// Hora fija: así los turnos y los avisos salen iguales en cada ejecución.
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

void main() {
  setUpAll(cargarFuentesDePrueba);

  testWidgets('c01 login', (tester) async {
    await _montar(tester, MatrLabState());
    await _capturar(tester, 'c01_login');
  });

  testWidgets('c02 login con validación', (tester) async {
    await _montar(tester, MatrLabState());
    await tester.tap(find.text('Ingresar'));
    await tester.pump(const Duration(milliseconds: 300));
    await _capturar(tester, 'c02_login_validacion');
  });

  testWidgets('c03 cursos', (tester) async {
    await _montar(tester, _estudiante());
    await _capturar(tester, 'c03_cursos');
  });

  testWidgets('c04 búsqueda de cursos', (tester) async {
    await _montar(tester, _estudiante());
    await tester.enterText(find.byType(SearchBar), 'datos');
    await tester.pump(const Duration(milliseconds: 400));
    await _capturar(tester, 'c04_cursos_busqueda');
  });

  testWidgets('c05 detalle de curso', (tester) async {
    await _montar(tester, _estudiante());
    await _abrir(tester, const CursoDetalleScreen(codigoCurso: 'IS-742'));
    await _capturar(tester, 'c05_curso_detalle');
  });

  testWidgets('c06 detalle de grupo', (tester) async {
    await _montar(tester, _estudiante());
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-A'));
    await _capturar(tester, 'c06_grupo_detalle');
  });

  testWidgets('c07 hoja de confirmación', (tester) async {
    await _montar(tester, _estudiante());
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-A'));
    await tester.tap(find.byKey(const ValueKey('accion-grupo')));
    await tester.pump(const Duration(milliseconds: 700));
    await _capturar(tester, 'c07_confirmar_sheet');
  });

  testWidgets('c08 matrícula confirmada', (tester) async {
    final e = _estudiante();
    e.matricular('PE-A');
    await _montar(tester, e);
    await _abrir(tester, const ConfirmacionScreen(grupoId: 'PE-A'));
    await _capturar(tester, 'c08_confirmacion');
  });

  testWidgets('c09 horario con dos matrículas', (tester) async {
    final e = _estudiante();
    e.matricular('PE-A');
    e.matricular('SI-B');
    e.irAPestana(1);
    await _montar(tester, e);
    await _capturar(tester, 'c09_horario');
  });

  testWidgets('c10 horario vacío', (tester) async {
    final e = _estudiante();
    e.irAPestana(1);
    await _montar(tester, e);
    await _capturar(tester, 'c10_horario_vacio');
  });

  testWidgets('c11 cruce de horario', (tester) async {
    final e = _estudiante();
    e.matricular('PE-A');
    await _montar(tester, e);
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'RC-A'));
    await _capturar(tester, 'c11_cruce_horario');
  });

  testWidgets('c12 grupo lleno', (tester) async {
    await _montar(tester, _estudiante());
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'BD2-B'));
    await _capturar(tester, 'c12_grupo_lleno');
  });

  testWidgets('c13 alertas con lista de espera', (tester) async {
    final e = _estudiante();
    e.matricular('PE-A');
    e.unirseAListaEspera('BD2-B');
    e.irAPestana(2);
    await _montar(tester, e);
    await _capturar(tester, 'c13_alertas_espera');
  });

  testWidgets('c14 panel del administrador', (tester) async {
    final e = MatrLabState();
    e.iniciarSesion('admin', Rol.administrador);
    e.irAPestana(1);
    await _montar(tester, e);
    await _capturar(tester, 'c14_panel_admin');
  });

  testWidgets('c15 cupo liberado', (tester) async {
    final e = _estudiante();
    e.unirseAListaEspera('BD2-B');
    e.ajustarCupos('BD2-B', 1); // acción del administrador
    e.irAPestana(2);
    await _montar(tester, e);
    await _capturar(tester, 'c15_alertas_cupo_liberado');
  });

  testWidgets('c16 tablet: riel de navegación', (tester) async {
    await _montar(tester, _estudiante(), ancho: 1000, alto: 640);
    await _capturar(tester, 'c16_tablet_cursos');
  });

  testWidgets('c17 tablet: horario', (tester) async {
    final e = _estudiante();
    e.matricular('PE-A');
    e.matricular('SI-B');
    e.irAPestana(1);
    await _montar(tester, e, ancho: 1000, alto: 640);
    await _capturar(tester, 'c17_tablet_horario');
  });

  // ------------------------------------------------------------ Laboratorio 05
  testWidgets('c18 cursos con turno pendiente', (tester) async {
    await _montar(tester, _estudiante(ciclo: 5));
    await _capturar(tester, 'c18_cursos_turno_pendiente');
  });

  testWidgets('c19 grupo fuera de turno', (tester) async {
    await _montar(tester, _estudiante(ciclo: 5));
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
    await _capturar(tester, 'c19_grupo_fuera_turno');
  });

  testWidgets('c20 ayuda: turnos y servicio', (tester) async {
    final e = _estudiante(ciclo: 5)..irAPestana(3);
    await _montar(tester, e);
    await _capturar(tester, 'c20_ayuda_turnos');
  });

  testWidgets('c21 ayuda: número de atención', (tester) async {
    final e = _estudiante()..irAPestana(3);
    e.solicitarTicket(motivosTicket.first);
    await _montar(tester, e);
    await tester.ensureVisible(find.byKey(const ValueKey('btn-cancelar-numero')));
    await _capturar(tester, 'c21_ayuda_numero');
  });

  testWidgets('c22 ayuda: preguntas frecuentes', (tester) async {
    final e = _estudiante()..irAPestana(3);
    await _montar(tester, e);
    await tester.ensureVisible(find.text('¿Cómo se calcula la espera de mi número?'));
    await _capturar(tester, 'c22_ayuda_preguntas');
  });

  testWidgets('c23 operación: servicio y turnos', (tester) async {
    final e = _admin()..irAPestana(2);
    await _montar(tester, e);
    await _capturar(tester, 'c23_operacion_servicio');
  });

  testWidgets('c24 operación: cola de atención', (tester) async {
    final e = _admin()..irAPestana(2);
    e.atenderSiguiente();
    await _montar(tester, e);
    await tester.ensureVisible(find.byKey(const ValueKey('btn-atender')));
    await _capturar(tester, 'c24_operacion_cola');
  });

  testWidgets('c25 grupo con el servicio caído', (tester) async {
    final e = _estudiante();
    e.cambiarServicio(disponible: false);
    await _montar(tester, e);
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
    await _capturar(tester, 'c25_grupo_servicio_caido');
  });

  testWidgets('c26 hoja para guardar la solicitud', (tester) async {
    final e = _estudiante();
    e.cambiarServicio(disponible: false);
    await _montar(tester, e);
    await _abrir(tester, const GrupoDetalleScreen(grupoId: 'PE-B'));
    await tester.tap(find.byKey(const ValueKey('accion-grupo')));
    await tester.pump(const Duration(milliseconds: 700));
    await _capturar(tester, 'c26_hoja_guardar_solicitud');
  });

  testWidgets('c27 horario con solicitud pendiente', (tester) async {
    final e = _estudiante();
    e.cambiarServicio(disponible: false);
    e.matricular('PE-B');
    e.irAPestana(1);
    await _montar(tester, e);
    await tester.scrollUntilVisible(
      find.text('Solicitudes pendientes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _capturar(tester, 'c27_horario_solicitud_pendiente');
  });

  testWidgets('c28 alertas tras restablecer el servicio', (tester) async {
    final e = _estudiante();
    e.cambiarServicio(disponible: false);
    e.matricular('PE-B');
    e.cambiarServicio(disponible: true);
    e.irAPestana(2);
    await _montar(tester, e);
    await _capturar(tester, 'c28_alertas_servicio_restablecido');
  });

  testWidgets('c29 ayuda con texto al 150 %', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final e = _estudiante()..irAPestana(3);
    await _montar(tester, e);
    await _capturar(tester, 'c29_ayuda_texto_grande');
  });

  testWidgets('c30 tablet: ayuda', (tester) async {
    final e = _estudiante(ciclo: 5)..irAPestana(3);
    await _montar(tester, e, ancho: 1000, alto: 640);
    await _capturar(tester, 'c30_tablet_ayuda');
  });
}
