const assert = require('assert');
const fs = require('fs');

const catalog = JSON.parse(fs.readFileSync('data/france/catalog.json', 'utf8'));
const nationalProblems = ['fuite-eau', 'wc-bouche', 'canalisation-bouchee'];
const testWaveCodes = new Set(['75056', '13055', '31555', '33063', '59350', '44109', '34172', '67482']);

function problemPaths(mode) {
  return catalog.cities.filter(city => city.seoStatus !== 'disabled').flatMap(city => {
    const enabled = mode === 'ALL' || (mode === 'TEST_WAVE' && testWaveCodes.has(city.inseeCode));
    return [...new Set([...city.activeProblems, ...(enabled ? nationalProblems : [])])].map(problem => `${city.urlSlug}/${problem}`);
  });
}

const wave0 = problemPaths('WAVE_0');
const testWave = problemPaths('TEST_WAVE');
const all = problemPaths('ALL');

assert.strictEqual(wave0.length, 28, 'WAVE_0 must preserve only historical problem URLs');
assert.strictEqual(new Set(wave0).size, wave0.length, 'WAVE_0 must not contain duplicates');
assert.strictEqual(testWave.length, 52, 'TEST_WAVE must add three problems for eight test communes');
assert.strictEqual(all.length, 104634, 'ALL must expose the deduplicated national problem inventory');
assert.strictEqual(new Set(all).size, all.length, 'ALL must not contain duplicates');
assert(testWave.includes('paris/fuite-eau'), 'TEST_WAVE must include Paris');
assert(!wave0.includes('paris/fuite-eau'), 'WAVE_0 must not include Paris');
assert(!wave0.includes('paris/robinet-qui-fuit'), 'WAVE_0 must not include unapproved problem slugs');
assert(!all.includes('commune-inexistante/fuite-eau'), 'Unknown communes must never enter rollout output');

console.log('problem rollout checks passed');
