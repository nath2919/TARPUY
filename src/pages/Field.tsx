import { lazy, Suspense, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapPin } from 'lucide-react';
import { useFarm } from '../context/FarmContext';
import { PageHeading } from '../components/UI';
const FieldMap = lazy(() => import('../components/FieldMap'));
export default function Field() {
  const { state, update } = useFarm();
  const [selected, setSelected] = useState(state.field);
  const [lat, setLat] = useState(String(state.field?.lat ?? -32.95));
  const [lng, setLng] = useState(String(state.field?.lng ?? -60.65));
  const [error, setError] = useState('');
  const navigate = useNavigate();
  return <><PageHeading eyebrow="01 / SELECCIÓN DE CAMPO" title="Todo empieza en tu tierra.">Haz clic en el mapa o ingresa coordenadas para marcar un punto. En este prototipo no se delimitan polígonos.</PageHeading><div className="grid gap-6 lg:grid-cols-[1fr_330px]"><div><Suspense fallback={<div className="card h-[420px]">Cargando mapa…</div>}><FieldMap field={selected} onSelect={field => { setSelected(field); setLat(String(field.lat)); setLng(String(field.lng)); setError(''); }}/></Suspense><p className="mt-3 text-xs text-slate-500">Mapa base: OpenStreetMap. Requiere internet; puedes continuar por coordenadas.</p></div><aside className="card"><MapPin size={28}/><h2 className="mt-4 text-xl font-semibold">Ubica tu lote</h2><p className="mb-5 mt-2 text-sm text-slate-500">Punto inicial: Rosario, Argentina. Puedes explorar cualquier ubicación.</p><form onSubmit={e => { e.preventDefault(); if (!lat.trim() || !lng.trim() || !Number.isFinite(Number(lat)) || !Number.isFinite(Number(lng)) || Math.abs(Number(lat)) > 90 || Math.abs(Number(lng)) > 180) { setError('Latitud válida: −90 a 90. Longitud válida: −180 a 180.'); return; } setSelected({ lat: Number(lat), lng: Number(lng) }); setError(''); }}><label className="label" htmlFor="lat">Latitud</label><input id="lat" type="number" step="any" value={lat} onChange={e => { setLat(e.target.value); setSelected(null); }} className="input"/><label className="label mt-4" htmlFor="lng">Longitud</label><input id="lng" type="number" step="any" value={lng} onChange={e => { setLng(e.target.value); setSelected(null); }} className="input"/><button className="button-secondary mt-4 w-full">Usar coordenadas</button></form>{error && <p role="alert" className="mt-3 text-sm text-red-700">{error}</p>}<div aria-live="polite" className="my-5 rounded-xl bg-mist p-4 text-sm">{selected ? selected.lat.toFixed(4) + ', ' + selected.lng.toFixed(4) : 'Aún no seleccionaste un punto.'}</div><button disabled={!selected} onClick={() => { if (selected) { update({ field: selected }); navigate('/diagnostico'); } }} className="button w-full">Confirmar ubicación</button></aside></div></>;
}