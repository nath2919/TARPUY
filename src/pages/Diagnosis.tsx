import { useEffect, useState } from 'react';
import { Droplets, Leaf, CloudRain, Thermometer } from 'lucide-react';
import { useFarm } from '../context/FarmContext';
import { getDiagnosis } from '../services/diagnosis';
import type { Diagnosis as DiagnosisData } from '../types';
import { PageHeading, MockNote, NextLink } from '../components/UI';
export default function Diagnosis() {
  const { state } = useFarm();
  const [data, setData] = useState<DiagnosisData | null>(null);
  const [error, setError] = useState(false);
  useEffect(() => {
    if (!state.field) return;
    const controller = new AbortController();
    setData(null); setError(false);
    getDiagnosis(state.field, controller.signal).then(setData).catch((e: unknown) => { if (!(e instanceof DOMException && e.name === 'AbortError')) setError(true); });
    return () => controller.abort();
  }, [state.field]);
  return <><PageHeading eyebrow="02 / DIAGNÓSTICO DEL LOTE" title="Escucha lo que dice tu suelo.">Una fotografía ambiental de referencia para empezar a explorar tus alternativas.</PageHeading>{error ? <p role="alert">No se pudo generar el diagnóstico. Vuelve a seleccionar el campo.</p> : !data ? <p role="status">Preparando indicadores simulados…</p> : <><div className="mb-6 flex flex-wrap justify-between gap-3"><span className="badge">UBICACIÓN · {state.field?.lat.toFixed(4)}, {state.field?.lng.toFixed(4)}</span><span className="text-xs text-slate-500">Escenario ilustrativo · Sin observación real</span></div><div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">{[{ label: 'Humedad del suelo', value: data.moisture, unit: '% volumétrico', icon: Droplets, note: 'Capa superficial · simulación' }, { label: 'Índice de vegetación', value: data.ndvi, unit: 'NDVI', icon: Leaf, note: 'Escala de −1 a 1' }, { label: 'Precipitación', value: data.precipitation, unit: 'mm / 30 días', icon: CloudRain, note: 'Acumulado ilustrativo' }, { label: 'Temperatura media', value: data.temperature, unit: '°C', icon: Thermometer, note: 'Promedio ilustrativo de 30 días' }].map(item => <div className="card" key={item.label}><item.icon className="text-[#547e9c]"/><p className="mt-6 text-sm text-slate-500">{item.label}</p><p className="mt-2 text-4xl font-semibold">{item.value} <span className="text-xs font-normal text-slate-500">{item.unit}</span></p><p className="mt-5 border-t pt-4 text-xs text-slate-500">{item.note}</p></div>)}</div><div className="card my-7 bg-forest text-white"><p className="eyebrow text-leaf">UNA LECTURA CON CONTEXTO</p><h2 className="mt-3 text-2xl font-semibold">La cobertura es una oportunidad para explorar.</h2><p className="mt-3 max-w-3xl text-sm leading-relaxed text-white/70">Prueba secuencias más diversas y compara los indicadores del escenario. Una decisión real requiere series temporales, datos de suelo y manejo del lote.</p></div><NextLink to="/prioridades">Definir mis prioridades</NextLink><MockNote/></>}</>;
}