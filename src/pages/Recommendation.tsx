import { useState } from 'react';
import { Download, Bookmark, Sprout } from 'lucide-react';
import { useFarm } from '../context/FarmContext';
import { rotations, metricInfo } from '../data/mock';
import { rankRotations, score, metricKeys } from '../utils/scoring';
import { PageHeading, MockNote, NextLink } from '../components/UI';
export default function Recommendation() {
  const { state } = useFarm();
  const [message, setMessage] = useState('');
  const best = rankRotations(rotations, state.priorities)[0];
  const current = rotations.find(r => r.id === state.currentRotation)!;
  const report = { application: 'SoilShift', generatedAt: new Date().toISOString(), dataSource: 'MOCK — sin conexión NASA', field: state.field, priorities: state.priorities, currentRotation: current, recommendation: best, score: Number(score(best, state.priorities).toFixed(1)), method: 'Promedio ponderado; agua=(800-mm)/5; erosión=100-riesgo; escala 0–100. No constituye asesoramiento agronómico.' };
  function save() { try { localStorage.setItem('soilshift:report', JSON.stringify(report)); setMessage('Plan guardado en este navegador.'); } catch { setMessage('No se pudo guardar. Puedes exportar el informe.'); } }
  function download() {
    const url = URL.createObjectURL(new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' }));
    const link = document.createElement('a'); link.href = url; link.download = 'soilshift-plan.json';
    document.body.append(link); link.click(); link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000); setMessage('Informe JSON preparado para descargar.');
  }
  return <><PageHeading eyebrow="05 / TU PRÓXIMO PASO" title="Una rotación con propósito.">La secuencia con mayor afinidad para tus objetivos dentro de las tres opciones simuladas.</PageHeading><section className="rounded-3xl bg-forest p-7 text-white md:p-10"><div className="flex flex-wrap items-start justify-between gap-6"><div><span className="badge bg-white/10 text-leaf">ALTERNATIVA DESTACADA</span><h2 className="mt-5 text-3xl font-semibold md:text-4xl">{best.name}</h2><p className="mt-4 max-w-2xl leading-relaxed text-white/70">{best.description}</p></div><Sprout size={58} className="text-leaf"/></div><div className="mt-8 flex flex-wrap gap-3">{best.crops.map((crop, i) => <span key={crop} className="rounded-xl border border-white/20 px-5 py-3 text-sm">{i + 1} / {crop}</span>)}</div><p className="mt-8 text-sm text-leaf">Afinidad: {score(best, state.priorities).toFixed(1)}/100 {best.id === current.id ? '· Tu secuencia actual obtiene el mejor puntaje.' : '· Comparada con ' + current.name}</p></section><div className="my-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{metricKeys.map(key => { const delta = best.metrics[key] - current.metrics[key]; return <div className="card" key={key}><p className="text-xs text-slate-500">{metricInfo[key].label}</p><p className="mt-3 text-2xl font-semibold">{delta > 0 ? '+' : ''}{delta} <span className="text-xs font-normal">{key === 'water' ? 'mm/ciclo' : 'puntos'}</span></p><p className="mt-2 text-xs text-slate-500">Respecto a tu rotación actual</p></div>; })}</div><div className="card mb-7"><h3 className="font-semibold">Antes de llevarlo al campo</h3><p className="mt-3 text-sm leading-relaxed text-slate-500">Revisa calendario de siembra, suelo, agua, costos y destino de la cosecha con tu asesor. El puntaje no es una probabilidad de éxito ni una predicción de rendimiento. Las diferencias son valores del mock, no impactos estimados para tu ubicación.</p></div><div className="flex flex-wrap gap-3"><button onClick={save} className="button"><Bookmark size={18}/>Guardar plan</button><button onClick={download} className="button-secondary"><Download size={18}/>Exportar JSON</button><NextLink to="/prioridades">Ajustar prioridades</NextLink></div><p role="status" className="mt-4 text-sm">{message}</p><MockNote/></>;
}