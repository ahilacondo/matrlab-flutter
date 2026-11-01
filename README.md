# MatrLab (Flutter)

Aplicación de matrícula en laboratorios para la Escuela Profesional de Ingeniería de Sistemas (UNSA).

- **Laboratorio 04** (v1.x): interfaces con componentes de Flutter a partir de un árbol de problemas.
- **Laboratorio 05** (v2.0): requisitos respaldados por casos reales de matrícula en la UNSA, proceso Scrum adaptado y cuatro historias nuevas con enfoque de proyección social (acceso equitativo y atención sin fila).

**Autor:** Andre Jimmy Hilacondo Begazo

## Qué agrega la versión 2.0
| HU | Funcionalidad | Dónde está |
|----|---------------|------------|
| HU-08 | Turnos escalonados de matrícula por ciclo | `estado.dart`, `AvisoTurno`, Ayuda, Operación |
| HU-09 | Número de atención virtual (sin fila presencial) | Ayuda (estudiante), Operación (administrador) |
| HU-10 | Comprobante con código y botón «Copiar» | `confirmacion_screen.dart` |
| HU-11 | Modo contingencia: solicitudes guardadas si el servicio cae | `estado.dart`, `BannerServicio`, Horario |
| HU-12 | Explicación del bloqueo y preguntas frecuentes | `motivoBloqueo`, Ayuda |

La caída del servicio se **simula** con un interruptor del administrador (pestaña Operación); la aplicación sigue sin servidor y con datos en memoria.

## Contenido
- `lib/` código de la aplicación (modelos, estado, widgets comunes y 11 pantallas)
- `test/` pruebas de reglas de negocio, de interfaz y generación de capturas
- `informe/` informe del laboratorio en LaTeX

## Cómo abrir y ejecutar la aplicación
Requisitos: Flutter SDK (3.24 o superior, Dart 3.5+) y Android Studio (para el emulador). Verificar con `flutter doctor`.

```powershell
cd matrlab-flutter
flutter create --project-name matrlab --platforms android,web .   # solo la primera vez
flutter pub get
flutter run                 # elige el emulador o el celular Android conectado
flutter run -d chrome       # alternativa en el navegador
```

Credenciales de la demo: estudiante con un código de 8 dígitos (por ejemplo `20201234`), cualquier clave de 4 caracteres o más y un ciclo (el ciclo 10 tiene el turno abierto; el 5 aún no); administrador con un código de 4 o más caracteres (por ejemplo `admin`).

## Pruebas y capturas
```powershell
flutter analyze
flutter test          # además guarda 30 capturas en .\capturas
```
También puede usarse `.\ejecutar.ps1`, que hace todo lo anterior, guarda las salidas en `salida_analyze.txt` y `salida_test.txt` y el historial de commits en `historial_git.txt`.
