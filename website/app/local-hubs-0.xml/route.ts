import { segmentResponse } from '../sitemap-data';

export function GET(): Response {
  return segmentResponse('local-hubs-0.xml');
}
