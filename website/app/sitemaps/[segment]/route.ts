import { sitemapResponse, sitemapSegments, urlSet } from '../../sitemap-data';

export const dynamicParams = false;

export function generateStaticParams() {
  return sitemapSegments().map(segment => ({ segment: segment.name }));
}

export async function GET(_request: Request, { params }: { params: Promise<{ segment: string }> }): Promise<Response> {
  const { segment } = await params;
  const entry = sitemapSegments().find(item => item.name === segment);
  if (!entry) return new Response('Not Found', { status: 404 });
  return sitemapResponse(urlSet(entry.paths));
}
