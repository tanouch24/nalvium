import type { Metadata } from 'next';
import './globals.css';
import { Footer, Header } from './components';

export const metadata: Metadata = {
  metadataBase: new URL('https://nalvium.com'),
  title: {
    default: 'NALVIUM — Montrez le problème. NALVIUM vous guide.',
    template: '%s | NALVIUM',
  },
  description: 'NALVIUM vous aide gratuitement à comprendre un problème domestique, à agir avec prudence et à savoir quand un professionnel est nécessaire.',
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    siteName: 'NALVIUM',
    title: 'Un problème à la maison ? Montrez-le à NALVIUM.',
    description: 'Photo → comprendre → être guidé → professionnel si nécessaire.',
    url: 'https://nalvium.com',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const jsonLd = [
    { '@context': 'https://schema.org', '@type': 'Organization', name: '3E Technology Ltd', legalName: '3E Technology Ltd', url: 'https://nalvium.com', email: 'contact@nalvium.com', identifier: { '@type': 'PropertyValue', propertyID: 'Company number', value: '17179077' }, brand: { '@type': 'Brand', name: 'NALVIUM' } },
    { '@context': 'https://schema.org', '@type': 'WebSite', name: 'NALVIUM', url: 'https://nalvium.com', publisher: { '@type': 'Organization', name: '3E Technology Ltd' } },
    { '@context': 'https://schema.org', '@type': 'SoftwareApplication', name: 'NALVIUM', applicationCategory: 'LifestyleApplication', operatingSystem: 'Android, iOS', description: 'Assistant mobile gratuit pour comprendre un problème domestique et être guidé avec prudence.', publisher: { '@type': 'Organization', name: '3E Technology Ltd' } },
  ];

  return (
    <html lang="fr">
      <body>
        <Header />
        {children}
        <Footer />
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      </body>
    </html>
  );
}
