const fs=require('fs'); const assert=require('assert');
const home=fs.readFileSync('public/index.html','utf8');
assert(home.includes('NALVIUM')); assert(home.includes('canonical')); assert(home.includes('Prendre une photo'));
assert(fs.existsSync('public/sitemap.xml')===true);
const catalog=require('../content/catalog.json'); assert(catalog.problems.some(problem=>problem.indexable)); assert(catalog.cities.every(city=>city.covered===false || typeof city.covered==='boolean'));
console.log('website content checks passed');
