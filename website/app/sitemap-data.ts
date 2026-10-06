import { categories, guides } from './data';
import { publishedLocalHubPaths, publishedLocalProblemPaths } from './data/france';
import { chunkSitemapPaths } from './data/france/sitemap-utils';

export const BASE_URL = 'https://nalvium.com';
export const LAST_MODIFIED = '2026-10-05';

function escapeXml(value: string): string {
  return value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll("'", '&apos;');
}

function generalPaths(): string[] {
  return ['', '/comment-ca-marche', '/ma-maison', '/securite', '/professionnels', '/communaute', '/guides', '/mentions-legales', '/confidentialite', '/cookies', '/cgu', '/suppression-compte', ...categories.map(category => `/guides/${category.slug}`), ...guides.map(guide => `/guides/${guide.slug}`)];
}

export type SitemapSegment = { name: string; paths: string[] };

export function sitemapSegments(): SitemapSegment[] {
  return [
    { name: 'general.xml', paths: generalPaths() },
    ...chunkSitemapPaths(publishedLocalHubPaths()).map((paths, index) => ({ name: `local-hubs-${index}.xml`, paths })),
    ...chunkSitemapPaths(publishedLocalProblemPaths()).map((paths, index) => ({ name: `local-problems-${index}.xml`, paths })),
  ];
}

export function sitemapResponse(body: string): Response {
  return new Response(body, { headers: { 'Content-Type': 'application/xml; charset=utf-8', 'Cache-Control': 'public, max-age=3600, s-maxage=3600' } });
}

export function urlSet(paths: string[]): string {
  return `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${paths.map(path => `<url><loc>${escapeXml(`${BASE_URL}${path}`)}</loc><lastmod>${LAST_MODIFIED}</lastmod><changefreq>monthly</changefreq><priority>${path === '' ? '1.0' : '0.7'}</priority></url>`).join('')}</urlset>`;
}

export function segmentResponse(name: string): Response {
  const segment = sitemapSegments().find(item => item.name === name);
  return segment ? sitemapResponse(urlSet(segment.paths)) : new Response('Not Found', { status: 404 });
}
