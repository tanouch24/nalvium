export const NATIONAL_PROBLEM_SLUGS = ['fuite-eau', 'wc-bouche', 'canalisation-bouchee'] as const;

export type ProblemRollout = 'WAVE_0' | 'TEST_WAVE' | 'ALL';

export const TEST_WAVE_INSEE_CODES = ['75056', '13055', '31555', '33063', '59350', '44109', '34172', '67482'] as const;

const rolloutModes = new Set<ProblemRollout>(['WAVE_0', 'TEST_WAVE', 'ALL']);

export function problemRolloutFromEnvironment(environment: NodeJS.ProcessEnv = process.env): ProblemRollout {
  const value = environment.NALVIUM_PROBLEM_ROLLOUT;
  return value && rolloutModes.has(value as ProblemRollout) ? value as ProblemRollout : 'WAVE_0';
}

export function isNationalProblemEnabled(inseeCode: string, mode: ProblemRollout = problemRolloutFromEnvironment()): boolean {
  if (mode === 'ALL') return true;
  if (mode === 'TEST_WAVE') return TEST_WAVE_INSEE_CODES.includes(inseeCode as typeof TEST_WAVE_INSEE_CODES[number]);
  return false;
}
