import 'package:flutter/material.dart';

/// Rol con el que se inicia sesión.
enum Rol { estudiante, administrador }

/// Nivel de ocupación de un grupo de laboratorio.
enum EstadoCupo { disponible, casiLleno, lleno }

/// Tipos de notificación que muestra la pestaña «Alertas».
enum TipoNotificacion { matricula, cupoLiberado, listaEspera, aviso }

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
  Matricula({required this.grupoId, required this.fecha});

  final String grupoId;
  final DateTime fecha;
  final String estado = 'Confirmada';
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
