import { rotations } from '../data/mock';
import { useFarm } from '../context/FarmContext';
import { rankRotations } from '../utils/scoring';
import { PageHeading, NextLink, MockNote } from '../components/UI';
import { RotationCard } from '../components/RotationCard';
export default function Compare() {
  const { state } = useFarm();
  const best = rankRotations(rotations, state.priorities)[0];
  const ordered = [...rotations].sort((a, b) => Number(b.id === state.currentRotation) - Number(a.id === state.currentRotation));
  return <><PageHeading eyebrow="04 / COMPARADOR DE ROTACIONES" title="Tres caminos. Una mejor perspectiva.">Compara tu secuencia actual con dos alternativas según tus prioridades y los valores del escenario.</PageHeading><p className="mb-5 text-xs text-slate-500">↑ Mayor es favorable · ↓ Menor es favorable · Las barras muestran desempeño favorable normalizado.</p><div className="grid gap-5 lg:grid-cols-3">{ordered.map(rotation => <RotationCard key={rotation.id} rotation={rotation} priorities={state.priorities} current={rotation.id === state.currentRotation} best={rotation.id === best.id}/>)}</div><details className="card my-6 text-sm"><summary className="cursor-pointer font-semibold">¿Cómo calculamos la afinidad?</summary><p className="mt-3 leading-relaxed text-slate-500">Promedio ponderado de salud, resiliencia, protección ante erosión (100 − riesgo) y desempeño hídrico ((800 − mm) / 5), limitado a 0–100. La escala de 300–800 mm es ilustrativa. Las secuencias pueden tener distinta duración: sus valores por ciclo no equivalen a una comparación anual. No modelamos rendimiento, rentabilidad ni disponibilidad hídrica local. Los empates se resuelven por identificador.</p></details><NextLink to="/recomendacion">Ver mi recomendación</NextLink><MockNote/></>;
}