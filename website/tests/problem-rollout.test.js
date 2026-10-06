const assert = require('assert');
const fs = require('fs');

const catalog = JSON.parse(fs.readFileSync('data/france/catalog.json', 'utf8'));
const nationalProblems = ['fuite-eau', 'wc-bouche', 'canalisation-bouchee'];
const testWaveCodes = new Set(['75056', '13055', '31555', '33063', '59350', '44109', '34172', '67482']);
const limits = { WAVE_100: 100, WAVE_500: 500, WAVE_1000: 1000, WAVE_2500: 2500, WAVE_5000: 5000, WAVE_10000: 10000, ALL: Infinity };

assert.strictEqual(catalog.cities.length, 34875, 'COG catalog must contain 34,875 communes');
assert(catalog.cities.every(city => Number.isInteger(city.population?.value) && city.population.value >= 0), 'Population must be non-negative');
assert.strictEqual(new Set(catalog.cities.map(city => city.inseeCode)).size, catalog.cities.length, 'INSEE codes must be unique');
assert.strictEqual(new Set(catalog.cities.map(city => city.population.rank)).size, catalog.cities.length, 'Population ranks must be unique');

function problemPaths(mode) {
  return catalog.cities.filter(city => city.seoStatus !== 'disabled').flatMap(city => {
    const enabled = mode === 'ALL' || (mode === 'TEST_WAVE' && testWaveCodes.has(city.inseeCode)) || (limits[mode] !== undefined && city.population.rank <= limits[mode]);
    return [...new Set([...city.activeProblems, ...(enabled ? nationalProblems : [])])].map(problem => `${city.urlSlug}/${problem}`);
  });
}

const expected = { WAVE_0: 28, WAVE_100: 318, WAVE_500: 1509, WAVE_1000: 3009, WAVE_2500: 7509, WAVE_5000: 15009, WAVE_10000: 30009, ALL: 104634 };
for (const [mode, count] of Object.entries(expected)) {
  const paths = problemPaths(mode);
  assert.strictEqual(paths.length, count, `${mode} URL count changed`);
  assert.strictEqual(new Set(paths).size, paths.length, `${mode} must not contain duplicates`);
}
assert.strictEqual(problemPaths('TEST_WAVE').length, 52, 'TEST_WAVE must remain a development fixture');
assert(problemPaths('TEST_WAVE').includes('paris/fuite-eau'), 'TEST_WAVE must include Paris');
assert(!problemPaths('WAVE_0').includes('paris/fuite-eau'), 'WAVE_0 must not include Paris');
assert(!problemPaths('WAVE_0').includes('paris/robinet-qui-fuit'), 'WAVE_0 must not include unapproved problem slugs');

const rankedCodes = [...catalog.cities].sort((a, b) => a.population.rank - b.population.rank).map(city => city.inseeCode);
for (const [mode, limit] of Object.entries(limits)) {
  if (mode === 'ALL') continue;
  assert.deepStrictEqual(new Set(rankedCodes.slice(0, limit)), new Set(catalog.cities.filter(city => city.population.rank <= limit).map(city => city.inseeCode)), `${mode} is not the population prefix`);
}
assert(!problemPaths('ALL').some(path => path.startsWith('commune-inexistante/')), 'Unknown communes must never enter rollout output');

console.log('problem rollout checks passed');
