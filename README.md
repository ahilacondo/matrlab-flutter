# MatrLab (Flutter)

Aplicación de matrícula en laboratorios para la Escuela Profesional de Ingeniería de Sistemas (UNSA).
Laboratorio 04 de Plataformas Emergentes: interfaces con los componentes propios de un framework multiplataforma (Flutter), basadas en un árbol de problemas.

**Autor:** Andre Jimmy Hilacondo Begazo

## Contenido
- `lib/` código de la aplicación (modelos, estado, widgets comunes y 9 pantallas)
- `test/` pruebas de reglas de negocio, de flujo de UI y generación de capturas
- `informe/` informe del laboratorio en LaTeX (`INFORME_LAB04_MatrLab.pdf` es la versión compilada)

## Cómo abrir y ejecutar la aplicación
Requisitos: Flutter SDK (3.24 o superior, Dart 3.5+) y Android Studio (para el emulador). Verificar con `flutter doctor`.

```powershell
git clone <url-del-repositorio>
cd matrlab-flutter
flutter create --project-name matrlab --platforms android,web .   # solo la primera vez
flutter pub get
flutter run                 # elige el emulador o el celular Android conectado
flutter run -d chrome       # alternativa en el navegador
```

Credenciales de la demo: estudiante con un código de 8 dígitos (por ejemplo `20201234`) y cualquier clave de 4 caracteres o más; administrador con un código de 4 o más caracteres (por ejemplo `admin`).

## Pruebas y capturas
```powershell
flutter analyze
flutter test          # además guarda 17 capturas en .\capturas
```
Luego, en `informe/`: `latexmk -pdf informe.tex` toma las capturas de `..\capturas` automáticamente.

También puede usarse `.\ejecutar.ps1`, que hace todo lo anterior.
