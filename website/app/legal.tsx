import Link from 'next/link';

export function LegalPage({ eyebrow, title, intro, updated = '5 octobre 2026', children }: { eyebrow: string; title: string; intro: string; updated?: string; children: React.ReactNode }) {
  return <main className="legal-document"><header className="legal-document-header"><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{intro}</p><small>Dernière mise à jour : {updated}</small></header><nav className="legal-document-nav" aria-label="Pages légales"><Link href="/mentions-legales">Mentions légales</Link><Link href="/confidentialite">Confidentialité</Link><Link href="/cookies">Cookies</Link><Link href="/cgu">CGU</Link><Link href="/suppression-compte">Suppression du compte</Link></nav><article className="legal-document-body">{children}</article></main>;
}

export function LegalSection({ title, children, id }: { title: string; children: React.ReactNode; id?: string }) {
  return <section className="legal-section" id={id}><h2>{title}</h2>{children}</section>;
}

export function LegalNote({ children }: { children: React.ReactNode }) {
  return <aside className="legal-note">{children}</aside>;
}
