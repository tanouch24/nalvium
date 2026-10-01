export type PublicEvent = 'cta_app_click' | 'guide_view' | 'local_service_page_view' | 'diagnostic_cta_click' | 'professional_cta_click';

// Intentionally a no-op until an analytics provider is selected.
// Keep properties limited to non-sensitive context: never pass photos, phone numbers,
// precise addresses, or full free-text problem descriptions here.
export function trackPublicEvent(event: PublicEvent, properties: Record<string, string | undefined> = {}) {
  if (typeof window === 'undefined') return;
  window.dispatchEvent(new CustomEvent('nalvium:analytics', { detail: { event, properties } }));
}
