# Estilo comun de todas las figuras del informe (Laboratorio 05).
# Fuente Carlito, color institucional guinda y mismas formas en todo.
import asyncio
from playwright.async_api import async_playwright

CSS = """
*{box-sizing:border-box}
body{margin:0;font-family:Carlito,'Liberation Sans',sans-serif;color:#222;background:#fff}
.fig{position:relative;padding:26px 30px;background:#fff;font-size:24px;line-height:1.15}
.card{border:2px solid #999;border-radius:12px;padding:10px 14px;position:absolute;background:#fff;display:flex;flex-direction:column;justify-content:center}
.card b{font-weight:700}
.card small{font-size:19px;color:#555;margin-top:4px;display:block}
.blue{background:#E7F0FA;border-color:#6F9BCB}
.green{background:#E6F2E6;border-color:#6CA86C}
.red{background:#F9E2E0;border-color:#CF7C75}
.amber{background:#FFF3CD;border-color:#D9A400}
.orange{background:#FDE9D0;border-color:#E0A25A}
.pink{background:#F6DADF;border-color:#C9929A}
.guinda{background:#8C1D2F;border-color:#8C1D2F;color:#fff}
.gray{background:#F2F2F2;border-color:#B5B5B5}
.badge{display:inline-block;min-width:40px;text-align:center;padding:1px 8px;border-radius:14px;background:#8C1D2F;color:#fff;font-weight:700;font-size:20px;margin-right:8px}
.nuevo{display:inline-block;background:#D9A400;color:#fff;font-size:16px;font-weight:700;padding:1px 7px;border-radius:8px;margin-left:8px;vertical-align:middle}
.lbl{position:absolute;font-size:20px;font-weight:700;color:#444;background:#fff;padding:0 6px}
svg.arrows{position:absolute;left:0;top:0;pointer-events:none}
"""

JS = """
function R(id){const e=document.getElementById(id),f=document.getElementById('fig').getBoundingClientRect(),r=e.getBoundingClientRect();return {l:r.left-f.left,t:r.top-f.top,w:r.width,h:r.height}}
function P(id,side,frac){const r=R(id);frac=(frac===undefined)?0.5:frac;
 if(side=='b')return [r.l+r.w*frac,r.t+r.h]; if(side=='t')return [r.l+r.w*frac,r.t];
 if(side=='l')return [r.l,r.t+r.h*frac]; return [r.l+r.w,r.t+r.h*frac];}
function link(a,sa,b,sb,o){o=o||{};const p1=P(a,sa,o.fa),p2=P(b,sb,o.fb);
 const svg=document.getElementById('arrows');let d;
 if(sa=='b'||sa=='t'){const ym=(o.mid!==undefined)?o.mid:(p1[1]+p2[1])/2; d=(Math.abs(p1[0]-p2[0])<2)?`M${p1[0]},${p1[1]} L${p2[0]},${p2[1]}`:`M${p1[0]},${p1[1]} V${ym} H${p2[0]} V${p2[1]}`;}
 else {const xm=(o.mid!==undefined)?o.mid:(p1[0]+p2[0])/2; d=(Math.abs(p1[1]-p2[1])<2)?`M${p1[0]},${p1[1]} L${p2[0]},${p2[1]}`:`M${p1[0]},${p1[1]} H${xm} V${p2[1]} H${p2[0]}`;}
 const c=o.color||'#555';const dash=o.dashed?'stroke-dasharray="9 7"':'';
 const mk=o.bidir?'marker-start="url(#h0)" marker-end="url(#h1)"':'marker-end="url(#h1)"';
 svg.insertAdjacentHTML('beforeend',`<path d="${d}" fill="none" stroke="${c}" stroke-width="2.6" ${dash} ${mk}/>`);
 if(o.label){const x=(o.lx!==undefined)?o.lx:(p1[0]+p2[0])/2,y=(o.ly!==undefined)?o.ly:(p1[1]+p2[1])/2;
  const l=document.createElement('div');l.className='lbl';l.textContent=o.label;l.style.left=x+'px';l.style.top=y+'px';l.style.transform='translate(-50%,-50%)';document.getElementById('fig').appendChild(l);}}
function init(){const f=document.getElementById('fig'),s=document.getElementById('arrows');s.setAttribute('width',f.offsetWidth);s.setAttribute('height',f.offsetHeight);}
"""

DEFS = ('<defs><marker id="h1" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="userSpaceOnUse">'
        '<path d="M1,1 L11,6 L1,11 z" fill="#555"/></marker>'
        '<marker id="h0" markerWidth="12" markerHeight="12" refX="2" refY="6" orient="auto-start-reverse" markerUnits="userSpaceOnUse">'
        '<path d="M1,1 L11,6 L1,11 z" fill="#555"/></marker></defs>')

def page(body, width, height, extra_js=''):
    return (f'<html><head><meta charset="utf-8"><style>{CSS}</style></head><body>'
            f'<div class="fig" id="fig" style="width:{width}px;height:{height}px">{body}'
            f'<svg class="arrows" id="arrows">{DEFS}</svg></div>'
            f'<script>{JS}\ninit();\n{extra_js}</script></body></html>')

async def _render(items, outdir):
    async with async_playwright() as p:
        br = await p.chromium.launch()
        for name, html in items.items():
            pg = await br.new_page(viewport={'width': 1400, 'height': 1000}, device_scale_factor=2)
            await pg.set_content(html)
            await pg.wait_for_timeout(300)
            el = await pg.query_selector('#fig')
            await el.screenshot(path=f'{outdir}/{name}.png')
            await pg.close()
        await br.close()

def render(items, outdir):
    asyncio.run(_render(items, outdir))
