import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const mainInput = path.join(root, 'data/insee/population-2023/donnees_communes.csv');
const supplementInput = path.join(root, 'data/insee/population-2023/communes-speciales.csv');
const catalogInput = path.join(root, 'data/france/catalog.json');
const publishedOutput = path.join(root, 'app/data/france/published-catalog.json');
const reportOutput = path.join(root, 'data/insee/population-2023/import-report.json');
const rankingOutput = path.join(root, 'data/insee/population-2023/national-ranking.json');

const MAIN_SOURCE = 'https://www.insee.fr/fr/statistiques/8680726';
const MAIN_FILE = 'ensemble.zip / donnees_communes.csv';
const EFFECTIVE_DATE = '2026-01-01';

function parseCsv(text, delimiter = ';') {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1];
    if (char === '"' && quoted && next === '"') { field += '"'; index += 1; continue; }
    if (char === '"') { quoted = !quoted; continue; }
    if (char === delimiter && !quoted) { row.push(field); field = ''; continue; }
    if ((char === '\n' || char === '\r') && !quoted) {
      if (char === '\r' && next === '\n') index += 1;
      row.push(field); field = '';
      if (row.some(value => value !== '')) rows.push(row);
      row = [];
      continue;
    }
    field += char;
  }
  if (field || row.length) { row.push(field); if (row.some(value => value !== '')) rows.push(row); }
  const [header, ...body] = rows;
  return body.map(values => Object.fromEntries(header.map((key, index) => [key, values[index] ?? ''])));
}

function readCsv(file, delimiter = ';') { return parseCsv(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''), delimiter); }
function assertColumns(rows, columns, label) {
  const actual = rows[0] ? Object.keys(rows[0]) : [];
  for (const column of columns) if (!actual.includes(column)) throw new Error(`${label} missing required column ${column}`);
}
function integer(value, label) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) throw new Error(`Invalid non-negative population for ${label}: ${value}`);
  return parsed;
}
function writeJson(file, value) { fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`); }

const catalog = JSON.parse(fs.readFileSync(catalogInput, 'utf8'));
const mainRows = readCsv(mainInput);
const supplementRows = readCsv(supplementInput);
assertColumns(mainRows, ['COM', 'Commune', 'PMUN'], 'INSEE population CSV');
assertColumns(supplementRows, ['inseeCode', 'population', 'referenceYear', 'effectiveDate', 'source', 'sourceFile', 'geographyDate'], 'population supplement');

const byCode = new Map();
const duplicateCodes = [];
for (const row of mainRows) {
  const code = row.COM;
  if (byCode.has(code)) duplicateCodes.push(code);
  byCode.set(code, { value: integer(row.PMUN, code), referenceYear: 2023, effectiveDate: EFFECTIVE_DATE, source: MAIN_SOURCE, sourceFile: MAIN_FILE, geographyDate: '2025-01-01' });
}
for (const row of supplementRows) {
  if (byCode.has(row.inseeCode)) duplicateCodes.push(row.inseeCode);
  byCode.set(row.inseeCode, { value: integer(row.population, row.inseeCode), referenceYear: integer(row.referenceYear, row.inseeCode), effectiveDate: row.effectiveDate || null, source: row.source, sourceFile: row.sourceFile, geographyDate: row.geographyDate });
}
if (duplicateCodes.length) throw new Error(`Duplicate population codes: ${[...new Set(duplicateCodes)].join(', ')}`);

const catalogCodes = new Set(catalog.cities.map(city => city.inseeCode));
const mainCodes = new Set(mainRows.map(row => row.COM));
const supplementCodes = new Set(supplementRows.map(row => row.inseeCode));
const mainUnmatched = [...mainCodes].filter(code => !catalogCodes.has(code));
const catalogMissingBeforeSupplement = [...catalogCodes].filter(code => !mainCodes.has(code));
const populationByCode = new Map([...byCode].filter(([code]) => catalogCodes.has(code)));
const missingAfterSupplement = [...catalogCodes].filter(code => !populationByCode.has(code));
if (missingAfterSupplement.length) throw new Error(`No official population matched by INSEE code: ${missingAfterSupplement.join(', ')}`);

const cities = catalog.cities.map(city => ({ ...city, population: populationByCode.get(city.inseeCode) }));
const ranked = [...cities].sort((a, b) => b.population.value - a.population.value || a.inseeCode.localeCompare(b.inseeCode));
const rankByCode = new Map(ranked.map((city, index) => [city.inseeCode, index + 1]));
for (const city of cities) city.population = { ...city.population, rank: rankByCode.get(city.inseeCode) };
const waveForRank = rank => rank <= 100 ? 'WAVE_100' : rank <= 500 ? 'WAVE_500' : rank <= 1000 ? 'WAVE_1000' : rank <= 2500 ? 'WAVE_2500' : rank <= 5000 ? 'WAVE_5000' : rank <= 10000 ? 'WAVE_10000' : 'ALL';
const ranking = ranked.map((city, index) => ({ rank: index + 1, inseeCode: city.inseeCode, commune: city.displayName || city.name, departmentCode: city.departmentCode, department: city.departmentName, regionCode: city.regionCode, region: city.regionName, population: city.population.value, referenceYear: city.population.referenceYear, entryWave: waveForRank(index + 1) }));

const source = { provider: 'INSEE', cogVintage: '2026', populationReferenceYear: 2023, populationEffectiveDate: EFFECTIVE_DATE, mainPublication: 'https://www.insee.fr/fr/statistiques/8681011', mainDownload: MAIN_SOURCE, mainFile: MAIN_FILE, specialPublication: 'https://www.insee.fr/fr/statistiques/8643952', mayottePublication: 'https://www.insee.fr/fr/statistiques/3291775', populationImportedAt: new Date().toISOString() };
const report = { source, counts: { cogCommunes: catalog.cities.length, mainPopulationRows: mainRows.length, supplementRows: supplementRows.length, exactMatchesAfterSupplement: populationByCode.size, cogMissingFromMain: catalogMissingBeforeSupplement.length, mainRowsWithoutCogMatch: mainUnmatched.length, missingAfterSupplement: missingAfterSupplement.length, duplicatePopulationCodes: [...new Set(duplicateCodes)].length, populationReferenceYears: [...new Set(cities.map(city => city.population.referenceYear))] }, unmatched: { cogMissingFromMain: catalogMissingBeforeSupplement, mainRowsWithoutCogMatch: mainUnmatched }, outremers: { mayotteSupplementedCodes: supplementRows.filter(row => row.inseeCode.startsWith('976')).map(row => row.inseeCode), dromPopulationRowsInMain: mainRows.filter(row => /^(971|972|973|974)/.test(row.COM)).length }, ranking: { total: ranking.length, validPopulationCount: ranking.filter(row => row.population >= 0).length, tieBreaker: 'inseeCode ascending', missingPopulationStrategy: 'fail import; none missing after official supplements' } };
const enrichedCatalog = { ...catalog, source: { ...catalog.source, ...source, populationImported: true, populationSourceFile: 'data/insee/population-2023/donnees_communes.csv + communes-speciales.csv' }, cities };
writeJson(catalogInput, enrichedCatalog);
writeJson(publishedOutput, enrichedCatalog);
writeJson(rankingOutput, ranking);
writeJson(reportOutput, report);
console.log(JSON.stringify({ ...report.counts, ranking: ranking.slice(0, 30) }, null, 2));
