const fs=require('fs'); const assert=require('assert');
const layout=fs.readFileSync('app/layout.tsx','utf8');
const home=fs.readFileSync('app/page.tsx','utf8');
assert(layout.includes('NALVIUM')); assert(layout.includes('metadataBase')); assert(home.includes('NALVIUM'));
assert(!fs.existsSync('public/index.html'));
assert(fs.existsSync('app/sitemap.ts')===true);
for (const file of ['app/mentions-legales/page.tsx','app/confidentialite/page.tsx','app/cookies/page.tsx','app/cgu/page.tsx','app/suppression-compte/page.tsx']) {
  const legal = fs.readFileSync(file, 'utf8');
  assert(!/TODO|TBD|placeholder|example\.com|Lorem|à confirmer|a confirmer/i.test(legal), `${file} contains an unresolved public legal placeholder`);
  assert(legal.includes('contact@nalvium.com'), `${file} is missing the privacy contact`);
}
assert(fs.readFileSync('app/components.tsx', 'utf8').includes('/suppression-compte'));
const catalog=require('../content/catalog.json'); assert(catalog.problems.some(problem=>problem.indexable)); assert(catalog.cities.every(city=>city.covered===false || typeof city.covered==='boolean'));
console.log('website content checks passed');
