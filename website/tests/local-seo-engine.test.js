const fs = require('fs');
const assert = require('assert');

const catalog = JSON.parse(fs.readFileSync('data/france/catalog.json', 'utf8'));
const statuses = new Set(['disabled', 'hub', 'full']);
const problemSlugs = new Set(catalog.problems.map(problem => problem.slug));
const cities = catalog.cities;

assert.strictEqual(cities.length, 34875, 'The national COG catalogue must include every COM candidate');
assert.strictEqual(new Set(cities.map(city => city.inseeCode)).size, cities.length, 'INSEE codes must be unique');
assert.strictEqual(new Set(cities.map(city => city.urlSlug)).size, cities.length, 'City URL slugs must be unique');
assert(cities.every(city => /^(?:[0-9]{5}|2A[0-9]{3}|2B[0-9]{3})$/.test(city.inseeCode)), 'Every city must have a valid COG INSEE code');
assert(cities.every(city => statuses.has(city.seoStatus)), 'Every city must have an explicit SEO status');
assert(cities.every(city => city.professionalClaims === false), 'The catalog must not contain professional claims');
assert(cities.every(city => city.localClaims.length === 0), 'The catalog must not contain unverified local claims');
assert(cities.every(city => Array.isArray(city.neighborInseeCodes)), 'Neighbour relations must be explicit arrays');
assert(cities.every(city => city.activeProblems.every(slug => problemSlugs.has(slug))), 'Every active problem must exist in the central problem registry');
assert(cities.filter(city => city.seoStatus !== 'disabled').every(city => city.neighborInseeCodes.length >= 0), 'Published neighbours must be explicit');
assert(cities.filter(city => city.seoStatus === 'disabled').every(city => city.activeProblems.length === 0), 'Disabled COG candidates must not publish problems');

const expectedActiveCities = new Map([
  ['69123', 'lyon'],
  ['69266', 'villeurbanne'],
  ['69029', 'bron'],
  ['69259', 'venissieux'],
  ['69290', 'saint-priest'],
  ['69034', 'caluire-et-cuire'],
  ['06088', 'nice'],
]);
for (const [inseeCode, urlSlug] of expectedActiveCities) {
  const city = cities.find(candidate => candidate.inseeCode === inseeCode);
  assert(city, `Existing active city ${inseeCode} must remain in the catalog`);
  assert.notStrictEqual(city.seoStatus, 'disabled', `Existing active city ${inseeCode} must remain published`);
  assert.strictEqual(city.urlSlug, urlSlug, `Existing URL slug changed for ${inseeCode}`);
}
const saintPriestHomonyms = cities.filter(city => city.slug === 'saint-priest');
assert.deepStrictEqual(
  saintPriestHomonyms.map(city => [city.inseeCode, city.urlSlug]),
  [['07288', 'saint-priest-07'], ['23234', 'saint-priest-23'], ['69290', 'saint-priest']],
  'Historical Saint-Priest URL must win over new homonym disambiguation',
);

assert(catalog.source?.provider === 'INSEE', 'Catalog source must be INSEE');
assert(catalog.source?.cogVintage === '2026', 'Catalog must identify the COG 2026 millésime');
assert(catalog.importStats?.communeRows === cities.length, 'Import stats must match the candidate catalogue');

const publishedCities = cities.filter(city => city.seoStatus !== 'disabled');
const publishedProblems = cities.filter(city => city.seoStatus === 'full').flatMap(city => city.activeProblems.map(problem => `${city.urlSlug}/${problem}`));
assert.strictEqual(cities.filter(city => city.seoStatus === 'full').length, 7, 'Exactly the historical seven cities must remain full');
assert.strictEqual(cities.filter(city => city.seoStatus === 'hub').length, 34868, 'All other COG candidates must be hub-only');
assert.strictEqual(cities.filter(city => city.seoStatus === 'disabled').length, 0, 'No COG candidate should remain disabled after national hub activation');
assert.strictEqual(publishedCities.length, 34875, 'Every COG candidate must publish a hub');
assert.strictEqual(publishedProblems.length, 28, 'Published local problem pages must be explicit');
assert.strictEqual(publishedCities.length + publishedProblems.length, 34903, 'National local inventory must contain every hub plus the 28 historical problem pages');

const collisionFixture = [
  { slug: 'saint-priest', departmentCode: '69', urlSlug: 'saint-priest' },
  { slug: 'saint-priest', departmentCode: '07', urlSlug: 'saint-priest-07' },
];
assert.strictEqual(new Set(collisionFixture.map(city => city.slug)).size, 1, 'The fixture must represent a real slug collision');
assert(collisionFixture.every(city => city.urlSlug === city.slug || city.urlSlug === `${city.slug}-${city.departmentCode}`), 'Homonyms must use a stable department suffix');

const fakeProfessionalTokens = /LocalBusiness|Plumber|openingHours|priceRange|telephone|rating|review|availability/i;
assert(!fakeProfessionalTokens.test(JSON.stringify(catalog)), 'The local catalog must not contain professional schema or availability fields');
assert(catalog.problems.every(problem => problem.safetyProfile && problem.nationalGuideSlugs.length > 0), 'Every problem needs safety and national-guide metadata');

const publishedUrlHistory = JSON.parse(fs.readFileSync('data/france/published-url-history.json', 'utf8'));
for (const city of cities.filter(city => city.seoStatus === 'full')) {
  assert.strictEqual(city.urlSlug, publishedUrlHistory[city.inseeCode], `Published URL history changed for ${city.inseeCode}`);
}

console.log('local SEO engine checks passed');
