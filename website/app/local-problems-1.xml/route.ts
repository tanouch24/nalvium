import { segmentResponse } from '../sitemap-data';

export function GET(): Response {
  return segmentResponse('local-problems-1.xml');
}
