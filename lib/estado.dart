import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'datos_demo.dart';
import 'models.dart';

/// Resultado de intentar matricularse en un grupo.
enum ResultadoMatricula { ok, sinCupo, yaMatriculado, cruceHorario }

/// Valida el código (estudiante: 8 dígitos; administrador: 4+ caracteres).
String? validarCodigo(String? valor, Rol rol) {
  final v = (valor ?? '').trim();
  if (v.isEmpty) return 'Ingresa tu código';
  if (rol == Rol.estudiante && !RegExp(r'^\d{8}$').hasMatch(v)) {
    return 'El código tiene 8 dígitos';
  }
  if (rol == Rol.administrador && v.length < 4) {
    return 'Usuario de al menos 4 caracteres';
  }
  return null;
}

String? validarClave(String? valor) {
  if ((valor ?? '').length < 4) return 'Mínimo 4 caracteres';
  return null;
}

/// Estado global de la aplicación (en memoria; sin servidor).
///
/// Es un [ChangeNotifier]: cada cambio llama a [notifyListeners] y las
/// pantallas que dependen de [MatrLabScope] se reconstruyen solas.
class MatrLabState extends ChangeNotifier {
  MatrLabState({
    List<Curso>? cursos,
    List<GrupoLab>? grupos,
    bool conAvisosIniciales = true,
  })  : cursos = cursos ?? datosCursos(),
        grupos = grupos ?? datosGrupos() {
    if (conAvisosIniciales) notificaciones.addAll(avisosIniciales());
  }

  final List<Curso> cursos;
  final List<GrupoLab> grupos;
  final List<Matricula> matriculas = [];
  final List<Notificacion> notificaciones = [];
  final Set<String> listaEspera = {};

  String? codigoUsuario;
  Rol rol = Rol.estudiante;
  int pestana = 0;

  // ---------------------------------------------------------------- sesión
  bool get sesionIniciada => codigoUsuario != null;
  bool get esAdmin => rol == Rol.administrador;

  void iniciarSesion(String codigo, Rol nuevoRol) {
    codigoUsuario = codigo;
    rol = nuevoRol;
    pestana = 0;
    notifyListeners();
  }

  void cerrarSesion() {
    codigoUsuario = null;
    pestana = 0;
    notifyListeners();
  }

  void irAPestana(int indice) {
    pestana = indice;
    notifyListeners();
  }

  // ------------------------------------------------------------- consultas
  Curso cursoPorCodigo(String codigo) =>
      cursos.firstWhere((c) => c.codigo == codigo);

  GrupoLab grupoPorId(String id) => grupos.firstWhere((g) => g.id == id);

  Curso cursoDeGrupo(GrupoLab g) => cursoPorCodigo(g.cursoCodigo);

  List<GrupoLab> gruposDe(String codigoCurso) =>
      grupos.where((g) => g.cursoCodigo == codigoCurso).toList();

  int cuposLibresDe(String codigoCurso) => gruposDe(codigoCurso)
      .fold<int>(0, (suma, g) => suma + math.max(0, g.cuposLibres));

  bool estaMatriculado(String grupoId) =>
      matriculas.any((m) => m.grupoId == grupoId);

  /// Grupo del mismo curso en el que ya está matriculado (si existe).
  GrupoLab? grupoMatriculadoDe(String codigoCurso) {
    for (final m in matriculas) {
      final g = grupoPorId(m.grupoId);
      if (g.cursoCodigo == codigoCurso) return g;
    }
    return null;
  }

  bool tieneCursoMatriculado(String codigoCurso) =>
      grupoMatriculadoDe(codigoCurso) != null;

  /// Devuelve el grupo ya matriculado con el que [g] se cruza, o null.
  GrupoLab? conflictoCon(GrupoLab g) {
    for (final m in matriculas) {
      final otro = grupoPorId(m.grupoId);
      if (otro.id != g.id && otro.horario.seCruzaCon(g.horario)) return otro;
    }
    return null;
  }

  bool enListaEspera(String grupoId) => listaEspera.contains(grupoId);

  // ------------------------------------------------------------- acciones
  ResultadoMatricula matricular(String grupoId) {
    final g = grupoPorId(grupoId);
    if (tieneCursoMatriculado(g.cursoCodigo)) {
      return ResultadoMatricula.yaMatriculado;
    }
    if (conflictoCon(g) != null) return ResultadoMatricula.cruceHorario;
    if (g.cuposLibres <= 0) return ResultadoMatricula.sinCupo;

    g.cuposOcupados++; // el cupo se reserva de inmediato
    matriculas.add(Matricula(grupoId: g.id, fecha: DateTime.now()));
    listaEspera.remove(g.id);
    _notificar(
      'Matrícula confirmada',
      '${cursoDeGrupo(g).nombre} · ${g.nombre} (${g.horario.texto}).',
      TipoNotificacion.matricula,
    );
    notifyListeners();
    return ResultadoMatricula.ok;
  }

  void cancelarMatricula(String grupoId) {
    final antes = matriculas.length;
    matriculas.removeWhere((m) => m.grupoId == grupoId);
    if (matriculas.length == antes) return;
    final g = grupoPorId(grupoId);
    g.cuposOcupados = math.max(0, g.cuposOcupados - 1);
    _notificar(
      'Matrícula cancelada',
      'Liberaste un cupo en ${cursoDeGrupo(g).nombre} · ${g.nombre}.',
      TipoNotificacion.aviso,
    );
    notifyListeners();
  }

  void unirseAListaEspera(String grupoId) {
    final g = grupoPorId(grupoId);
    if (g.cuposLibres > 0 || listaEspera.contains(grupoId)) return;
    listaEspera.add(grupoId);
    _notificar(
      'Estás en la lista de espera',
      '${cursoDeGrupo(g).nombre} · ${g.nombre}. Te avisaremos si se libera un cupo.',
      TipoNotificacion.listaEspera,
    );
    notifyListeners();
  }

  /// Acción del administrador: cambia el total de cupos de un grupo.
  /// Si hay cupos libres y alguien esperaba, se genera la notificación.
  void ajustarCupos(String grupoId, int delta) {
    final g = grupoPorId(grupoId);
    g.cuposTotales = math.max(g.cuposOcupados, g.cuposTotales + delta);
    if (g.cuposLibres > 0 && listaEspera.remove(grupoId)) {
      _notificar(
        'Se liberó un cupo',
        '${cursoDeGrupo(g).nombre} · ${g.nombre} ya tiene cupos disponibles. ¡Matricúlate!',
        TipoNotificacion.cupoLiberado,
      );
    }
    notifyListeners();
  }

  void marcarLeidas() {
    for (final n in notificaciones) {
      n.leida = true;
    }
    notifyListeners();
  }

  void _notificar(String titulo, String mensaje, TipoNotificacion tipo) {
    notificaciones.insert(
      0,
      Notificacion(
        titulo: titulo,
        mensaje: mensaje,
        fecha: DateTime.now(),
        tipo: tipo,
      ),
    );
  }

  // ------------------------------------------------------------- métricas
  int get noLeidas => notificaciones.where((n) => !n.leida).length;

  int get cuposTotales => grupos.fold<int>(0, (s, g) => s + g.cuposTotales);

  int get cuposOcupados => grupos.fold<int>(0, (s, g) => s + g.cuposOcupados);

  int get cuposLibres => cuposTotales - cuposOcupados;

  double get ocupacionGlobal =>
      cuposTotales == 0 ? 0.0 : cuposOcupados / cuposTotales;

  List<GrupoLab> gruposPorOcupacion() {
    final copia = List<GrupoLab>.of(grupos);
    copia.sort((a, b) => b.ocupacion.compareTo(a.ocupacion));
    return copia;
  }
}

/// Expone el [MatrLabState] a todo el árbol de widgets.
class MatrLabScope extends InheritedNotifier<MatrLabState> {
  const MatrLabScope({
    super.key,
    required MatrLabState estado,
    required super.child,
  }) : super(notifier: estado);

  /// Lee el estado y SUSCRIBE al widget: se reconstruye cuando cambia.
  static MatrLabState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MatrLabScope>();
    assert(scope != null, 'Falta MatrLabScope encima en el árbol de widgets');
    return scope!.notifier!;
  }

  /// Lee el estado sin suscribirse (para usarlo dentro de callbacks).
  static MatrLabState leer(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<MatrLabScope>();
    assert(scope != null, 'Falta MatrLabScope encima en el árbol de widgets');
    return scope!.notifier!;
  }
}
