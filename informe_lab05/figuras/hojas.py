# Hojas de calculo del informe: se dibujan como imagen con aspecto de Excel y
# tambien se exportan a MatrLab_Scrum.xlsx con los mismos datos.
import sys, html
from estilo import render, CSS

OUT = sys.argv[1]
XLSX = sys.argv[2] if len(sys.argv) > 2 else None
W = 1240
TABS = ['Product Backlog', 'Sprint 1', 'Sprint 2', 'Elementos de Scrum', 'Definición de terminado', 'Retrospectiva', 'Trazabilidad']

SHEET_CSS = """
.xl{width:1240px;border:1px solid #BDBDBD;background:#fff;font-family:Carlito,sans-serif;font-size:21px;color:#222}
.xl .tb{background:#F3F3F3;border-bottom:1px solid #D0D0D0;padding:7px 14px;font-size:18px;color:#444;display:flex;align-items:center;gap:10px}
.xl .ico{width:18px;height:18px;background:#8C1D2F;border-radius:3px;display:inline-block}
.xl table{border-collapse:collapse;width:100%;table-layout:fixed}
.xl td,.xl th{border:1px solid #D4D4D4;padding:6px 10px;vertical-align:middle;line-height:1.15;word-wrap:break-word}
.xl th.col{background:#EFEFEF;color:#555;font-weight:400;font-size:17px;text-align:center;padding:3px}
.xl td.rn{background:#EFEFEF;color:#555;font-size:17px;text-align:center;padding:3px;width:44px}
.xl td.t1{font-size:27px;font-weight:700;color:#8C1D2F;border-bottom:none}
.xl td.t2{font-size:20px;color:#444;border-top:none}
.xl td.hd{background:#8C1D2F;color:#fff;font-weight:700;border-color:#6E1624}
.xl td.c{text-align:center}
.xl td.b{font-weight:700}
.xl td.ft{background:#F7F7F7;font-weight:700}
.xl td.must{background:#F4C7C3;font-weight:700;text-align:center}.xl td.should{background:#FFE699;font-weight:700;text-align:center}
.xl td.could{background:#BDD7EE;font-weight:700;text-align:center}.xl td.wont{background:#D9D9D9;font-weight:700;text-align:center}
.xl td.ok{background:#C6E0B4;font-weight:700;text-align:center}.xl td.pend{background:#FFE699;font-weight:700;text-align:center}
.xl td.func{background:#E2EFDA;font-weight:700}.xl td.mej{background:#FCE4D6;font-weight:700}
.xl td.sec{background:#F4E4E7;font-weight:700;color:#6E1624}
.xl .tabs{background:#F3F3F3;border-top:1px solid #D0D0D0;padding:0 14px;display:flex;gap:4px;font-size:18px;overflow:hidden;white-space:nowrap}
.xl .tab{padding:6px 14px;color:#555;border-right:1px solid #D0D0D0}
.xl .tab.on{background:#fff;color:#8C1D2F;font-weight:700;border-bottom:3px solid #8C1D2F;margin-top:-1px}
"""

def letters(n):
    return [chr(65 + i) for i in range(n)]

def cell(c):
    cls = ''
    if isinstance(c, tuple):
        c, cls = c
    return c, cls

def sheet(libro, tab, titulo, sub, headers, rows, widths, footer=None, merged=None):
    """rows: lista de filas; cada celda es str o (str, clase). Una fila que es str se funde (seccion)."""
    n = len(headers)
    tot = sum(widths)
    cols = ''.join(f'<col style="width:{w}px">' for w in widths)
    h = '<div class="xl"><div class="tb"><span class="ico"></span> MatrLab_Scrum.xlsx &nbsp;·&nbsp; ' + tab + '</div>'
    h += f'<table><colgroup><col style="width:44px">{cols}</colgroup>'
    h += '<tr><th class="col"></th>' + ''.join(f'<th class="col">{l}</th>' for l in letters(n)) + '</tr>'
    r = 1
    def full(txt, cls):
        nonlocal r
        s = f'<tr><td class="rn">{r}</td><td colspan="{n}" class="{cls}">{txt}</td></tr>'
        r += 1
        return s
    h += full(html.escape(titulo), 't1')
    h += full(sub, 't2')
    h += '<tr><td class="rn">%d</td><td colspan="%d" style="height:10px;border-top:none"></td></tr>' % (r, n); r += 1
    h += f'<tr><td class="rn">{r}</td>' + ''.join(f'<td class="hd">{html.escape(x)}</td>' for x in headers) + '</tr>'; r += 1
    for row in rows:
        if isinstance(row, str):
            h += full(row, 'sec')
            continue
        h += f'<tr><td class="rn">{r}</td>'
        for c in row:
            t, cls = cell(c)
            h += f'<td class="{cls}">{t}</td>'
        h += '</tr>'; r += 1
    if footer:
        h += full(footer, 'ft')
    h += '</table><div class="tabs">' + ''.join(f'<div class="tab{" on" if t == tab else ""}">{t}</div>' for t in TABS) + '</div></div>'
    return h

def wrap(inner):
    return (f'<html><head><meta charset="utf-8"><style>{CSS}{SHEET_CSS}</style></head><body>'
            f'<div id="fig" style="width:{W}px;background:#fff">{inner}</div></body></html>')

E = lambda s: html.escape(s)
libro = {}

# ---------------- Product Backlog
pb_rows = [
    ['HU-08', 'Como estudiante, quiero ver cuándo es el turno de matrícula de mi ciclo y que el sistema respete ese turno, para no competir con todos a la vez.', ('Must', 'must'), ('5', 'c'), 'RF8', ('1', 'c'), ('Construida', 'ok')],
    ['HU-12', 'Como estudiante, quiero que la aplicación me diga por qué no puedo matricularme en un grupo y qué hacer, para no depender de preguntar en persona.', ('Must', 'must'), ('3', 'c'), 'RF12', ('1', 'c'), ('Construida', 'ok')],
    ['HU-09', 'Como estudiante, quiero pedir un número de atención virtual, para recibir ayuda sin hacer fila.', ('Must', 'must'), ('5', 'c'), 'RF9', ('1', 'c'), ('Construida', 'ok')],
    ['HU-11', 'Como estudiante, quiero que mi solicitud se guarde si el servicio se cae, para no perder mi lugar.', ('Must', 'must'), ('8', 'c'), 'RF11, RNF4', ('2', 'c'), ('Construida', 'ok')],
    ['HU-10', 'Como estudiante, quiero un comprobante con código, para demostrar que quedé matriculado.', ('Should', 'should'), ('2', 'c'), 'RF10', ('2', 'c'), ('Construida', 'ok')],
    ['HU-13', 'Como estudiante con texto ampliado, quiero que las pantallas nuevas se lean sin desbordes, para usar la aplicación en mi celular.', ('Should', 'should'), ('3', 'c'), 'RNF1, RNF2', ('2', 'c'), ('Construida', 'ok')],
    ['HU-14', 'Como estudiante, quiero que la aplicación recuerde mi sesión y mis solicitudes al cerrarla.', ('Could', 'could'), ('5', 'c'), 'futuro', ('—', 'c'), ('Backlog', 'wont')],
    ['HU-15', 'Como estudiante, quiero recibir avisos en el celular cuando se acerque mi turno.', ('Won\'t (por ahora)', 'wont'), ('8', 'c'), 'futuro', ('—', 'c'), ('Backlog', 'wont')],
]
pb_head = ['ID', 'Historia de usuario', 'Prioridad MoSCoW', 'Puntos', 'Requisito', 'Sprint', 'Estado']
pb_w = [78, 520, 130, 80, 140, 80, 132]
libro['f5_hoja_backlog'] = sheet('', 'Product Backlog', 'PRODUCT BACKLOG · MatrLab 2.0',
    'Meta de producto: asegurar el cupo de laboratorio desde cualquier lugar, dentro del turno propio, con ayuda sin fila y sin perder el lugar si el servicio falla.',
    pb_head, pb_rows, pb_w, 'Total comprometido en los dos sprints: 26 puntos (HU-14 y HU-15 quedan fuera). Estimación en puntos: criterio del autor.')

# ---------------- Sprint 1 / 2
def estado(): return ('Construida', 'ok')
s1 = [
    ['S1-01', ('HU-08', 'c'), 'Modelo de turno con estados (programado, en curso, finalizado)', 'models.dart', estado()],
    ['S1-02', ('HU-08', 'c'), 'Cuatro turnos de demostración y reloj inyectable', 'datos_demo.dart, estado.dart', estado()],
    ['S1-03', ('HU-08', 'c'), 'Regla que bloquea la matrícula fuera de turno', 'estado.dart', estado()],
    ['S1-04', ('HU-08', 'c'), 'Selector de ciclo en el inicio de sesión', 'login_screen.dart', estado()],
    ['S1-05', ('HU-08', 'c'), 'Aviso de turno en Cursos; lista de turnos en Ayuda y Operación', 'turno_widgets.dart, ayuda_screen.dart', estado()],
    ['S1-06', ('HU-12', 'c'), 'Función que calcula el motivo del bloqueo', 'estado.dart', estado()],
    ['S1-07', ('HU-12', 'c'), 'Estados del botón del grupo con aviso del motivo', 'grupo_detalle_screen.dart', estado()],
    ['S1-08', ('HU-12', 'c'), 'Preguntas frecuentes en la pestaña Ayuda', 'ayuda_screen.dart', estado()],
    ['S1-09', ('HU-09', 'c'), 'Modelo de número de atención', 'models.dart', estado()],
    ['S1-10', ('HU-09', 'c'), 'Solicitar, cancelar y atender en el estado', 'estado.dart', estado()],
    ['S1-11', ('HU-09', 'c'), 'Tarjeta con posición y espera; diálogo de motivos', 'ayuda_screen.dart', estado()],
    ['S1-12', ('HU-09', 'c'), 'Cola del administrador y avisos en Alertas', 'operacion_screen.dart, alertas_screen.dart', estado()],
]
hd = ['Tarea', 'Historia', 'Descripción de la tarea', 'Archivo principal', 'Estado']
wd = [88, 90, 470, 400, 142]
libro['f5_hoja_sprint1'] = sheet('', 'Sprint 1', 'SPRINT BACKLOG · SPRINT 1',
    'Meta: el estudiante sabe cuándo le toca matricularse, entiende por qué algo está bloqueado y puede pedir atención sin fila. Capacidad: 13 puntos.',
    hd, s1, wd, 'Comprometido: 13 puntos (HU-08: 5 · HU-12: 3 · HU-09: 5). Resultado de las pruebas: pendiente de ejecución.')
s2 = [
    ['S2-01', ('HU-11', 'c'), 'Interruptor de caída del servicio en Operación', 'operacion_screen.dart', estado()],
    ['S2-02', ('HU-11', 'c'), 'Banner de servicio no disponible en todas las pestañas', 'turno_widgets.dart, shell_screen.dart', estado()],
    ['S2-03', ('HU-11', 'c'), 'Solicitud pendiente con código, sin consumir cupo', 'estado.dart', estado()],
    ['S2-04', ('HU-11', 'c'), 'Procesamiento por orden de llegada con motivo de rechazo', 'estado.dart', estado()],
    ['S2-05', ('HU-11', 'c'), 'Pendientes en Mi horario y botón «Guardar solicitud»', 'horario_screen.dart, grupo_detalle_screen.dart', estado()],
    ['S2-06', ('HU-10', 'c'), 'Código de comprobante en cada matrícula', 'models.dart, estado.dart', estado()],
    ['S2-07', ('HU-10', 'c'), 'Fila «Comprobante» y botón para copiarlo', 'confirmacion_screen.dart', estado()],
    ['S2-08', ('HU-13', 'c'), 'Etiqueta semántica del número de atención', 'ayuda_screen.dart', estado()],
    ['S2-09', ('HU-13', 'c'), 'Pruebas de interfaz con texto al 150 %', 'lab05_widget_test.dart', estado()],
    ['S2-10', ('HU-13', 'c'), 'Corrección del contraste del verde (WCAG AA)', 'comunes.dart, turno_widgets.dart', estado()],
]
libro['f5_hoja_sprint2'] = sheet('', 'Sprint 2', 'SPRINT BACKLOG · SPRINT 2',
    'Meta: la matrícula no se pierde si el servicio cae, queda con un comprobante verificable y las pantallas nuevas se leen con texto ampliado. Capacidad: 13 puntos.',
    hd, s2, wd, 'Comprometido: 13 puntos (HU-11: 8 · HU-10: 2 · HU-13: 3). Resultado de las pruebas: pendiente de ejecución.')

# ---------------- Elementos de Scrum
el = [
    'Roles',
    [('Product Owner', 'b'), 'Lo asumo yo, apoyado en la evidencia pública y en la guía del laboratorio (cumple la función de cliente). El docente valida en la entrega.'],
    [('Developers y Scrum Master', 'b'), 'También los asumo. Limitación: no hay revisión de pares; se compensa con pruebas automáticas, trazabilidad y criterios de aceptación escritos antes de programar.'],
    'Artefactos',
    [('Product Backlog', 'b'), 'Ocho historias con prioridad MoSCoW y puntos (hoja «Product Backlog»).'],
    [('Sprint Backlog', 'b'), 'Tareas por historia (hojas «Sprint 1» y «Sprint 2»).'],
    [('Incremento', 'b'), 'Una versión de la aplicación que se ejecuta y se prueba al cierre de cada sprint.'],
    'Eventos',
    [('Planificación del sprint', 'b'), 'Elegí las historias por prioridad y dependencia; fijé una meta y una capacidad de 13 puntos por sprint.'],
    [('Scrum diario', 'b'), 'Se reemplaza por el registro de cambios del repositorio (anexo B).'],
    [('Revisión del sprint', 'b'), 'Comparar capturas y resultados de pruebas con los criterios de aceptación (sección 9).'],
    [('Retrospectiva', 'b'), 'Hoja «Retrospectiva».'],
]
libro['f5_hoja_scrum'] = sheet('', 'Elementos de Scrum', 'ELEMENTOS DE SCRUM ADAPTADOS A UN EQUIPO DE UNA PERSONA',
    'Referencia: Guía de Scrum 2020. Se mantiene la lógica del marco y se declaran las adaptaciones.',
    ['Elemento', 'Cómo se aplicó en este laboratorio'], el, [330, 866])

# ---------------- DoD
dod = [
    [('1', 'c'), 'Cumple todos sus criterios de aceptación con pruebas automáticas definidas', 'Pruebas escritas; resultado pendiente', ('Pendiente', 'pend')],
    [('2', 'c'), 'flutter analyze no reporta errores', 'Pendiente de ejecución', ('Pendiente', 'pend')],
    [('3', 'c'), 'Se ve bien a 360 dp (teléfono) y a 900 dp (tableta)', 'Capturas c30 y c16/c17 por generar', ('Pendiente', 'pend')],
    [('4', 'c'), 'No se desborda con el texto del sistema al 150 %', 'Pruebas escritas; pendiente', ('Pendiente', 'pend')],
    [('5', 'c'), 'El texto de las etiquetas cumple contraste 4,5:1', 'Cálculo con la fórmula de WCAG 2.2', ('Cumple', 'ok')],
    [('6', 'c'), 'No usa paquetes externos (solo el SDK de Flutter)', 'Revisión de pubspec.yaml', ('Cumple', 'ok')],
    [('7', 'c'), 'Tiene al menos una captura en el recorrido del informe', 'Capturas definidas; por generar', ('Pendiente', 'pend')],
    [('8', 'c'), 'Está registrada en el repositorio con un mensaje claro', 'Anexo B (git log)', ('Cumple', 'ok')],
]
libro['f5_hoja_dod'] = sheet('', 'Definición de terminado', 'DEFINICIÓN DE TERMINADO (DoD)',
    'Una historia está terminada cuando cumple todas las condiciones. Se indica cuáles ya se verificaron y cuáles dependen de ejecutar el proyecto.',
    ['N.°', 'Condición', 'Verificación', 'Estado'], dod, [60, 600, 380, 156],
    'Resumen: 3 condiciones cumplidas y 5 pendientes de la ejecución en el equipo del autor.')

# ---------------- Retrospectiva
retro = [
    'Qué funcionó',
    [('Partir de la evidencia', 'func'), 'Tres de las cuatro funciones principales (turnos escalonados, protocolo de contingencia y mejor orientación) coinciden con medidas que el director de Servicios Académicos nombró como pendientes.'],
    [('Reloj inyectable', 'func'), 'Con un reloj fijo, las pruebas y las capturas son repetibles y textos como «faltan 2 d 0 h» no cambian.'],
    [('Revisar el propio diseño', 'func'), 'Calcular el contraste mostró que el verde heredado del Laboratorio 4 no cumplía WCAG AA; se corrigió.'],
    'Qué mejorar y acción',
    [('Un commit por historia', 'mej'), 'El registro quedó con un solo commit de código para los dos sprints. Acción: un commit por historia terminada en los próximos laboratorios.'],
    [('Verificar más temprano', 'mej'), 'Ejecutar flutter analyze y flutter test al final de cada sprint, no solo al cierre (ejecutar.ps1 lo hace en un paso).'],
    [('Datos propios de usuarios', 'mej'), 'La evidencia es documental. Con más tiempo, una encuesta breve a compañeros validaría los hallazgos H1 a H8 y ajustaría el backlog.'],
    [('Trabajo en solitario', 'mej'), 'Sin revisión de pares, un error de criterio solo lo detectan las pruebas. Acción: pedir una revisión corta del informe y del código a un compañero.'],
]
libro['f5_hoja_retro'] = sheet('', 'Retrospectiva', 'RETROSPECTIVA PRELIMINAR · MatrLab 2.0',
    'Lo que se sabe antes de ejecutar las pruebas; se completará con los resultados de la sección 9.',
    ['Aspecto', 'Observación o acción'], retro, [330, 866])

# ---------------- Trazabilidad
tz = [
    [('C1, C2', 'b'), 'E6, E7', ('RF8', 'c'), ('HU-08', 'c'), 'Login (ciclo), Cursos, Ayuda, Operación', 'lab05_estado_test, lab05_widget_test', 'c18, c20'],
    [('C6', 'b'), 'E7', ('RF9', 'c'), ('HU-09', 'c'), 'Ayuda, Operación', 'lab05_estado_test, lab05_widget_test', 'c21, c24'],
    [('C4', 'b'), 'E4, E5, E7', ('RF10', 'c'), ('HU-10', 'c'), 'Confirmación', 'lab05_estado_test, lab05_widget_test', 'c08'],
    [('C3, C4', 'b'), 'E4, E5, E7', ('RF11', 'c'), ('HU-11', 'c'), 'Banner, Grupo, Hoja de confirmación, Horario, Alertas, Operación', 'lab05_estado_test, lab05_widget_test', 'c23, c25 a c28'],
    [('C5', 'b'), 'E6, E7', ('RF12', 'c'), ('HU-12', 'c'), 'Grupo, Ayuda (preguntas frecuentes)', 'lab05_estado_test, lab05_widget_test', 'c19, c22'],
    [('C1 a C7', 'b'), 'E8', ('RNF2', 'c'), ('HU-13', 'c'), 'Ayuda, Operación, Grupo', 'lab05_widget_test (texto grande)', 'c29'],
    [('C7', 'b'), 'Lab. 1 y 4 (hipótesis)', ('RF1 a RF7', 'c'), ('HU-01 a 07', 'c'), 'Login, Cursos, Grupo, Horario, Alertas, Panel', 'matrlab_state_test, flujo_widget_test', 'c01 a c17'],
]
libro['f5_hoja_traza'] = sheet('', 'Trazabilidad', 'MATRIZ DE TRAZABILIDAD · causa → requisito → historia → pantalla → prueba → captura',
    'Cada fila permite ir de una causa del árbol de problemas a su evidencia, su requisito, su pantalla y su prueba.',
    ['Causa', 'Evidencia', 'Requisito', 'Historia', 'Pantallas', 'Pruebas', 'Captura'], tz, [92, 112, 112, 112, 330, 292, 146])

render({k: wrap(v) for k, v in libro.items()}, OUT)

# ---------------- exportar a Excel
if XLSX:
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
    wb = Workbook(); wb.remove(wb.active)
    thin = Side(style='thin', color='BFBFBF')
    def plain(c):
        c = c[0] if isinstance(c, tuple) else c
        return html.unescape(c.replace('<br>', '\n'))
    datos = [
        ('Product Backlog', 'PRODUCT BACKLOG · MatrLab 2.0', pb_head, pb_rows, pb_w),
        ('Sprint 1', 'SPRINT BACKLOG · SPRINT 1 (capacidad 13 puntos)', hd, s1, wd),
        ('Sprint 2', 'SPRINT BACKLOG · SPRINT 2 (capacidad 13 puntos)', hd, s2, wd),
        ('Elementos de Scrum', 'ELEMENTOS DE SCRUM ADAPTADOS A UN EQUIPO DE UNA PERSONA', ['Elemento', 'Cómo se aplicó'], el, [330, 866]),
        ('Definición de terminado', 'DEFINICIÓN DE TERMINADO (DoD)', ['N.°', 'Condición', 'Verificación', 'Estado'], dod, [60, 600, 380, 156]),
        ('Retrospectiva', 'RETROSPECTIVA PRELIMINAR', ['Aspecto', 'Observación o acción'], retro, [330, 866]),
        ('Trazabilidad', 'MATRIZ DE TRAZABILIDAD', ['Causa', 'Evidencia', 'Requisito', 'Historia', 'Pantallas', 'Pruebas', 'Captura'], tz, [92, 112, 112, 112, 330, 292, 146]),
    ]
    for nombre, titulo, head, rows, widths in datos:
        ws = wb.create_sheet(nombre[:31])
        ws['A1'] = titulo; ws['A1'].font = Font(bold=True, size=14, color='8C1D2F')
        for j, t in enumerate(head, 1):
            c = ws.cell(row=3, column=j, value=t)
            c.font = Font(bold=True, color='FFFFFF'); c.fill = PatternFill('solid', fgColor='8C1D2F')
            c.alignment = Alignment(wrap_text=True, vertical='center')
        r = 4
        for row in rows:
            if isinstance(row, str):
                c = ws.cell(row=r, column=1, value=row); c.font = Font(bold=True, color='6E1624')
                for j in range(1, len(head) + 1): ws.cell(row=r, column=j).fill = PatternFill('solid', fgColor='F4E4E7')
            else:
                for j, c0 in enumerate(row, 1):
                    c = ws.cell(row=r, column=j, value=plain(c0))
                    c.alignment = Alignment(wrap_text=True, vertical='top')
                    c.border = Border(left=thin, right=thin, top=thin, bottom=thin)
            r += 1
        for j, w in enumerate(widths, 1):
            ws.column_dimensions[chr(64 + j)].width = max(8, w / 7.2)
    ws = wb['Product Backlog']
    ws.cell(row=13, column=3, value='Total'); ws.cell(row=13, column=4, value='=SUM(D4:D11)')
    wb.save(XLSX)
