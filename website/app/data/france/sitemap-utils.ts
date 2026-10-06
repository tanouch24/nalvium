import { publishedLocalHubPaths, publishedLocalProblemPaths } from './index';

export const SITEMAP_URL_LIMIT = 45_000;

export function publishedLocalSitemapPaths(): string[] {
  return [...publishedLocalHubPaths(), ...publishedLocalProblemPaths()];
}

export function chunkSitemapPaths(paths: string[], limit = SITEMAP_URL_LIMIT): string[][] {
  if (!Number.isInteger(limit) || limit < 1) throw new Error('Sitemap chunk limit must be a positive integer');
  const chunks: string[][] = [];
  for (let index = 0; index < paths.length; index += limit) chunks.push(paths.slice(index, index + limit));
  return chunks;
}
