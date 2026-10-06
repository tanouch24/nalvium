import { segmentResponse } from '../sitemap-data';

export function GET(): Response {
  return segmentResponse('local-problems-2.xml');
}
