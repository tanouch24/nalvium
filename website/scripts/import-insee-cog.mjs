#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const SOURCE_PAGE = 'https://www.insee.fr/fr/information/8740222';
const DEFAULT_INPUT = 'data/insee/cog-2026/v_commune_2026.csv';
const DEFAULT_DEPARTMENTS = 'data/insee/cog-2026/v_departement_2026.csv';
const DEFAULT_REGIONS = 'data/insee/cog-2026/v_region_2026.csv';
const DEFAULT_OUTPUT = 'data/france/catalog.json';
const DEFAULT_PUBLISHED_OUTPUT = 'app/data/france/published-catalog.json';
const DEFAULT_HISTORY = 'data/france/published-url-history.json';
const DEFAULT_REPORT = 'data/insee/cog-2026/import-report.json';
const REQUIRED_COMMUNE_COLUMNS = ['TYPECOM', 'COM', 'REG', 'DEP', 'CTCD', 'ARR', 'TNCC', 'NCC', 'NCCENR', 'LIBELLE', 'CAN', 'COMPARENT'];

function option(name, fallback) {
  const index = process.argv.indexOf(`--${name}`);
  return index === -1 ? fallback : process.argv[index + 1];
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = '';
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1];
    if (quoted && char === '"' && next === '"') { value += '"'; index += 1; continue; }
    if (char === '"') { quoted = !quoted; continue; }
    if (!quoted && char === ',') { row.push(value); value = ''; continue; }
    if (!quoted && (char === '\n' || char === '\r')) {
      if (char === '\r' && next === '\n') index += 1;
      row.push(value); value = '';
      if (row.some(cell => cell !== '')) rows.push(row);
      row = [];
      continue;
    }
    value += char;
  }
  if (value.length > 0 || row.length > 0) { row.push(value); rows.push(row); }
  const headers = rows.shift().map(header => header.replace(/^\uFEFF/, ''));
  return rows.map(cells => Object.fromEntries(headers.map((header, index) => [header, cells[index] ?? ''])));
}

function readCsv(file) { return parseCsv(fs.readFileSync(file, 'utf8')); }

function slugify(value) {
  return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[’']/g, '-').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').replace(/-+/g, '-');
}

function ensureColumns(rows, required, file) {
  const actual = Object.keys(rows[0] ?? {});
  const missing = required.filter(column => !actual.includes(column));
  if (missing.length > 0) throw new Error(`${file} is missing columns: ${missing.join(', ')}`);
}

function indexBy(rows, key) { return new Map(rows.map(row => [row[key], row])); }

function resolveUrlSlugs(rows) {
  const groups = new Map();
  for (const row of rows) groups.set(row.slug, [...(groups.get(row.slug) ?? []), row]);
  const collisionGroups = [...groups.values()].filter(group => group.length > 1);
  const used = new Set(rows.filter(row => row.urlSlugLocked).map(row => row.urlSlug));
  for (const row of rows) {
    if (row.urlSlugLocked) continue;
    const group = groups.get(row.slug);
    const departmentSuffix = row.departmentCode.replace(/[^a-z0-9]/gi, '').toLowerCase();
    let urlSlug = group.length === 1 ? row.slug : `${row.slug}-${departmentSuffix}`;
    if (used.has(urlSlug)) urlSlug = `${row.slug}-${row.inseeCode}`;
    if (used.has(urlSlug)) throw new Error(`Unable to resolve urlSlug collision for ${row.inseeCode}`);
    row.urlSlug = urlSlug;
    used.add(urlSlug);
  }
  return collisionGroups;
}

const input = option('input', DEFAULT_INPUT);
const departmentsFile = option('departments', DEFAULT_DEPARTMENTS);
const regionsFile = option('regions', DEFAULT_REGIONS);
const output = option('output', DEFAULT_OUTPUT);
const publishedOutput = option('published-output', DEFAULT_PUBLISHED_OUTPUT);
const reportFile = option('report', DEFAULT_REPORT);
const existingFile = option('existing', DEFAULT_OUTPUT);
const historyFile = option('history', DEFAULT_HISTORY);

const communeRows = readCsv(input);
const departmentRows = readCsv(departmentsFile);
const regionRows = readCsv(regionsFile);
ensureColumns(communeRows, REQUIRED_COMMUNE_COLUMNS, input);
ensureColumns(departmentRows, ['DEP', 'REG', 'LIBELLE'], departmentsFile);
ensureColumns(regionRows, ['REG', 'LIBELLE'], regionsFile);

const typeCounts = Object.fromEntries([...new Set(communeRows.map(row => row.TYPECOM))].map(type => [type, communeRows.filter(row => row.TYPECOM === type).length]));
const communeRowsOnly = communeRows.filter(row => row.TYPECOM === 'COM');
const departmentByCode = indexBy(departmentRows, 'DEP');
const regionByCode = indexBy(regionRows, 'REG');

for (const row of communeRowsOnly) {
  if (!/^(?:\d{5}|2A\d{3}|2B\d{3})$/.test(row.COM)) {
    throw new Error(`Invalid COM code: ${row.COM}`);
  }
  if (!departmentByCode.has(row.DEP)) throw new Error(`Unknown department code ${row.DEP} for ${row.COM}`);
  if (!regionByCode.has(row.REG)) throw new Error(`Unknown region code ${row.REG} for ${row.COM}`);
  if (!row.NCCENR && !row.LIBELLE) throw new Error(`Missing commune name for ${row.COM}`);
}

const existing = fs.existsSync(existingFile) ? JSON.parse(fs.readFileSync(existingFile, 'utf8')) : { problems: [] };
const publishedUrlHistory = fs.existsSync(historyFile) ? JSON.parse(fs.readFileSync(historyFile, 'utf8')) : {};
const existingByInsee = new Map((existing.cities ?? []).map(city => [city.inseeCode, city]));
const baseCities = communeRowsOnly.map(row => {
  const department = departmentByCode.get(row.DEP);
  const region = regionByCode.get(row.REG);
  const name = row.NCCENR || row.LIBELLE;
  const generated = {
    inseeCode: row.COM,
    name,
    displayName: row.LIBELLE || name,
    slug: slugify(name),
    urlSlug: slugify(name),
    departmentCode: row.DEP,
    departmentName: department.NCCENR || department.LIBELLE,
    regionCode: row.REG,
    regionName: region.NCCENR || region.LIBELLE,
    typecom: row.TYPECOM,
    seoStatus: 'disabled',
    activeProblems: [],
    neighborInseeCodes: [],
    relatedCityInseeCodes: [],
    sourceUrl: SOURCE_PAGE,
    editorialSource: 'cog-2026',
    localClaims: [],
    professionalClaims: false,
  };
  const previous = existingByInsee.get(row.COM);
  if (!previous || previous.seoStatus === 'disabled') {
    if (publishedUrlHistory[row.COM]) return { ...generated, urlSlug: publishedUrlHistory[row.COM], urlSlugLocked: true };
    return generated;
  }
  return { ...generated, ...previous, inseeCode: row.COM, name, displayName: row.LIBELLE || name, departmentCode: row.DEP, departmentName: generated.departmentName, regionCode: row.REG, regionName: generated.regionName, typecom: row.TYPECOM, sourceUrl: previous.sourceUrl || SOURCE_PAGE, ...(publishedUrlHistory[row.COM] ? { urlSlug: publishedUrlHistory[row.COM], urlSlugLocked: true } : { urlSlugLocked: true }) };
});

const collisions = resolveUrlSlugs(baseCities);
const collisionReport = collisions.map(group => ({ baseSlug: group[0].slug, communes: group.map(row => ({ inseeCode: row.inseeCode, name: row.name, departmentCode: row.departmentCode, urlSlug: row.urlSlug })) }));
for (const city of baseCities) delete city.urlSlugLocked;
const catalog = { source: { provider: 'INSEE', page: SOURCE_PAGE, dataset: 'Code officiel géographique au 1er janvier 2026', cogVintage: '2026', communeFile: path.basename(input), departmentFile: path.basename(departmentsFile), regionFile: path.basename(regionsFile), importedAt: new Date().toISOString(), populationImported: false }, importStats: { sourceRows: communeRows.length, communeRows: communeRowsOnly.length, typeCounts, collisionCount: collisionReport.length, ignoredTypes: Object.fromEntries(Object.entries(typeCounts).filter(([type]) => type !== 'COM')) }, cities: baseCities, problems: existing.problems ?? [] };

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, `${JSON.stringify(catalog, null, 2)}\n`);
const publishedCatalog = { ...catalog, cities: baseCities.filter(city => city.seoStatus !== 'disabled') };
fs.writeFileSync(publishedOutput, `${JSON.stringify(publishedCatalog, null, 2)}\n`);
fs.mkdirSync(path.dirname(reportFile), { recursive: true });
const report = { ...catalog.source, sourceRows: communeRows.length, communeRows: communeRowsOnly.length, typeCounts, ignoredTypes: catalog.importStats.ignoredTypes, finalCandidateCount: baseCities.length, collisionCount: collisionReport.length, collisions: collisionReport, activeCitiesPreserved: baseCities.filter(city => city.seoStatus !== 'disabled').map(city => ({ inseeCode: city.inseeCode, name: city.name, urlSlug: city.urlSlug, seoStatus: city.seoStatus, activeProblems: city.activeProblems })) };
fs.writeFileSync(reportFile, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
