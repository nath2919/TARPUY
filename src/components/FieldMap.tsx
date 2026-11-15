import { MapContainer, TileLayer, CircleMarker, useMapEvents, useMap } from 'react-leaflet';
import { useEffect } from 'react';
import type { Field } from '../types';
function Selection({ field, onSelect }: { field: Field | null; onSelect: (field: Field) => void }) {
  const map = useMap();
  useMapEvents({ click: event => onSelect({ lat: Number(event.latlng.lat.toFixed(5)), lng: Number(event.latlng.wrap().lng.toFixed(5)) }) });
  // React-Leaflet solo utiliza center al montar; sincronizamos selecciones posteriores.
  useEffect(() => { if (field) map.panTo([field.lat, field.lng]); }, [field, map]);
  return field ? <CircleMarker center={[field.lat, field.lng]} radius={12} pathOptions={{ color: '#173f35', fillColor: '#bddd87', fillOpacity: 0.9 }}/> : null;
}
export default function FieldMap({ field, onSelect }: { field: Field | null; onSelect: (field: Field) => void }) {
  return <MapContainer center={field ? [field.lat, field.lng] : [-32.95, -60.65]} zoom={9} className="h-[420px] w-full rounded-2xl" scrollWheelZoom={false}><TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"/><Selection field={field} onSelect={onSelect}/></MapContainer>;
}