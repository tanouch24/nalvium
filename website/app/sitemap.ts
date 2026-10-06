import { MetadataRoute } from 'next';
import { guides, categories } from './data';
import { publishedLocalSitemapPaths } from './data/france/sitemap-utils';
export default function sitemap(): MetadataRoute.Sitemap { const base='https://nalvium.com'; const siteLastModified = new Date('2026-10-05'); const routes=['','/comment-ca-marche','/ma-maison','/securite','/professionnels','/communaute','/guides','/mentions-legales','/confidentialite','/cookies','/cgu','/suppression-compte',...categories.map(c=>`/guides/${c.slug}`),...guides.map(g=>`/guides/${g.slug}`),...publishedLocalSitemapPaths()];return routes.map(url=>({url:base+url,lastModified:siteLastModified,changeFrequency:'monthly',priority:url===''?1:.7})) }
