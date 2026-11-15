import { describe, expect, it } from 'vitest';
import { score, utility, rankRotations } from './scoring';
import { rotations, defaultPriorities } from '../data/mock';
describe('Motor de comparación', () => {
  it('favorece menos agua y menos erosión', () => { expect(utility('water', 450)).toBeGreaterThan(utility('water', 620)); expect(utility('erosion', 24)).toBeGreaterThan(utility('erosion', 64)); });
  it('con prioridad hídrica elige menor uso', () => { expect(rankRotations(rotations, { soil: 0, water: 100, resilience: 0, erosion: 0 })[0].id).toBe('soja-leguminosa'); });
  it('con prioridad de suelo elige mayor salud', () => { expect(rankRotations(rotations, { soil: 100, water: 0, resilience: 0, erosion: 0 })[0].id).toBe('maiz-trigo'); });
  it('pesos cero producen promedio finito', () => { const value = score(rotations[0], { soil: 0, water: 0, resilience: 0, erosion: 0 }); expect(value).toBeGreaterThanOrEqual(0); expect(value).toBeLessThanOrEqual(100); });
  it('no altera el catálogo', () => { const ids = rotations.map(r => r.id); rankRotations(rotations, defaultPriorities); expect(rotations.map(r => r.id)).toEqual(ids); });
});