export const NATIONAL_PROBLEM_SLUGS = ['fuite-eau', 'wc-bouche', 'canalisation-bouchee'] as const;

export type ProblemRollout = 'WAVE_0' | 'TEST_WAVE' | 'WAVE_100' | 'WAVE_500' | 'WAVE_1000' | 'WAVE_2500' | 'WAVE_5000' | 'WAVE_10000' | 'ALL';

export const TEST_WAVE_INSEE_CODES = ['75056', '13055', '31555', '33063', '59350', '44109', '34172', '67482'] as const;

const rolloutModes = new Set<ProblemRollout>(['WAVE_0', 'TEST_WAVE', 'WAVE_100', 'WAVE_500', 'WAVE_1000', 'WAVE_2500', 'WAVE_5000', 'WAVE_10000', 'ALL']);

const populationWaveLimits: Record<Exclude<ProblemRollout, 'WAVE_0' | 'TEST_WAVE' | 'ALL'>, number> = {
  WAVE_100: 100,
  WAVE_500: 500,
  WAVE_1000: 1000,
  WAVE_2500: 2500,
  WAVE_5000: 5000,
  WAVE_10000: 10000,
};

export function problemRolloutFromEnvironment(environment: NodeJS.ProcessEnv = process.env): ProblemRollout {
  const value = environment.NALVIUM_PROBLEM_ROLLOUT;
  if (!value) return 'WAVE_0';
  if (!rolloutModes.has(value as ProblemRollout)) throw new Error(`Unknown NALVIUM_PROBLEM_ROLLOUT: ${value}`);
  if (value === 'TEST_WAVE' && environment.NODE_ENV === 'production') throw new Error('TEST_WAVE is development-only');
  return value as ProblemRollout;
}

export function populationWaveLimit(mode: ProblemRollout): number | null {
  if (mode === 'ALL') return Number.POSITIVE_INFINITY;
  if (mode === 'WAVE_0' || mode === 'TEST_WAVE') return null;
  return populationWaveLimits[mode];
}

export function isNationalProblemEnabled(inseeCode: string, populationRank: number | undefined, mode: ProblemRollout = problemRolloutFromEnvironment()): boolean {
  if (mode === 'ALL') return true;
  if (mode === 'TEST_WAVE') return TEST_WAVE_INSEE_CODES.includes(inseeCode as typeof TEST_WAVE_INSEE_CODES[number]);
  const limit = populationWaveLimit(mode);
  return limit !== null && populationRank !== undefined && populationRank <= limit;
}
