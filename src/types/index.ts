export interface Field { lat: number; lng: number; }
export type Metric = 'soil' | 'water' | 'resilience' | 'erosion';
export type Priorities = Record<Metric, number>;
export interface Rotation { id: string; name: string; crops: string[]; description: string; metrics: Record<Metric, number>; }
export interface Diagnosis { moisture: number; ndvi: number; precipitation: number; temperature: number; }
export interface FarmState { field: Field | null; currentRotation: string; priorities: Priorities; }