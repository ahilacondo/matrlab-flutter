// Pruebas de la lógica de negocio (sin interfaz): cupos, cruces de horario,
// lista de espera y panel de administración.
import 'package:flutter_test/flutter_test.dart';
import 'package:matrlab/estado.dart';
import 'package:matrlab/models.dart';

void main() {
  late MatrLabState e;

  setUp(() => e = MatrLabState());

  group('validación de credenciales', () {
    test('el código de estudiante exige 8 dígitos', () {
      expect(validarCodigo('20241234', Rol.estudiante), isNull);
      expect(validarCodigo('1234', Rol.estudiante), isNotNull);
      expect(validarCodigo('', Rol.estudiante), isNotNull);
      expect(validarCodigo('abcdefgh', Rol.estudiante), isNotNull);
    });

    test('el administrador exige al menos 4 caracteres', () {
      expect(validarCodigo('admin', Rol.administrador), isNull);
      expect(validarCodigo('ab', Rol.administrador), isNotNull);
    });

    test('la contraseña exige al menos 4 caracteres', () {
      expect(validarClave('abcd'), isNull);
      expect(validarClave('abc'), isNotNull);
    });
  });

  group('matrícula', () {
    test('matricularse reserva un cupo y registra la matrícula', () {
      final antes = e.grupoPorId('PE-B').cuposOcupados;
      expect(e.matricular('PE-B'), ResultadoMatricula.ok);
      expect(e.grupoPorId('PE-B').cuposOcupados, antes + 1);
      expect(e.estaMatriculado('PE-B'), isTrue);
      expect(e.notificaciones.first.tipo, TipoNotificacion.matricula);
    });

    test('no permite dos grupos del mismo curso', () {
      e.matricular('PE-A');
      expect(e.matricular('PE-B'), ResultadoMatricula.yaMatriculado);
    });

    test('detecta el cruce de horario entre cursos distintos', () {
      // PE-A y RC-A son martes 14:00-16:00.
      expect(e.matricular('PE-A'), ResultadoMatricula.ok);
      expect(e.conflictoCon(e.grupoPorId('RC-A'))?.id, 'PE-A');
      expect(e.matricular('RC-A'), ResultadoMatricula.cruceHorario);
      expect(e.estaMatriculado('RC-A'), isFalse);
    });

    test('rechaza un grupo sin cupos', () {
      expect(e.grupoPorId('BD2-B').cuposLibres, 0);
      expect(e.matricular('BD2-B'), ResultadoMatricula.sinCupo);
    });

    test('cancelar devuelve el cupo', () {
      e.matricular('PE-B');
      final ocupados = e.grupoPorId('PE-B').cuposOcupados;
      e.cancelarMatricula('PE-B');
      expect(e.grupoPorId('PE-B').cuposOcupados, ocupados - 1);
      expect(e.estaMatriculado('PE-B'), isFalse);
    });

    test('el último cupo solo lo obtiene una persona', () {
      final g = e.grupoPorId('RC-B'); // 21 de 22
      expect(g.cuposLibres, 1);
      expect(e.matricular('RC-B'), ResultadoMatricula.ok);
      expect(g.estado, EstadoCupo.lleno);
      e.cancelarMatricula('RC-B');
      g.cuposOcupados = g.cuposTotales; // simula que otro tomó el cupo
      expect(e.matricular('RC-B'), ResultadoMatricula.sinCupo);
    });
  });

  group('lista de espera y administración', () {
    test('unirse a la lista solo aplica a grupos llenos', () {
      e.unirseAListaEspera('PE-B'); // tiene cupos: se ignora
      expect(e.enListaEspera('PE-B'), isFalse);
      e.unirseAListaEspera('BD2-B');
      expect(e.enListaEspera('BD2-B'), isTrue);
    });

    test('al agregar un cupo se notifica a quien esperaba', () {
      e.unirseAListaEspera('BD2-B');
      e.ajustarCupos('BD2-B', 1);
      expect(e.enListaEspera('BD2-B'), isFalse);
      expect(e.notificaciones.first.tipo, TipoNotificacion.cupoLiberado);
      expect(e.grupoPorId('BD2-B').cuposLibres, 1);
    });

    test('no se pueden quitar más cupos de los ocupados', () {
      final g = e.grupoPorId('BD2-B');
      e.ajustarCupos('BD2-B', -5);
      expect(g.cuposTotales, g.cuposOcupados);
    });
  });

  group('estados y métricas', () {
    test('clasifica la ocupación por umbrales', () {
      expect(e.grupoPorId('PE-B').estado, EstadoCupo.disponible); // 45 %
      expect(e.grupoPorId('PE-A').estado, EstadoCupo.casiLleno); // 85 %
      expect(e.grupoPorId('BD2-B').estado, EstadoCupo.lleno); // 100 %
    });

    test('el ranking pone primero al grupo más saturado', () {
      expect(e.gruposPorOcupacion().first.id, 'BD2-B');
    });

    test('cupos totales = ocupados + libres', () {
      expect(e.cuposTotales, e.cuposOcupados + e.cuposLibres);
    });

    test('las alertas sin leer se cuentan y se pueden marcar', () {
      expect(e.noLeidas, 2);
      e.marcarLeidas();
      expect(e.noLeidas, 0);
    });
  });

  group('horario', () {
    test('franjas del mismo día se cruzan solo si se solapan', () {
      const a = Horario(2, 8, 10);
      expect(a.seCruzaCon(const Horario(2, 9, 11)), isTrue);
      expect(a.seCruzaCon(const Horario(2, 10, 12)), isFalse);
      expect(a.seCruzaCon(const Horario(3, 8, 10)), isFalse);
    });
  });
}
