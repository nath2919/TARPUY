import type { Diagnosis, Field } from '../types';
// Adaptador mock reemplazable por un backend. No consulta NASA.
export async function getDiagnosis(field: Field, signal?: AbortSignal): Promise<Diagnosis> {
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(resolve, 350);
    signal?.addEventListener('abort', () => { clearTimeout(timer); reject(new DOMException('Cancelado', 'AbortError')); }, { once: true });
  });
  const offset = Math.abs(Math.sin(field.lat * Math.PI / 180) * Math.cos(field.lng * Math.PI / 180));
  return { moisture: Math.round(22 + offset * 16), ndvi: Number((0.55 + offset * 0.22).toFixed(2)), precipitation: Math.round(65 + offset * 70), temperature: Number((20 + offset * 7).toFixed(1)) };
}