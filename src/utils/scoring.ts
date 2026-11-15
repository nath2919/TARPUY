import type { Priorities, Rotation, Metric } from '../types';
export const metricKeys: Metric[] = ['soil', 'water', 'resilience', 'erosion'];
// Escala ilustrativa: agua entre 300 y 800 mm/ciclo. No es un modelo agronómico.
export function utility(key: Metric, value: number): number {
  const normalized = key === 'water' ? (800 - value) / 5 : key === 'erosion' ? 100 - value : value;
  return Math.max(0, Math.min(100, normalized));
}
export function score(rotation: Rotation, priorities: Priorities): number {
  const total = metricKeys.reduce((sum, key) => sum + priorities[key], 0);
  // Si todos los pesos son cero se utiliza igual importancia.
  return metricKeys.reduce((sum, key) => sum + utility(key, rotation.metrics[key]) * (total ? priorities[key] : 1), 0) / (total || 4);
}
export function rankRotations(rotations: Rotation[], priorities: Priorities): Rotation[] {
  return [...rotations].sort((a, b) => score(b, priorities) - score(a, priorities) || a.id.localeCompare(b.id));
}