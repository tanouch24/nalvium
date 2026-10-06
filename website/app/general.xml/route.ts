import { segmentResponse } from '../sitemap-data';

export function GET(): Response {
  return segmentResponse('general.xml');
}
