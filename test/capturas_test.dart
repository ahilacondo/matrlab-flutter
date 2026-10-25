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

MatrLabState _estudiante() {
  final e = MatrLabState();
  e.iniciarSesion('20241234', Rol.estudiante);
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
}
