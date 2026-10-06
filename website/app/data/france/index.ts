import rawCatalog from './published-catalog.json';
import { assertLocalPageQuality, validateFranceSeoCatalog } from './quality-gate';

export type SeoPublicationStatus = 'disabled' | 'hub' | 'full';
export type FranceProblemRecord = (typeof rawCatalog.problems)[number];
export type FranceCityRecord = (typeof rawCatalog.cities)[number] & { seoStatus: SeoPublicationStatus };

export const franceProblems = rawCatalog.problems as FranceProblemRecord[];
export const franceCities = rawCatalog.cities as FranceCityRecord[];

const catalogErrors = validateFranceSeoCatalog(franceCities, franceProblems);
if (catalogErrors.length > 0) throw new Error(`France SEO catalog invalid:\n${catalogErrors.join('\n')}`);

const citiesByUrlSlug = new Map(franceCities.map(city => [city.urlSlug, city]));
const problemsBySlug = new Map(franceProblems.map(problem => [problem.slug, problem]));

export function getFranceCity(urlSlug: string): FranceCityRecord | undefined { return citiesByUrlSlug.get(urlSlug); }
export function getFranceProblem(slug: string): FranceProblemRecord | undefined { return problemsBySlug.get(slug); }
export function isPublishedCity(urlSlug: string): boolean { const city = getFranceCity(urlSlug); return Boolean(city && city.seoStatus !== 'disabled'); }
export function isPublishedProblem(citySlug: string, problemSlug: string): boolean { const city = getFranceCity(citySlug); return Boolean(city && city.seoStatus === 'full' && city.activeProblems.includes(problemSlug)); }
export function publishedCitySlugs(): string[] { return franceCities.filter(city => city.seoStatus !== 'disabled').map(city => city.urlSlug); }
export function publishedLocalProblemParams(): { city: string; problem: string }[] { return franceCities.filter(city => city.seoStatus === 'full').flatMap(city => city.activeProblems.map(problem => ({ city: city.urlSlug, problem }))); }
export function publishedLocalHubPaths(): string[] { return publishedCitySlugs().map(city => `/plombier/${city}`); }
export function publishedLocalProblemPaths(): string[] { return publishedLocalProblemParams().map(({ city, problem }) => `/plombier/${city}/${problem}`); }
export function cityUrlSlug(city: FranceCityRecord): string { return city.urlSlug; }

export { assertLocalPageQuality };
