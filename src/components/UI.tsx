import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
export function PageHeading({ eyebrow, title, children }: { eyebrow: string; title: string; children: ReactNode }) {
  return <div className="mb-8 max-w-3xl"><p className="eyebrow">{eyebrow}</p><h1 className="mt-3 text-3xl font-semibold tracking-tight md:text-5xl">{title}</h1><p className="mt-4 leading-relaxed text-slate-500">{children}</p></div>;
}
export function NextLink({ to, children }: { to: string; children: ReactNode }) { return <Link className="button" to={to}>{children}<ArrowRight size={18}/></Link>; }
export function MockNote() { return <p className="mt-6 text-xs leading-relaxed text-slate-500">Datos simulados con fines demostrativos. No se han consultado satélites ni APIs de NASA. Los resultados no sustituyen una evaluación agronómica local.</p>; }