// Pruebas de las reglas nuevas del Laboratorio 05: turnos escalonados (HU-08),
// número de atención virtual (HU-09), comprobante (HU-10), contingencia
// (HU-11) y explicación del bloqueo (HU-12).
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/estado.dart';
import 'package:matrlab/models.dart';

/// Hora fija para que los resultados no dependan del reloj del equipo.
final DateTime _base = DateTime(2026, 11, 9, 8, 0);

MatrLabState _estudiante({Reloj? reloj, int ciclo = 10}) {
  final e = MatrLabState(reloj: reloj ?? () => _base);
  e.iniciarSesion('20241234', Rol.estudiante, ciclo: ciclo);
  return e;
}

void main() {
  group('HU-08 turnos escalonados', () {
    test('todos los ciclos del 1 al 10 tienen un turno', () {
      for (var c = 1; c <= 10; c++) {
        expect(_estudiante(ciclo: c).turnoDelEstudiante, isNotNull,
            reason: 'ciclo $c');
      }
    });

    test('el ciclo 10 está abierto y el ciclo 5 aún no', () {
      expect(_estudiante(ciclo: 10).turnoAbierto, isTrue);
      expect(_estudiante(ciclo: 5).turnoAbierto, isFalse);
    });

    test('fuera de turno no se consume cupo ni se registra matrícula', () {
      final e = _estudiante(ciclo: 5);
      final antes = e.grupoPorId('PE-B').cuposOcupados;
      expect(e.matricular('PE-B'), ResultadoMatricula.fueraDeTurno);
      expect(e.grupoPorId('PE-B').cuposOcupados, antes);
      expect(e.matriculas, isEmpty);
    });

    test('al iniciar el turno el estudiante ya puede matricularse', () {
      var ahora = _base;
      final e = _estudiante(reloj: () => ahora, ciclo: 5); // Turno 3: +48 h
      ahora = _base.add(const Duration(hours: 47, minutes: 59));
      expect(e.matricular('PE-B'), ResultadoMatricula.fueraDeTurno);
      ahora = _base.add(const Duration(hours: 48));
      expect(e.matricular('PE-B'), ResultadoMatricula.ok);
    });

    test('el estado de cada turno depende de la hora', () {
      final e = _estudiante();
      expect(e.turnos[0].estadoEn(_base), 'En curso');
      expect(e.turnos[1].estadoEn(_base), 'Programado');
      expect(e.turnos[0].estadoEn(_base.add(const Duration(hours: 25))),
          'Finalizado');
    });

    test('el administrador no está sujeto a turnos', () {
      final e = MatrLabState(reloj: () => _base);
      e.iniciarSesion('admin', Rol.administrador);
      expect(e.turnoAbierto, isTrue);
    });
  });

  group('HU-12 explicación del bloqueo', () {
    test('fuera de turno dice cuál es el turno y cuánto falta', () {
      final e = _estudiante(ciclo: 5);
      final motivo = e.motivoBloqueo(e.grupoPorId('PE-B'));
      expect(motivo, isNotNull);
      expect(motivo, contains('Turno 3'));
      expect(motivo, contains('faltan 2 d 0 h'));
    });

    test('sin obstáculos no hay motivo de bloqueo', () {
      final e = _estudiante();
      expect(e.motivoBloqueo(e.grupoPorId('PE-B')), isNull);
    });

    test('el cruce de horario se explica con el curso en conflicto', () {
      final e = _estudiante();
      e.matricular('PE-A');
      expect(e.motivoBloqueo(e.grupoPorId('RC-A')), contains('Se cruza'));
    });

    test('un segundo grupo del mismo curso se explica', () {
      final e = _estudiante();
      e.matricular('PE-A');
      expect(e.motivoBloqueo(e.grupoPorId('PE-B')),
          contains('Ya estás matriculado'));
    });
  });

  group('HU-10 comprobante', () {
    test('cada matrícula recibe un código único', () {
      final e = _estudiante();
      e.matricular('PE-B');
      e.matricular('SI-B');
      final a = e.matriculas[0].codigo;
      final b = e.matriculas[1].codigo;
      expect(a, startsWith('MLB-2026B-'));
      expect(b, startsWith('MLB-2026B-'));
      expect(a, isNot(b));
    });
  });

  group('HU-11 modo contingencia', () {
    test('sin servicio la solicitud queda pendiente y no consume cupo', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      final antes = e.grupoPorId('PE-B').cuposOcupados;
      expect(e.matricular('PE-B'), ResultadoMatricula.pendiente);
      expect(e.pendientes, hasLength(1));
      expect(e.pendientes.first.codigo, startsWith('SOL-2026B-'));
      expect(e.grupoPorId('PE-B').cuposOcupados, antes);
      expect(e.estaMatriculado('PE-B'), isFalse);
    });

    test('no admite dos solicitudes para el mismo curso', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      e.matricular('PE-B');
      expect(e.matricular('PE-B'), ResultadoMatricula.yaPendiente);
      expect(e.matricular('PE-A'), ResultadoMatricula.yaPendiente);
      expect(e.pendientes, hasLength(1));
    });

    test('al restablecerse se confirma la solicitud y se avisa', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      e.matricular('PE-B');
      e.cambiarServicio(disponible: true);
      expect(e.estaMatriculado('PE-B'), isTrue);
      expect(e.pendientes, isEmpty);
      expect(e.notificaciones.any((n) => n.titulo == 'Servicio restablecido'),
          isTrue);
    });

    test('se procesan por orden de llegada y se rechaza la que se cruza', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      // PE-A y RC-A son martes 14:00-16:00: ambas pasan las reglas locales.
      expect(e.matricular('PE-A'), ResultadoMatricula.pendiente);
      expect(e.matricular('RC-A'), ResultadoMatricula.pendiente);
      e.cambiarServicio(disponible: true);
      expect(e.estaMatriculado('PE-A'), isTrue);
      expect(e.estaMatriculado('RC-A'), isFalse);
      expect(
          e.notificaciones.any((n) =>
              n.titulo == 'Solicitud no confirmada' &&
              n.mensaje.contains('cruza')),
          isTrue);
    });

    test('si el grupo se llenó durante la caída, se rechaza con motivo', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      expect(e.matricular('RC-B'), ResultadoMatricula.pendiente); // 21 de 22
      final g = e.grupoPorId('RC-B');
      g.cuposOcupados = g.cuposTotales; // otra persona tomó el último cupo
      e.cambiarServicio(disponible: true);
      expect(e.estaMatriculado('RC-B'), isFalse);
      expect(
          e.notificaciones.any((n) =>
              n.titulo == 'Solicitud no confirmada' &&
              n.mensaje.contains('se llenó')),
          isTrue);
    });

    test('se puede cancelar una solicitud pendiente', () {
      final e = _estudiante();
      e.cambiarServicio(disponible: false);
      e.matricular('PE-B');
      e.cancelarSolicitud('PE-B');
      expect(e.pendientes, isEmpty);
      expect(e.tienePendiente('PE-B'), isFalse);
    });

    test('repetir el mismo cambio de servicio no duplica avisos', () {
      final e = _estudiante();
      final antes = e.notificaciones.length;
      e.cambiarServicio(disponible: false);
      e.cambiarServicio(disponible: false);
      expect(e.notificaciones.length, antes + 1);
    });
  });

  group('HU-09 número de atención virtual', () {
    test('la cola de demostración tiene cuatro personas', () {
      expect(_estudiante().enEspera, 4);
    });

    test('el estudiante recibe A-021 con posición y espera estimada', () {
      final e = _estudiante();
      final t = e.solicitarTicket('Mi matrícula falló o quedó incompleta');
      expect(t, isNotNull);
      expect(t!.etiqueta, 'A-021');
      expect(e.posicionDe(t), 5);
      expect(e.minutosEstimados(t), 4 * MatrLabState.minutosPorAtencion);
      expect(e.ticketActivo, same(t));
      expect(e.notificaciones.first.tipo, TipoNotificacion.ticket);
    });

    test('solo se permite un número activo por estudiante', () {
      final e = _estudiante();
      e.solicitarTicket('Otro motivo');
      expect(e.solicitarTicket('Otro motivo'), isNull);
    });

    test('el administrador no puede pedir número', () {
      final e = MatrLabState(reloj: () => _base);
      e.iniciarSesion('admin', Rol.administrador);
      expect(e.solicitarTicket('Otro motivo'), isNull);
    });

    test('al atender a los de adelante se avisa al estudiante', () {
      final e = _estudiante();
      final t = e.solicitarTicket('Otro motivo')!;
      for (var i = 0; i < 4; i++) {
        e.atenderSiguiente();
      }
      expect(e.posicionDe(t), 1);
      expect(e.notificaciones.first.tipo, TipoNotificacion.ticket);
      expect(e.notificaciones.first.titulo, 'Es tu turno: A-021');
      e.atenderSiguiente();
      expect(t.estado, EstadoTicket.atendido);
      expect(e.ticketActivo, isNull);
      expect(e.enEspera, 0);
    });

    test('cancelar el número permite pedir uno nuevo', () {
      final e = _estudiante();
      e.solicitarTicket('Otro motivo');
      e.cancelarTicket();
      expect(e.ticketActivo, isNull);
      expect(e.solicitarTicket('Otro motivo')!.etiqueta, 'A-022');
    });

    test('sin cola de demostración la numeración parte de A-001', () {
      final e = MatrLabState(reloj: () => _base, conColaDemo: false);
      e.iniciarSesion('20241234', Rol.estudiante);
      expect(e.enEspera, 0);
      expect(e.atenderSiguiente(), isNull);
      expect(e.solicitarTicket('Otro motivo')!.etiqueta, 'A-001');
    });
  });

  group('formato de tiempo restante', () {
    test('muestra días, horas o minutos según el tamaño', () {
      expect(formatoFaltante(const Duration(days: 2, hours: 3)), '2 d 3 h');
      expect(formatoFaltante(const Duration(hours: 5, minutes: 10)),
          '5 h 10 min');
      expect(formatoFaltante(const Duration(minutes: 12)), '12 min');
      expect(formatoFaltante(Duration.zero), 'menos de 1 min');
    });
  });
}
