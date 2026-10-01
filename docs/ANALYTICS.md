# NALVIUM — ANALYTICS

## Objectif

Mesurer la valeur réelle, pas le temps passé artificiellement dans l’app.

## Événements

### Acquisition/onboarding
- app_opened
- onboarding_started
- onboarding_completed

### Site public / SEO
- seo_landing_viewed
- seo_cta_diagnostic_clicked
- seo_cta_pro_clicked
- app_store_clicked
- web_diagnostic_started

Propriétés non sensibles possibles : page_type, trade, city_slug, problem_slug, referrer_group.

### Diagnostic
- diagnostic_started
- photo_captured
- photo_uploaded
- analysis_started
- analysis_completed
- clarification_requested
- clarification_answered
- diagnostic_oriented

### Réparation
- diy_started
- repair_step_shown
- repair_step_completed
- additional_photo_sent
- repair_resolved
- repair_failed
- safety_stop

### Pro
- professional_recommended
- pro_flow_started
- lead_consent_viewed
- lead_consented
- lead_created
- lead_assigned
- lead_accepted

### Qualité
- feedback_submitted
- report_incorrect_guidance
- report_safety_issue

## Propriétés autorisées

Exemples :
- category
- risk_level
- step_count
- latency_bucket
- app_version
- locale

Ne pas envoyer :
- photo ;
- téléphone ;
- adresse précise ;
- description libre complète ;
- secret.

## Funnels principaux

1. Open → Diagnostic → Action utile
2. Diagnostic → DIY → Résolu
3. Diagnostic → Pro → Lead
4. Safety flag → Safety stop

## Cohortes

- plomberie
- électroménager
- bricolage
- version moteur IA
- version app
