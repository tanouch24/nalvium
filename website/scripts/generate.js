const fs = require('fs');
const path = require('path');
const catalog = require('../content/catalog.json');
const indexableProblems = catalog.problems.filter(problem => problem.indexable);
const coveredCities = catalog.cities.filter(city => city.covered);
const pages = [...indexableProblems.map(problem => `/depannage/${problem.slug}/`), ...catalog.trades.flatMap(trade => coveredCities.map(city => `/${trade.slug}/${city.slug}/`))];
console.log(JSON.stringify({indexable_pages: pages, noindex_local_combinations: catalog.trades.length * (catalog.cities.length - coveredCities.length)}, null, 2));
