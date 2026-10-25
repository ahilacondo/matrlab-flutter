// Prueba de interfaz: recorre el flujo principal (login -> curso -> grupo
// -> confirmar -> horario) con widgets reales.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/app.dart';
import 'package:matrlab/estado.dart';

import 'fuentes_prueba.dart';

/// Deja que la pantalla se construya y que termine la animación de la ruta
/// (mismo ritmo que usan las pruebas de capturas).
Future<void> _avanzar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

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
    await _avanzar(tester);
    expect(find.text('Plataformas Emergentes'), findsOneWidget);

    // Curso -> grupo.
    await tester.tap(find.text('Plataformas Emergentes'));
    await _avanzar(tester);
    await tester.tap(find.text('Grupo B'));
    await _avanzar(tester);

    // Matricularme -> confirmar en la hoja inferior.
    await tester.tap(find.byKey(const ValueKey('accion-grupo')));
    await _avanzar(tester);
    expect(find.text('Confirmar matrícula'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('btn-confirmar-sheet')));
    await _avanzar(tester);

    expect(find.text('¡Matrícula confirmada!'), findsOneWidget);
    expect(estado.estaMatriculado('PE-B'), isTrue);

    // Ver mi horario.
    await tester.tap(find.byKey(const ValueKey('btn-ver-horario')));
    await _avanzar(tester);
    expect(find.text('Horario semanal'), findsOneWidget);
    expect(find.text('Mis matrículas'), findsOneWidget);
  });
}
