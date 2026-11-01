import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'datos_demo.dart';
import 'models.dart';

/// Resultado de intentar matricularse en un grupo.
///
/// [pendiente]: el servicio no estaba disponible y la solicitud quedó guardada.
/// [fueraDeTurno]: el turno del estudiante aún no inicia.
/// [yaPendiente]: ya existe una solicitud pendiente para ese curso.
enum ResultadoMatricula {
  ok,
  sinCupo,
  yaMatriculado,
  cruceHorario,
  fueraDeTurno,
  pendiente,
  yaPendiente,
}

/// Función que entrega la hora actual (se reemplaza en las pruebas).
typedef Reloj = DateTime Function();

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
    bool conColaDemo = true,
    Reloj? reloj,
  })  : cursos = cursos ?? datosCursos(),
        grupos = grupos ?? datosGrupos(),
        reloj = reloj ?? DateTime.now {
    if (conAvisosIniciales) notificaciones.addAll(avisosIniciales());
    turnos = datosTurnos(this.reloj());
    if (conColaDemo) {
      tickets.addAll(ticketsDemo(this.reloj()));
      _ultimoTicket = 20;
    }
  }

  final List<Curso> cursos;
  final List<GrupoLab> grupos;
  final List<Matricula> matriculas = [];
  final List<Notificacion> notificaciones = [];
  final Set<String> listaEspera = {};

  /// Reloj del sistema; en las pruebas se sustituye por uno controlado.
  final Reloj reloj;

  /// Turnos escalonados de matrícula (HU-08).
  late final List<TurnoMatricula> turnos;

  /// Cola de atención virtual (HU-09).
  final List<TicketAtencion> tickets = [];

  /// Solicitudes guardadas mientras el servicio no estaba disponible (HU-11),
  /// en orden de llegada.
  final List<SolicitudPendiente> pendientes = [];

  /// Minutos que se estima por cada persona atendida (valor de demostración).
  static const int minutosPorAtencion = 5;

  String? codigoUsuario;
  Rol rol = Rol.estudiante;
  int pestana = 0;

  /// Ciclo del estudiante (define su turno). Se elige al iniciar sesión.
  int cicloEstudiante = 10;

  /// false = simulación de caída del servicio (modo contingencia).
  bool servicioDisponible = true;

  int _ultimoTicket = 0;
  int _consecutivo = 0;

  DateTime get ahora => reloj();

  // ---------------------------------------------------------------- sesión
  bool get sesionIniciada => codigoUsuario != null;
  bool get esAdmin => rol == Rol.administrador;

  void iniciarSesion(String codigo, Rol nuevoRol, {int ciclo = 10}) {
    codigoUsuario = codigo;
    rol = nuevoRol;
    cicloEstudiante = ciclo;
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

  // ---------------------------------------------------------------- turnos
  /// Turno que le corresponde al ciclo del estudiante (null si no hay).
  TurnoMatricula? get turnoDelEstudiante {
    for (final t in turnos) {
      if (t.incluyeCiclo(cicloEstudiante)) return t;
    }
    return null;
  }

  /// true si el turno del estudiante ya inició (el administrador no tiene turno).
  bool get turnoAbierto {
    if (esAdmin) return true;
    final t = turnoDelEstudiante;
    return t != null && t.haIniciado(ahora);
  }

  /// Explica por qué un estudiante no puede matricularse en [g], o null si puede
  /// (HU-12: el sistema siempre dice el motivo y qué hacer).
  String? motivoBloqueo(GrupoLab g) {
    if (esAdmin) return null;
    if (!turnoAbierto) {
      final t = turnoDelEstudiante;
      if (t == null) return 'Tu ciclo no tiene un turno asignado.';
      return 'Tu turno (${t.nombre}) inicia el ${formatoFechaHora(t.inicio)}; '
          'faltan ${formatoFaltante(t.inicio.difference(ahora))}. '
          'Mientras tanto puedes revisar cursos y horarios.';
    }
    final otro = grupoMatriculadoDe(g.cursoCodigo);
    if (otro != null && otro.id != g.id) {
      return 'Ya estás matriculado en ${otro.nombre} de este curso.';
    }
    final choque = conflictoCon(g);
    if (choque != null) {
      return 'Se cruza con ${cursoDeGrupo(choque).nombre} · ${choque.nombre} '
          '(${choque.horario.texto}). Elige otro grupo.';
    }
    return null;
  }

  // ------------------------------------------------------------- acciones
  bool tienePendiente(String grupoId) =>
      pendientes.any((p) => p.grupoId == grupoId);

  bool tienePendienteDeCurso(String codigoCurso) =>
      pendientes.any((p) => grupoPorId(p.grupoId).cursoCodigo == codigoCurso);

  String _siguienteCodigo(String prefijo) {
    _consecutivo++;
    return '$prefijo-2026B-${_consecutivo.toString().padLeft(4, '0')}';
  }

  /// Reglas que no dependen del servidor (turno, curso repetido, cruce).
  ResultadoMatricula? _validarLocal(GrupoLab g) {
    if (!turnoAbierto) return ResultadoMatricula.fueraDeTurno;
    if (tieneCursoMatriculado(g.cursoCodigo)) {
      return ResultadoMatricula.yaMatriculado;
    }
    if (tienePendienteDeCurso(g.cursoCodigo)) {
      return ResultadoMatricula.yaPendiente;
    }
    if (conflictoCon(g) != null) return ResultadoMatricula.cruceHorario;
    return null;
  }

  /// Reserva el cupo y registra la matrícula con su comprobante.
  void _confirmar(GrupoLab g) {
    g.cuposOcupados++; // el cupo se reserva de inmediato
    matriculas.add(Matricula(
      grupoId: g.id,
      fecha: ahora,
      codigo: _siguienteCodigo('MLB'),
    ));
    listaEspera.remove(g.id);
    _notificar(
      'Matrícula confirmada',
      '${cursoDeGrupo(g).nombre} · ${g.nombre} (${g.horario.texto}).',
      TipoNotificacion.matricula,
    );
  }

  ResultadoMatricula matricular(String grupoId) {
    final g = grupoPorId(grupoId);
    final bloqueo = _validarLocal(g);
    if (bloqueo != null) return bloqueo;

    if (!servicioDisponible) {
      // Modo contingencia: se guarda la solicitud y se decide al restablecerse.
      pendientes.add(SolicitudPendiente(
        grupoId: g.id,
        creada: ahora,
        codigo: _siguienteCodigo('SOL'),
      ));
      _notificar(
        'Solicitud guardada',
        '${cursoDeGrupo(g).nombre} · ${g.nombre}. Se procesará por orden de '
            'llegada cuando el servicio se restablezca.',
        TipoNotificacion.servicio,
      );
      notifyListeners();
      return ResultadoMatricula.pendiente;
    }

    if (g.cuposLibres <= 0) return ResultadoMatricula.sinCupo;
    _confirmar(g);
    notifyListeners();
    return ResultadoMatricula.ok;
  }

  /// Quita una solicitud pendiente antes de que se procese.
  void cancelarSolicitud(String grupoId) {
    final antes = pendientes.length;
    pendientes.removeWhere((p) => p.grupoId == grupoId);
    if (pendientes.length != antes) notifyListeners();
  }

  /// Simula la caída (o el restablecimiento) del servicio. Al restablecerse se
  /// procesan las solicitudes pendientes en orden de llegada.
  void cambiarServicio({required bool disponible}) {
    if (servicioDisponible == disponible) return;
    servicioDisponible = disponible;
    if (disponible) {
      final cantidad = pendientes.length;
      _notificar(
        'Servicio restablecido',
        cantidad == 0
            ? 'Ya puedes matricularte con normalidad.'
            : 'Procesamos $cantidad solicitud(es) pendiente(s) por orden de '
                'llegada.',
        TipoNotificacion.servicio,
      );
      _procesarPendientes();
    } else {
      _notificar(
        'Servicio no disponible',
        'Puedes seguir eligiendo grupos: guardaremos tus solicitudes y las '
            'procesaremos cuando el servicio se restablezca.',
        TipoNotificacion.servicio,
      );
    }
    notifyListeners();
  }

  void _procesarPendientes() {
    final cola = List<SolicitudPendiente>.of(pendientes);
    pendientes.clear();
    for (final s in cola) {
      final g = grupoPorId(s.grupoId);
      final nombre = '${cursoDeGrupo(g).nombre} · ${g.nombre}';
      String? motivo;
      if (tieneCursoMatriculado(g.cursoCodigo)) {
        motivo = 'ya tenías un grupo de este curso';
      } else if (conflictoCon(g) != null) {
        motivo = 'el horario se cruza con otro grupo ya matriculado';
      } else if (g.cuposLibres <= 0) {
        motivo = 'el grupo se llenó antes de que el servicio se restableciera';
      }
      if (motivo == null) {
        _confirmar(g);
      } else {
        _notificar(
          'Solicitud no confirmada',
          '$nombre: $motivo. Elige otro grupo o únete a la lista de espera.',
          TipoNotificacion.servicio,
        );
      }
    }
  }

  // ------------------------------------------------- número de atención
  /// Número de atención en espera del usuario actual (null si no tiene).
  TicketAtencion? get ticketActivo {
    for (final t in tickets) {
      if (t.codigoEstudiante == codigoUsuario &&
          t.estado == EstadoTicket.esperando) {
        return t;
      }
    }
    return null;
  }

  int get enEspera =>
      tickets.where((t) => t.estado == EstadoTicket.esperando).length;

  /// Posición en la cola (1 = siguiente en ser atendido).
  int posicionDe(TicketAtencion t) {
    var posicion = 1;
    for (final otro in tickets) {
      if (otro.estado == EstadoTicket.esperando && otro.numero < t.numero) {
        posicion++;
      }
    }
    return posicion;
  }

  /// Espera estimada: personas delante por [minutosPorAtencion].
  int minutosEstimados(TicketAtencion t) =>
      (posicionDe(t) - 1) * minutosPorAtencion;

  /// Pide un número de atención virtual (uno activo por estudiante).
  TicketAtencion? solicitarTicket(String motivo) {
    final codigo = codigoUsuario;
    if (codigo == null || esAdmin || ticketActivo != null) return null;
    _ultimoTicket++;
    final t = TicketAtencion(
      numero: _ultimoTicket,
      codigoEstudiante: codigo,
      motivo: motivo,
      creado: ahora,
    );
    tickets.add(t);
    final delante = posicionDe(t) - 1;
    _notificar(
      'Número de atención ${t.etiqueta}',
      delante == 0
          ? 'Eres el siguiente. No necesitas hacer fila.'
          : 'Hay $delante persona(s) delante de ti. No necesitas hacer fila: '
              'te avisaremos cuando se acerque tu turno.',
      TipoNotificacion.ticket,
    );
    notifyListeners();
    return t;
  }

  void cancelarTicket() {
    final t = ticketActivo;
    if (t == null) return;
    t.estado = EstadoTicket.cancelado;
    notifyListeners();
  }

  /// Acción del administrador: atiende al siguiente número en espera y avisa
  /// a quien pasa a ser el siguiente si es un estudiante real (no de demostración).
  TicketAtencion? atenderSiguiente() {
    TicketAtencion? atendido;
    for (final t in tickets) {
      if (t.estado == EstadoTicket.esperando) {
        atendido = t;
        break;
      }
    }
    if (atendido == null) return null;
    atendido.estado = EstadoTicket.atendido;
    for (final t in tickets) {
      if (t.estado == EstadoTicket.esperando) {
        if (t.codigoEstudiante != codigoTicketDemo) {
          _notificar(
            'Es tu turno: ${t.etiqueta}',
            'Acércate a la dirección de escuela; te atenderán ahora.',
            TipoNotificacion.ticket,
          );
        }
        break;
      }
    }
    notifyListeners();
    return atendido;
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
        fecha: ahora,
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
