'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';

const links = [
  ['/comment-ca-marche', 'Comment ça marche'],
  ['/ma-maison', 'Ma maison'],
  ['/securite', 'Sécurité'],
  ['/guides', 'Guides'],
  ['/professionnels', 'Professionnels'],
] as const;

export function MobileMenu() {
  const [open, setOpen] = useState(false);
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setOpen(false);
    };
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    document.addEventListener('keydown', closeOnEscape);
    closeButtonRef.current?.focus();
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, [open]);

  return <div className="mobile-menu">
    <button type="button" className="mobile-menu-toggle" aria-expanded={open} aria-controls="mobile-navigation" aria-label={open ? 'Fermer le menu' : 'Ouvrir le menu'} onClick={() => setOpen(value => !value)}>
      <span aria-hidden="true">{open ? '×' : '☰'}</span>
    </button>
    {open && <div className="mobile-menu-panel" id="mobile-navigation" role="dialog" aria-label="Navigation principale">
      <div className="mobile-menu-panel-head"><span className="eyebrow">NAVIGATION</span><button ref={closeButtonRef} type="button" className="mobile-menu-close" aria-label="Fermer le menu" onClick={() => setOpen(false)}>×</button></div>
      <nav aria-label="Navigation mobile">{links.map(([href, label]) => <Link key={href} href={href} onClick={() => setOpen(false)}>{label}</Link>)}</nav>
      <Link className="mobile-menu-cta" href="/comment-ca-marche" onClick={() => setOpen(false)}>Essayer NALVIUM <span aria-hidden="true">→</span></Link>
    </div>}
  </div>;
}
