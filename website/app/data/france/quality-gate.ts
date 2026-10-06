type FranceCityRecord = {
  inseeCode: string;
  slug: string;
  urlSlug: string;
  name: string;
  departmentCode: string;
  regionCode: string;
  sourceUrl: string;
  seoStatus: string;
  nationalProblems: string[];
  activeProblems: string[];
  professionalClaims: boolean;
  localClaims: string[];
  neighborInseeCodes: string[];
  population?: { value: number; rank?: number; referenceYear: number; source: string };
};

type FranceProblemRecord = {
  slug: string;
  intent: string;
  label: string;
  safetyProfile: string;
  metadataKey: string;
};

const statuses = new Set(['disabled', 'hub', 'full']);

export function validateFranceSeoCatalog(cities: FranceCityRecord[], problems: FranceProblemRecord[]): string[] {
  const errors: string[] = [];
  const inseeCodes = new Set<string>();
  const urlSlugs = new Map<string, FranceCityRecord[]>();
  const problemSlugs = new Set<string>();

  for (const problem of problems) {
    if (!problem.slug || problemSlugs.has(problem.slug)) errors.push(`Duplicate or empty problem slug: ${problem.slug}`);
    problemSlugs.add(problem.slug);
    if (!problem.intent || !problem.label || !problem.safetyProfile || !problem.metadataKey) errors.push(`Incomplete problem registry entry: ${problem.slug}`);
  }

  for (const city of cities) {
    if (!/^(?:[0-9]{5}|2A[0-9]{3}|2B[0-9]{3})$/.test(city.inseeCode)) errors.push(`Invalid INSEE code: ${city.inseeCode}`);
    if (inseeCodes.has(city.inseeCode)) errors.push(`Duplicate INSEE code: ${city.inseeCode}`);
    inseeCodes.add(city.inseeCode);
    if (!city.slug || !city.urlSlug || !city.name || !city.departmentCode || !city.regionCode || !city.sourceUrl) errors.push(`Incomplete city record: ${city.inseeCode}`);
    if (!statuses.has(city.seoStatus)) errors.push(`Invalid SEO status for ${city.inseeCode}: ${city.seoStatus}`);
    if (city.nationalProblems.length !== 3 || !city.nationalProblems.includes('fuite-eau') || !city.nationalProblems.includes('wc-bouche') || !city.nationalProblems.includes('canalisation-bouchee')) errors.push(`National problem coverage is incomplete: ${city.inseeCode}`);
    if (city.seoStatus === 'disabled' && city.activeProblems.length > 0) errors.push(`Disabled city has active problems: ${city.inseeCode}`);
    if (city.seoStatus === 'hub' && city.activeProblems.length > 0) errors.push(`Hub-only city has active problem pages: ${city.inseeCode}`);
    if (city.seoStatus === 'full' && city.activeProblems.length === 0) errors.push(`Full city has no active problems: ${city.inseeCode}`);
    if (city.professionalClaims !== false) errors.push(`Professional claims must be false: ${city.inseeCode}`);
    if (city.localClaims.length > 0) errors.push(`Unverified local claims found: ${city.inseeCode}`);
    const population = city.population;
    if (!population || !Number.isInteger(population.value) || population.value < 0 || !Number.isInteger(population.rank) || (population.rank ?? 0) < 1 || !population.source) errors.push(`Invalid official population metadata: ${city.inseeCode}`);
    for (const problemSlug of [...city.nationalProblems, ...city.activeProblems]) if (!problemSlugs.has(problemSlug)) errors.push(`Unknown active problem ${problemSlug} on ${city.inseeCode}`);
    const sameSlug = urlSlugs.get(city.slug) ?? [];
    sameSlug.push(city);
    urlSlugs.set(city.slug, sameSlug);
  }

  for (const city of cities) {
    for (const neighborInseeCode of city.neighborInseeCodes) {
      if (neighborInseeCode === city.inseeCode || !inseeCodes.has(neighborInseeCode)) errors.push(`Invalid neighbour reference ${neighborInseeCode} on ${city.inseeCode}`);
    }
  }

  urlSlugs.forEach((matches, slug) => {
    if (matches.length > 1) {
      const historicalBaseCount = matches.filter(city => city.urlSlug === slug).length;
      const expected = historicalBaseCount <= 1 && matches.every(city =>
        city.urlSlug === slug ||
        city.urlSlug === `${slug}-${city.departmentCode.replace(/[^a-z0-9]/gi, '').toLowerCase()}` ||
        city.urlSlug === `${slug}-${city.inseeCode.toLowerCase()}`,
      );
      if (!expected) errors.push(`Slug collision requires department disambiguation: ${slug}`);
    }
  });
  const uniqueUrlSlugs = new Set(cities.map(city => city.urlSlug));
  if (uniqueUrlSlugs.size !== cities.length) errors.push('Every city must have a unique urlSlug');
  return errors;
}

export function assertLocalPageQuality(input: { city: FranceCityRecord; problem?: FranceProblemRecord; title: string; description: string; h1: string; canonical: string; hasSafety: boolean; hasCta: boolean; usefulLinks: number; hasFalseProfessionalData: boolean }): void {
  const errors = [
    input.city.seoStatus === 'disabled' ? 'city is disabled' : '',
    input.problem && !input.city.activeProblems.includes(input.problem.slug) && !input.city.nationalProblems.includes(input.problem.slug) ? 'problem is not activated for city' : '',
    input.title.length < 20 ? 'title is too short' : '',
    input.description.length < 60 ? 'description is too short' : '',
    input.h1.length < 10 ? 'H1 is too short' : '',
    !input.canonical.startsWith('https://nalvium.com/') ? 'canonical is not absolute nalvium.com' : '',
    !input.hasSafety ? 'safety section missing' : '',
    !input.hasCta ? 'NALVIUM CTA missing' : '',
    input.usefulLinks < 1 ? 'useful links missing' : '',
    input.hasFalseProfessionalData ? 'false professional data present' : '',
  ].filter(Boolean);
  if (errors.length > 0) throw new Error(`Local SEO quality gate failed for ${input.city.inseeCode}: ${errors.join(', ')}`);
}
