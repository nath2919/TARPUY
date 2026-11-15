import { createContext, useContext, useState, type ReactNode } from 'react';
import type { FarmState } from '../types';
import { defaultPriorities, rotations } from '../data/mock';
const initial: FarmState = { field: null, currentRotation: rotations[0].id, priorities: defaultPriorities };
function restore(): FarmState {
  try {
    const saved = JSON.parse(localStorage.getItem('soilshift:farm') || 'null') as FarmState | null;
    if (!saved || !rotations.some(r => r.id === saved.currentRotation)) return initial;
    if (!Object.keys(defaultPriorities).every(k => typeof saved.priorities?.[k as keyof typeof defaultPriorities] === 'number' && Number.isFinite(saved.priorities[k as keyof typeof defaultPriorities]) && saved.priorities[k as keyof typeof defaultPriorities] >= 0 && saved.priorities[k as keyof typeof defaultPriorities] <= 100)) return initial;
    if (saved.field !== null && (!saved.field || !Number.isFinite(saved.field.lat) || !Number.isFinite(saved.field.lng) || Math.abs(saved.field.lat) > 90 || Math.abs(saved.field.lng) > 180)) return initial;
    return saved;
  } catch { return initial; }
}
const Context = createContext<{ state: FarmState; update: (patch: Partial<FarmState>) => void; storageError: boolean } | null>(null);
export function FarmProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<FarmState>(restore);
  const [storageError, setStorageError] = useState(false);
  function update(patch: Partial<FarmState>) {
    const next = { ...state, ...patch }; setState(next);
    try { localStorage.setItem('soilshift:farm', JSON.stringify(next)); setStorageError(false); } catch { setStorageError(true); }
  }
  return <Context.Provider value={{ state, update, storageError }}>{children}</Context.Provider>;
}
export function useFarm() { const context = useContext(Context); if (!context) throw new Error('FarmProvider requerido'); return context; }