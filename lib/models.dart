import 'package:flutter/material.dart';

/// Rol con el que se inicia sesión.
enum Rol { estudiante, administrador }

/// Nivel de ocupación de un grupo de laboratorio.
enum EstadoCupo { disponible, casiLleno, lleno }

/// Tipos de notificación que muestra la pestaña «Alertas».
enum TipoNotificacion {
  matricula,
  cupoLiberado,
  listaEspera,
  aviso,
  ticket,
  servicio,
}

/// Estado de un número de atención virtual.
enum EstadoTicket { esperando, atendido, cancelado }

const List<String> _diasCortos = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie'];

String _hora(int h) => '${h.toString().padLeft(2, '0')}:00';

/// Franja semanal de un grupo (día 1 = lunes … 5 = viernes; horas enteras).
class Horario {
  const Horario(this.dia, this.inicio, this.fin);

  final int dia;
  final int inicio;
  final int fin;

  String get diaCorto => _diasCortos[dia];
  String get texto => '$diaCorto ${_hora(inicio)}–${_hora(fin)}';

  /// Dos franjas se cruzan si son del mismo día y sus intervalos se solapan.
  bool seCruzaCon(Horario otro) =>
      dia == otro.dia && inicio < otro.fin && otro.inicio < fin;
}

class Curso {
  const Curso({
    required this.codigo,
    required this.sigla,
    required this.nombre,
    required this.docente,
    required this.descripcion,
    required this.icono,
  });

  final String codigo;
  final String sigla;
  final String nombre;
  final String docente;
  final String descripcion;
  final IconData icono;
}

class GrupoLab {
  GrupoLab({
    required this.id,
    required this.cursoCodigo,
    required this.nombre,
    required this.horario,
    required this.aula,
    required this.cuposTotales,
    required this.cuposOcupados,
  });

  final String id;
  final String cursoCodigo;
  final String nombre;
  final Horario horario;
  final String aula;
  int cuposTotales;
  int cuposOcupados;

  int get cuposLibres => cuposTotales - cuposOcupados;

  double get ocupacion =>
      cuposTotales == 0 ? 1.0 : cuposOcupados / cuposTotales;

  EstadoCupo get estado {
    if (cuposLibres <= 0) return EstadoCupo.lleno;
    if (ocupacion >= 0.85) return EstadoCupo.casiLleno;
    return EstadoCupo.disponible;
  }
}

class Matricula {
  Matricula({required this.grupoId, required this.fecha, this.codigo = ''});

  final String grupoId;
  final DateTime fecha;

  /// Código de comprobante (por ejemplo MLB-2026B-0001).
  final String codigo;
  final String estado = 'Confirmada';
}

/// Ventana de matrícula asignada a un rango de ciclos (HU-08).
///
/// Un estudiante puede matricularse desde que inicia su turno y hasta que
/// termina el proceso; el escalonamiento reparte el momento de inicio, de modo
/// que no todos compiten por los mismos cupos en el mismo segundo.
class TurnoMatricula {
  const TurnoMatricula({
    required this.nombre,
    required this.cicloMin,
    required this.cicloMax,
    required this.inicio,
    required this.fin,
  });

  final String nombre;
  final int cicloMin;
  final int cicloMax;
  final DateTime inicio;
  final DateTime fin;

  bool incluyeCiclo(int ciclo) => ciclo >= cicloMin && ciclo <= cicloMax;

  bool haIniciado(DateTime ahora) => !ahora.isBefore(inicio);

  bool enCurso(DateTime ahora) => haIniciado(ahora) && ahora.isBefore(fin);

  String get rangoCiclos =>
      cicloMin == cicloMax ? 'Ciclo $cicloMin' : 'Ciclos $cicloMin–$cicloMax';

  String estadoEn(DateTime ahora) {
    if (!haIniciado(ahora)) return 'Programado';
    return enCurso(ahora) ? 'En curso' : 'Finalizado';
  }
}

/// Número de atención virtual: reemplaza la fila presencial (HU-09).
class TicketAtencion {
  TicketAtencion({
    required this.numero,
    required this.codigoEstudiante,
    required this.motivo,
    required this.creado,
    this.estado = EstadoTicket.esperando,
  });

  final int numero;
  final String codigoEstudiante;
  final String motivo;
  final DateTime creado;
  EstadoTicket estado;

  String get etiqueta => 'A-${numero.toString().padLeft(3, '0')}';
}

/// Solicitud de matrícula guardada mientras el servicio no estaba disponible
/// (HU-11). Se procesa por orden de llegada cuando el servicio vuelve.
class SolicitudPendiente {
  SolicitudPendiente({
    required this.grupoId,
    required this.creada,
    required this.codigo,
  });

  final String grupoId;
  final DateTime creada;
  final String codigo;
}

class Notificacion {
  Notificacion({
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    this.leida = false,
  });

  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final TipoNotificacion tipo;
  bool leida;
}

/// Formatea una fecha como «dd/mm/aaaa hh:mm».
String formatoFechaHora(DateTime f) {
  String d2(int n) => n.toString().padLeft(2, '0');
  return '${d2(f.day)}/${d2(f.month)}/${f.year} ${d2(f.hour)}:${d2(f.minute)}';
}

String formatoHoraCorta(DateTime f) {
  String d2(int n) => n.toString().padLeft(2, '0');
  return '${d2(f.hour)}:${d2(f.minute)}';
}

/// Texto corto para un tiempo restante: «2 d 3 h», «5 h 10 min», «12 min».
String formatoFaltante(Duration d) {
  final minutos = d.inMinutes;
  if (minutos <= 0) return 'menos de 1 min';
  final dias = minutos ~/ 1440;
  final horas = (minutos % 1440) ~/ 60;
  final resto = minutos % 60;
  if (dias > 0) return '$dias d $horas h';
  if (horas > 0) return '$horas h $resto min';
  return '$resto min';
}
