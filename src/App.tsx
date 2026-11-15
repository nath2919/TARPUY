import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { FarmProvider, useFarm } from './context/FarmContext';
import { Layout } from './components/Layout';
import Home from './pages/Home';
import Field from './pages/Field';
import Diagnosis from './pages/Diagnosis';
import Priorities from './pages/Priorities';
import Compare from './pages/Compare';
import Recommendation from './pages/Recommendation';
import { NextLink, PageHeading } from './components/UI';
import type { ReactNode } from 'react';
function RequireField({ children }: { children: ReactNode }) { const { state } = useFarm(); return state.field ? children : <Navigate to="/campo" replace/>; }
export default function App() {
  return <FarmProvider><BrowserRouter><Routes><Route element={<Layout/>}><Route index element={<Home/>}/><Route path="campo" element={<Field/>}/><Route path="diagnostico" element={<RequireField><Diagnosis/></RequireField>}/><Route path="prioridades" element={<RequireField><Priorities/></RequireField>}/><Route path="comparador" element={<RequireField><Compare/></RequireField>}/><Route path="recomendacion" element={<RequireField><Recommendation/></RequireField>}/><Route path="*" element={<><PageHeading eyebrow="404" title="Este sendero no existe.">Vuelve al inicio para continuar con tu campo.</PageHeading><NextLink to="/">Ir al inicio</NextLink></>}/></Route></Routes></BrowserRouter></FarmProvider>;
}