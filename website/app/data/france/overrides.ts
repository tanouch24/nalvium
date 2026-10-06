import { franceCities } from './index';

export type LocalEditorialOverride = {
  source: string;
  title?: string;
  description?: string;
  h1?: string;
  faqKey?: string;
  imageKey?: string;
};

export const localEditorialOverrides: Record<string, { hub: LocalEditorialOverride; problems: Record<string, LocalEditorialOverride> }> = Object.fromEntries(
  franceCities.filter(city => city.seoStatus !== 'disabled').map(city => [
    city.urlSlug,
    {
      hub: { source: city.editorialSource },
      problems: Object.fromEntries(city.activeProblems.map(problem => [problem, { source: city.editorialSource }])),
    },
  ]),
);

export function getLocalEditorialOverride(citySlug: string, problemSlug?: string): LocalEditorialOverride | undefined {
  const city = localEditorialOverrides[citySlug];
  return problemSlug ? city?.problems[problemSlug] : city?.hub;
}
