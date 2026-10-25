// Prueba de interfaz: recorre el flujo principal (login -> curso -> grupo
// -> confirmar -> horario) con widgets reales.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/app.dart';
import 'package:matrlab/estado.dart';

import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesDePrueba);

  testWidgets('flujo completo de matrícula del estudiante', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = MatrLabState();
    await tester.pumpWidget(MatrLabApp(estado: estado));

    // Login con validación.
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('Ingresa tu código'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '20241234');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave');
    await tester.tap(find.text('Ingresar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Plataformas Emergentes'), findsOneWidget);

    // Curso -> grupo.
    await tester.tap(find.text('Plataformas Emergentes'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Grupo B'));
    await tester.pump(const Duration(milliseconds: 600));

    // Matricularme -> confirmar en la hoja inferior.
    await tester.tap(find.byKey(const ValueKey('accion-grupo')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Confirmar matrícula'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('btn-confirmar-sheet')));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('¡Matrícula confirmada!'), findsOneWidget);
    expect(estado.estaMatriculado('PE-B'), isTrue);

    // Ver mi horario.
    await tester.tap(find.byKey(const ValueKey('btn-ver-horario')));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Horario semanal'), findsOneWidget);
    expect(find.text('Mis matrículas'), findsOneWidget);
  });
}
