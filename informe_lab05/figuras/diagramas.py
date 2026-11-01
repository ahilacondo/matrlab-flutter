# Diagramas del informe: arbol de problemas, navegacion, contingencia y flujo Scrum.
import sys
from estilo import page, render

OUT = sys.argv[1]
W = 1240

def card(id, cls, x, y, w, h, html, extra=''):
    return f'<div class="card {cls}" id="{id}" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;{extra}">{html}</div>'

# ------------------------------------------------------------ arbol de problemas
def arbol():
    b = ''
    # bandas laterales
    def band(y, h, txt, color, fs=21):
        return (f'<div style="position:absolute;left:30px;top:{y}px;width:44px;height:{h}px;background:{color};border-radius:10px;'
                f'display:flex;align-items:center;justify-content:center"><div style="writing-mode:vertical-rl;transform:rotate(180deg);'
                f'color:#fff;font-weight:700;letter-spacing:2px;font-size:{fs}px">{txt}</div></div>')
    b += band(26, 130, 'EFECTOS', '#C77B1B')
    b += band(262, 110, 'PROBLEMA', '#8C1D2F', 17)
    b += band(470, 560, 'CAUSAS', '#A5535F')
    efectos = [('E1', 'Estudiantes pasan la noche a la intemperie'), ('E2', 'Pérdida de cupos en cursos clave'),
               ('E3', 'Matrículas y trámites paralizados por semanas'), ('E4', 'Desgaste y reclamos que se repiten cada semestre')]
    for i, (k, t) in enumerate(efectos):
        b += card(f'e{i}', 'orange', 98 + i * 280, 26, 262, 130, f'<div><span class="badge" style="background:#C77B1B">{k}</span></div><div style="margin-top:6px">{t}</div>')
    b += card('pc', 'guinda', 150, 262, 1000, 110,
              '<div style="text-align:center;font-size:27px"><b>Los estudiantes no logran asegurar su cupo de laboratorio de forma justa, segura y confiable durante la matrícula</b></div>')
    grupos = [
        ('Demanda y capacidad', [('C1', 'Demanda concentrada en los últimos días y capacidad limitada', 'Evidencia: E6, E7'),
                                 ('C2', 'Sin turnos escalonados de matrícula', 'Evidencia: E7')]),
        ('Continuidad del servicio', [('C3', 'Servidores antiguos y sin alta disponibilidad', 'Evidencia: E4, E7'),
                                      ('C4', 'Sin protocolo de contingencia ante una caída', 'Evidencia: E4, E5, E7')]),
        ('Atención e información', [('C5', 'Poca orientación sobre fechas, cursos y créditos', 'Evidencia: E6, E7'),
                                    ('C6', 'Atención asistida solo por fila presencial', 'Evidencia: E7'),
                                    ('C7', 'Cupos poco visibles, sin aviso ni validación de cruces', 'Hipótesis del autor')]),
    ]
    gw = 330
    for gi, (gt, cs) in enumerate(grupos):
        gx = 98 + gi * 358
        gh = 556 if len(cs) == 3 else 400
        b += (f'<div id="g{gi}" style="position:absolute;left:{gx}px;top:470px;width:{gw+10}px;height:{gh}px;border:2.5px dashed #B9808A;'
              f'border-radius:14px;background:#FBF1F3"></div>')
        b += f'<div style="position:absolute;left:{gx}px;top:480px;width:{gw+10}px;text-align:center;font-weight:700;color:#8C1D2F;font-size:25px">{gt}</div>'
        for ci, (k, t, ev) in enumerate(cs):
            y = 530 + ci * 168
            style = 'border-style:dashed;' if k == 'C7' else ''
            b += card(f'c{k}', 'pink', gx + 12, y, gw - 14, 154,
                      f'<div><span class="badge">{k}</span></div><div style="margin-top:6px">{t}</div><small>{ev}</small>', style)
    js = ''
    for i in range(4):
        js += f"link('pc','t','e{i}','b',{{fa:{0.12+0.25*i:.2f},mid:222}});"
    for gi in range(3):
        js += f"link('g{gi}','t','pc','b',{{fa:0.5,fb:{0.17+0.33*gi:.2f},mid:430}});"
    # leyenda
    b += ('<div style="position:absolute;left:98px;top:1050px;font-size:20px;color:#444;display:flex;gap:30px;align-items:center">'
          '<span><span style="display:inline-block;width:26px;height:16px;background:#F6DADF;border:2px solid #C9929A;border-radius:4px;vertical-align:middle"></span> Causa respaldada por la evidencia</span>'
          '<span><span style="display:inline-block;width:26px;height:16px;background:#F6DADF;border:2px dashed #C9929A;border-radius:4px;vertical-align:middle"></span> Causa planteada como hipótesis</span>'
          '<span><span style="display:inline-block;width:26px;height:16px;background:#FDE9D0;border:2px solid #E0A25A;border-radius:4px;vertical-align:middle"></span> Efecto</span></div>')
    return page(b, W, 1100, js)

# ------------------------------------------------------------ navegacion
def navegacion():
    b = ''
    def chip(txt, nuevo=False):
        st = 'background:#FFF3CD;border:2px solid #D9A400;' if nuevo else 'background:#fff;border:2px solid #8A8A8A;'
        tag = '<span class="nuevo">NUEVO</span>' if nuevo else ''
        return f'<span style="display:inline-block;{st}border-radius:9px;padding:5px 12px;margin:3px 0;font-size:22px">{txt}{tag}</span>'
    def row(y, h, tab, nuevo, desc, chain=None, x=0, w=0):
        t = chip(tab, nuevo)
        inner = f'<div style="font-weight:700;font-size:24px;color:#8C1D2F;margin-bottom:4px">{tab}{"<span class=nuevo>NUEVO</span>" if nuevo else ""}</div>'
        inner += f'<div style="font-size:21px;color:#333">{desc}</div>'
        if chain:
            inner += '<div style="margin-top:8px;font-size:18px">' + ' <span style="color:#777;font-size:24px">›</span> '.join(
                f'<span style="display:inline-block;background:#fff;border:2px solid #8A8A8A;border-radius:8px;padding:1px 7px;margin:2px 0;font-size:18px">{c}</span>' for c in chain) + '</div>'
        return card('r_' + tab.replace(' ', '_'), 'amber' if nuevo else 'gray', x, y, w, h, inner, 'align-items:flex-start;')
    b += card('login', 'pink', 440, 20, 360, 82,
              '<div style="text-align:center"><b>Inicio de sesión</b><small style="margin-top:2px">código · rol · ciclo del estudiante</small></div>')
    # paneles
    b += ('<div id="pe" style="position:absolute;left:30px;top:170px;width:740px;height:700px;border:2.5px solid #8C1D2F;border-radius:14px"></div>'
          '<div style="position:absolute;left:50px;top:158px;background:#fff;padding:0 12px;font-weight:700;color:#8C1D2F;font-size:26px">Estudiante</div>')
    b += ('<div id="pa" style="position:absolute;left:800px;top:170px;width:410px;height:700px;border:2.5px solid #8C1D2F;border-radius:14px"></div>'
          '<div style="position:absolute;left:820px;top:158px;background:#fff;padding:0 12px;font-weight:700;color:#8C1D2F;font-size:26px">Administrador</div>')
    b += row(200, 232, 'Cursos', False, 'Lista con búsqueda, filtros y aviso del turno del estudiante. Desde aquí se recorre el flujo de matrícula:',
             ['Detalle de curso', 'Detalle de grupo', 'Hoja de confirmación', 'Confirmación'], 52, 696)
    b += row(446, 112, 'Mi horario', False, 'Matrículas confirmadas, franjas semanales y solicitudes pendientes.', None, 52, 696)
    b += row(572, 112, 'Alertas', False, 'Avisos de matrícula, cupo liberado, número de atención y estado del servicio.', None, 52, 696)
    b += row(698, 150, 'Ayuda', True, 'Turnos de matrícula, estado del servicio, número de atención virtual y preguntas frecuentes.', None, 52, 696)
    b += row(200, 232, 'Cursos', False, 'Misma lista de cursos, con la ocupación de cada grupo.', None, 822, 366)
    b = b.replace('id="r_Cursos"', 'id="r_Cursos"', 1)
    b += row(446, 190, 'Panel', False, 'Cupos totales y ocupados, ocupación global, ranking de grupos y ajuste de cupos.', None, 822, 366)
    b += row(650, 198, 'Operación', True, 'Simular caída del servicio, ver los turnos y atender la cola de números.', None, 822, 366)
    js = "link('login','b','pe','t',{fa:0.25,fb:0.6,mid:140});link('login','b','pa','t',{fa:0.75,fb:0.75,mid:140});"
    # ids duplicados de Cursos: el segundo se renombra
    b = b.replace('id="r_Cursos" style="left:822', 'id="r_CursosA" style="left:822')
    return page(b, W, 900, js)

# ------------------------------------------------------------ contingencia
def contingencia():
    b = ''
    b += ('<div style="position:absolute;left:30px;top:410px;width:470px;height:380px;border:2.5px solid #6CA86C;border-radius:14px;background:#F6FBF6"></div>'
          '<div style="position:absolute;left:50px;top:750px;font-weight:700;color:#2E6B2E;font-size:25px">Servicio disponible</div>')
    b += ('<div style="position:absolute;left:530px;top:410px;width:680px;height:760px;border:2.5px solid #D9A400;border-radius:14px;background:#FFFBEF"></div>'
          '<div style="position:absolute;left:560px;top:1130px;font-weight:700;color:#8A6500;font-size:25px">Servicio caído · modo contingencia</div>')
    b += card('a', 'blue', 410, 20, 420, 78, '<div style="text-align:center"><b>1 · El estudiante confirma un grupo</b></div>')
    b += card('r', 'blue', 340, 140, 560, 92, '<div style="text-align:center"><b>2 · Reglas locales</b><small>turno · curso repetido · cruce de horario</small></div>')
    b += card('rej', 'red', 940, 130, 270, 112, '<div style="text-align:center"><b>Rechazada</b><small>no cumple una regla: se explica el motivo</small></div>')
    b += card('d', 'amber', 440, 270, 360, 84, '<div style="text-align:center;font-size:26px"><b>3 · ¿Servicio disponible?</b></div>', 'border-radius:42px;')
    # carril izquierdo
    b += card('d2', 'amber', 95, 450, 340, 84, '<div style="text-align:center"><b>¿Hay cupo en el grupo?</b></div>', 'border-radius:42px;')
    b += card('ok1', 'green', 52, 600, 200, 150, '<div style="text-align:center"><b>Cupo reservado</b><small>comprobante MLB-2026B-…</small></div>')
    b += card('no1', 'red', 278, 600, 200, 150, '<div style="text-align:center"><b>Sin cupo</b><small>se ofrece la lista de espera</small></div>')
    # carril derecho
    xw = 760
    b += card('p', 'orange', 600, 450, 560, 100, '<div style="text-align:center"><b>Solicitud pendiente</b><small>código SOL-2026B-… · no consume cupo</small></div>')
    b += card('s', 'blue', 600, 590, 560, 76, '<div style="text-align:center"><b>El servicio se restablece</b></div>')
    b += card('q', 'blue', 600, 706, 560, 90, '<div style="text-align:center"><b>Se procesan las pendientes</b><small>por orden de llegada</small></div>')
    b += card('d3', 'amber', 640, 836, 480, 84, '<div style="text-align:center"><b>¿Hay cupo y no hay cruce?</b></div>', 'border-radius:42px;')
    b += card('ok2', 'green', 566, 980, 300, 150, '<div style="text-align:center"><b>Confirmada</b><small>comprobante y aviso en Alertas</small></div>')
    b += card('no2', 'red', 894, 980, 300, 150, '<div style="text-align:center"><b>No confirmada</b><small>aviso en Alertas con el motivo y alternativas</small></div>')
    js = ("link('a','b','r','t');link('r','r','rej','l');"
          "link('r','b','d','t');"
          "link('d','b','d2','t',{fa:0.15,fb:0.5,mid:390,label:'Sí',lx:255,ly:390});"
          "link('d','b','p','t',{fa:0.85,fb:0.5,mid:390,label:'No',lx:880,ly:390});"
          "link('d2','b','ok1','t',{fa:0.25,fb:0.5,mid:570,label:'Sí',lx:152,ly:570});"
          "link('d2','b','no1','t',{fa:0.75,fb:0.5,mid:570,label:'No',lx:378,ly:570});"
          "link('p','b','s','t');link('s','b','q','t');link('q','b','d3','t');"
          "link('d3','b','ok2','t',{fa:0.25,fb:0.5,mid:950,label:'Sí',lx:716,ly:950});"
          "link('d3','b','no2','t',{fa:0.75,fb:0.5,mid:950,label:'No',lx:1044,ly:950});")
    return page(b, W, 1180, js)

# ------------------------------------------------------------ flujo scrum
def scrum():
    b = ''
    b += card('ev', 'orange', 30, 30, 360, 120, '<div style="text-align:center"><b>Evidencia real</b><small>8 fuentes públicas de la UNSA e INEI</small></div>')
    b += card('pb', 'blue', 440, 30, 440, 120, '<div style="text-align:center"><b>Product Backlog</b><small>8 historias · 26 puntos · prioridad MoSCoW</small></div>')
    b += card('s1', 'green', 30, 270, 218, 200, '<div style="text-align:center"><b>Sprint 1</b><small>planificación: meta y 13 puntos<br>HU-08 · HU-12 · HU-09</small></div>')
    b += card('r1', 'amber', 274, 270, 218, 200, '<div style="text-align:center"><b>Revisión 1</b><small>pruebas y capturas; ajusta el backlog</small></div>')
    b += card('s2', 'green', 518, 270, 218, 200, '<div style="text-align:center"><b>Sprint 2</b><small>planificación: meta y 13 puntos<br>HU-11 · HU-10 · HU-13</small></div>')
    b += card('r2', 'amber', 762, 270, 218, 200, '<div style="text-align:center"><b>Revisión 2</b><small>pruebas, capturas y retrospectiva</small></div>')
    b += card('en', 'guinda', 1006, 270, 204, 200, '<div style="text-align:center"><b>Entrega</b><small style="color:#fff">MatrLab 2.0 e informe</small></div>')
    js = ("link('ev','r','pb','l');"
          "link('pb','b','s1','t',{fa:0.25,fb:0.5,mid:210});"
          "link('pb','b','s2','t',{fa:0.75,fb:0.5,mid:210});"
          "link('s1','r','r1','l');link('r1','r','s2','l');link('s2','r','r2','l');link('r2','r','en','l');")
    b += ('<div style="position:absolute;left:30px;top:505px;font-size:20px;color:#444">Los sprints son iteraciones lógicas ordenadas por prioridad y dependencia; el informe no les asigna duración en días.</div>')
    return page(b, W, 560, js)

if __name__ == '__main__':
    render({'f5_arbol': arbol(), 'f5_navegacion': navegacion(), 'f5_contingencia': contingencia(), 'f5_scrum_flujo': scrum()}, OUT)
