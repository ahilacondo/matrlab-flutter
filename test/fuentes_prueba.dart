// Carga las fuentes del SDK de Flutter para las pruebas de interfaz.
//
// Por defecto flutter_test dibuja todo el texto con la fuente "Ahem" (cuadrados
// anchos) y los iconos como cuadros. Cargando Roboto y MaterialIcons el
// resultado se parece a un teléfono Android.
import 'dart:io';

import 'package:flutter/services.dart';

Future<void> cargarFuentesDePrueba() async {
  final raizFlutter = Platform.environment['FLUTTER_ROOT'];
  if (raizFlutter == null) return;
  final carpeta = Directory('$raizFlutter/bin/cache/artifacts/material_fonts');
  if (!carpeta.existsSync()) return;

  final roboto = FontLoader('Roboto');
  for (final nombre in const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final f = File('${carpeta.path}/$nombre');
    if (f.existsSync()) {
      roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await roboto.load();

  final iconos = File('${carpeta.path}/MaterialIcons-Regular.otf');
  if (iconos.existsSync()) {
    final cargador = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync())));
    await cargador.load();
  }
}
