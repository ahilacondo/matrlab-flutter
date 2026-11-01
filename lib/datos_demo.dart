import 'package:flutter/material.dart';

import 'models.dart';

/// Datos de demostración. Los códigos IS-742, IS-735 e IS-624 y sus grupos
/// provienen del caso del Laboratorio 2 (MatrLab en Adalo); los otros dos
/// cursos son ficticios y solo sirven para probar el diseño.
List<Curso> datosCursos() => const [
      Curso(
        codigo: 'IS-742',
        sigla: 'PE',
        nombre: 'Plataformas Emergentes',
        docente: 'MSc. Norman Harvey Arce',
        descripcion:
            'Laboratorio de desarrollo de aplicaciones móviles y multiplataforma.',
        icono: Icons.devices_other,
      ),
      Curso(
        codigo: 'IS-735',
        sigla: 'SI',
        nombre: 'Seguridad Informática',
        docente: 'Por designar',
        descripcion:
            'Prácticas de seguridad en la web, criptografía y análisis de vulnerabilidades.',
        icono: Icons.shield_outlined,
      ),
      Curso(
        codigo: 'IS-624',
        sigla: 'BD2',
        nombre: 'Base de Datos II',
        docente: 'Por designar',
        descripcion:
            'Diseño avanzado, consultas, transacciones y optimización en bases de datos.',
        icono: Icons.storage,
      ),
      Curso(
        codigo: 'IS-533',
        sigla: 'RC',
        nombre: 'Redes y Comunicación de Datos',
        docente: 'Por designar',
        descripcion:
            'Configuración de redes, enrutamiento y protocolos en laboratorio.',
        icono: Icons.lan_outlined,
      ),
      Curso(
        codigo: 'IS-641',
        sigla: 'IS',
        nombre: 'Ingeniería de Software',
        docente: 'Por designar',
        descripcion:
            'Requisitos, diseño, pruebas y gestión de proyectos de software.',
        icono: Icons.integration_instructions_outlined,
      ),
    ];

List<GrupoLab> datosGrupos() => [
      GrupoLab(
        id: 'PE-A',
        cursoCodigo: 'IS-742',
        nombre: 'Grupo A',
        horario: const Horario(2, 14, 16),
        aula: 'Lab. Redes 302',
        cuposTotales: 20,
        cuposOcupados: 17,
      ),
      GrupoLab(
        id: 'PE-B',
        cursoCodigo: 'IS-742',
        nombre: 'Grupo B',
        horario: const Horario(4, 10, 12),
        aula: 'Lab. Redes 302',
        cuposTotales: 20,
        cuposOcupados: 9,
      ),
      GrupoLab(
        id: 'SI-A',
        cursoCodigo: 'IS-735',
        nombre: 'Grupo A',
        horario: const Horario(1, 8, 10),
        aula: 'Lab. Cómputo 201',
        cuposTotales: 18,
        cuposOcupados: 15,
      ),
      GrupoLab(
        id: 'SI-B',
        cursoCodigo: 'IS-735',
        nombre: 'Grupo B',
        horario: const Horario(3, 16, 18),
        aula: 'Lab. Cómputo 201',
        cuposTotales: 18,
        cuposOcupados: 6,
      ),
      GrupoLab(
        id: 'BD2-A',
        cursoCodigo: 'IS-624',
        nombre: 'Grupo A',
        horario: const Horario(2, 8, 10),
        aula: 'Lab. Cómputo 105',
        cuposTotales: 25,
        cuposOcupados: 12,
      ),
      GrupoLab(
        id: 'BD2-B',
        cursoCodigo: 'IS-624',
        nombre: 'Grupo B',
        horario: const Horario(5, 14, 16),
        aula: 'Lab. Cómputo 105',
        cuposTotales: 25,
        cuposOcupados: 25,
      ),
      GrupoLab(
        id: 'RC-A',
        cursoCodigo: 'IS-533',
        nombre: 'Grupo A',
        horario: const Horario(2, 14, 16),
        aula: 'Lab. Redes 301',
        cuposTotales: 22,
        cuposOcupados: 10,
      ),
      GrupoLab(
        id: 'RC-B',
        cursoCodigo: 'IS-533',
        nombre: 'Grupo B',
        horario: const Horario(4, 14, 16),
        aula: 'Lab. Redes 301',
        cuposTotales: 22,
        cuposOcupados: 21,
      ),
      GrupoLab(
        id: 'IS-A',
        cursoCodigo: 'IS-641',
        nombre: 'Grupo A',
        horario: const Horario(3, 8, 10),
        aula: 'Lab. Cómputo 202',
        cuposTotales: 24,
        cuposOcupados: 5,
      ),
    ];

List<Notificacion> avisosIniciales() {
  final ahora = DateTime.now();
  return [
    Notificacion(
      titulo: 'Matrícula de laboratorios abierta',
      mensaje: 'Ya puedes elegir tu grupo de laboratorio del semestre 2026B.',
      fecha: ahora,
      tipo: TipoNotificacion.aviso,
    ),
    Notificacion(
      titulo: 'Cupos casi agotados',
      mensaje: 'Plataformas Emergentes · Grupo A tiene solo 3 cupos libres.',
      fecha: ahora,
      tipo: TipoNotificacion.aviso,
    ),
  ];
}

/// Turnos de matrícula de demostración, escalonados cada 24 horas a partir de
/// [base] (el primero empieza en ese instante). La asignación de ciclos es un
/// escenario de prueba; no representa el reglamento de la universidad.
List<TurnoMatricula> datosTurnos(DateTime base) {
  DateTime tras(int horas) => base.add(Duration(hours: horas));
  return [
    TurnoMatricula(
      nombre: 'Turno 1',
      cicloMin: 9,
      cicloMax: 10,
      inicio: tras(0),
      fin: tras(24),
    ),
    TurnoMatricula(
      nombre: 'Turno 2',
      cicloMin: 7,
      cicloMax: 8,
      inicio: tras(24),
      fin: tras(48),
    ),
    TurnoMatricula(
      nombre: 'Turno 3',
      cicloMin: 5,
      cicloMax: 6,
      inicio: tras(48),
      fin: tras(72),
    ),
    TurnoMatricula(
      nombre: 'Turno 4',
      cicloMin: 1,
      cicloMax: 4,
      inicio: tras(72),
      fin: tras(96),
    ),
  ];
}

/// Código con el que se marcan los números de atención ficticios de la cola
/// de demostración (otras personas que ya esperan).
const String codigoTicketDemo = 'demo';

/// Cola de atención de demostración: cuatro personas esperando (A-017 a A-020).
List<TicketAtencion> ticketsDemo(DateTime ahora) => [
      for (var n = 17; n <= 20; n++)
        TicketAtencion(
          numero: n,
          codigoEstudiante: codigoTicketDemo,
          motivo: 'Matrícula incompleta',
          creado: ahora.subtract(Duration(minutes: (21 - n) * 4)),
        ),
    ];

/// Motivos que puede elegir el estudiante al pedir un número de atención.
const List<String> motivosTicket = [
  'Mi matrícula falló o quedó incompleta',
  'No puedo ingresar a mi cuenta',
  'Consulta sobre cruce de horarios',
  'Otro motivo',
];
