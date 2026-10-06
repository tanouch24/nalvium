import { BASE_URL, LAST_MODIFIED, sitemapResponse, sitemapSegments } from '../sitemap-data';

export function GET(): Response {
  const entries = sitemapSegments().map(segment => `<sitemap><loc>${BASE_URL}/${segment.name}</loc><lastmod>${LAST_MODIFIED}</lastmod></sitemap>`).join('');
  return sitemapResponse(`<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${entries}</sitemapindex>`);
}
