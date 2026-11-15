import type { Metric, Priorities, Rotation } from '../types';
export const defaultPriorities: Priorities = { soil: 80, water: 70, resilience: 60, erosion: 50 };
export const metricInfo: Record<Metric, { label: string; priority: string; unit: string; lower: boolean }> = {
  soil: { label: 'Salud de suelo', priority: 'Mejorar la salud del suelo', unit: '/100', lower: false },
  water: { label: 'Uso de agua', priority: 'Ahorrar agua', unit: 'mm/ciclo', lower: true },
  resilience: { label: 'Resiliencia', priority: 'Resistir períodos de sequía', unit: '/100', lower: false },
  erosion: { label: 'Riesgo de erosión', priority: 'Reducir la erosión', unit: '/100', lower: true },
};
export const rotations: Rotation[] = [
  { id: 'maiz-soja', name: 'Maíz · Soja', crops: ['Maíz', 'Soja'], description: 'Una secuencia conocida, con menor diversidad y períodos de suelo descubierto.', metrics: { soil: 56, water: 620, resilience: 52, erosion: 64 } },
  { id: 'maiz-trigo', name: 'Maíz · Trigo · Cobertura', crops: ['Maíz', 'Trigo', 'Vicia de cobertura'], description: 'Más raíces y cobertura entre ciclos para proteger el suelo y conservar humedad.', metrics: { soil: 86, water: 490, resilience: 82, erosion: 24 } },
  { id: 'soja-leguminosa', name: 'Soja · Leguminosa · Maíz', crops: ['Soja', 'Arveja', 'Maíz'], description: 'Diversifica la secuencia con una leguminosa y mejora el aporte de nitrógeno.', metrics: { soil: 79, water: 450, resilience: 88, erosion: 32 } },
];