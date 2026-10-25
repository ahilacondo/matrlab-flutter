// Prueba de humo: la aplicación arranca en la pantalla de inicio de sesión.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/app.dart';
import 'package:matrlab/estado.dart';

void main() {
  testWidgets('arranca en el inicio de sesión', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MatrLabApp(estado: MatrLabState()));

    expect(find.text('MatrLab'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
