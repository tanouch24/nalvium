import { assertLocalPageQuality, validateFranceSeoCatalog } from './quality-gate';
import { isNationalProblemEnabled, NATIONAL_PROBLEM_SLUGS, problemRolloutFromEnvironment, type ProblemRollout } from './rollout';

export type SeoPublicationStatus = 'disabled' | 'hub' | 'full';
export type FranceProblemRecord = { slug: string; intent: string; label: string; safetyProfile: string; metadataKey: string };
export type FranceCityRecord = {
  inseeCode: string;
  name: string;
  displayName?: string;
  slug: string;
  urlSlug: string;
  departmentCode: string;
  departmentName?: string;
  regionCode: string;
  regionName?: string;
  typecom?: string;
  seoStatus: SeoPublicationStatus;
  nationalProblems: string[];
  activeProblems: string[];
  neighborInseeCodes: string[];
  relatedCityInseeCodes?: string[];
  sourceUrl: string;
  editorialSource?: string;
  localClaims: string[];
  professionalClaims: boolean;
  population?: { value: number; referenceYear: number; effectiveDate: string | null; source: string; sourceFile: string; geographyDate: string; rank: number };
};
type FranceCatalog = { problems: FranceProblemRecord[]; cities: FranceCityRecord[]; source: Record<string, unknown> };
// Keep the 34,875-record catalog's type surface explicit so TypeScript does not infer a giant JSON literal.
const rawCatalog = require('./published-catalog.json') as FranceCatalog;

export const franceProblems = rawCatalog.problems as FranceProblemRecord[];
export const franceCities = rawCatalog.cities as FranceCityRecord[];

const catalogErrors = validateFranceSeoCatalog(franceCities, franceProblems);
if (catalogErrors.length > 0) throw new Error(`France SEO catalog invalid:\n${catalogErrors.join('\n')}`);

const citiesByUrlSlug = new Map(franceCities.map(city => [city.urlSlug, city]));
const problemsBySlug = new Map(franceProblems.map(problem => [problem.slug, problem]));

export function getFranceCity(urlSlug: string): FranceCityRecord | undefined { return citiesByUrlSlug.get(urlSlug); }
export function getFranceProblem(slug: string): FranceProblemRecord | undefined { return problemsBySlug.get(slug); }
export function isPublishedCity(urlSlug: string): boolean { const city = getFranceCity(urlSlug); return Boolean(city && city.seoStatus !== 'disabled'); }
export function isPublishedProblem(citySlug: string, problemSlug: string, mode: ProblemRollout = problemRolloutFromEnvironment()): boolean { const city = getFranceCity(citySlug); return Boolean(city && city.seoStatus !== 'disabled' && (city.activeProblems.includes(problemSlug) || (NATIONAL_PROBLEM_SLUGS.includes(problemSlug as typeof NATIONAL_PROBLEM_SLUGS[number]) && city.nationalProblems.includes(problemSlug) && isNationalProblemEnabled(city.inseeCode, city.population?.rank, mode)))); }
export function publishedCitySlugs(): string[] { return franceCities.filter(city => city.seoStatus !== 'disabled').map(city => city.urlSlug); }
export function preRenderedCitySlugs(): string[] { return franceCities.filter(city => city.seoStatus === 'full').map(city => city.urlSlug); }
export function localProblemSlugs(city: FranceCityRecord, mode: ProblemRollout = problemRolloutFromEnvironment()): string[] { const national = isNationalProblemEnabled(city.inseeCode, city.population?.rank, mode) ? city.nationalProblems : []; return Array.from(new Set([...national, ...city.activeProblems])); }
export function preRenderedLocalProblemParams(): { city: string; problem: string }[] { return franceCities.filter(city => city.seoStatus === 'full').flatMap(city => city.activeProblems.map(problem => ({ city: city.urlSlug, problem }))); }
export function publishedLocalProblemParams(mode: ProblemRollout = problemRolloutFromEnvironment()): { city: string; problem: string }[] { return franceCities.filter(city => city.seoStatus !== 'disabled').flatMap(city => localProblemSlugs(city, mode).map(problem => ({ city: city.urlSlug, problem }))); }
export function publishedLocalHubPaths(): string[] { return publishedCitySlugs().map(city => `/plombier/${city}`); }
export function publishedLocalProblemPaths(mode: ProblemRollout = problemRolloutFromEnvironment()): string[] { return publishedLocalProblemParams(mode).map(({ city, problem }) => `/plombier/${city}/${problem}`); }
export function cityUrlSlug(city: FranceCityRecord): string { return city.urlSlug; }

export { assertLocalPageQuality };
