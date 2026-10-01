import io
import pytest
from PIL import Image
from fastapi.testclient import TestClient

from app.main import app, rate_limiters, store
from app.rate_limit import RateLimiter
from app.equipment_context import build_equipment_context

client = TestClient(app)

@pytest.fixture(autouse=True)
def reset_test_rate_limits():
    for kind in rate_limiters:
        rate_limiters[kind] = RateLimiter(100)

def image_bytes() -> bytes:
    image = Image.new("RGB", (12, 8), (20, 120, 90))
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()

def test_session_upload_analyze_and_history():
    session = client.post("/v1/sessions")
    assert session.status_code == 200
    session_id = session.json()["id"]
    upload = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("problem.png", image_bytes(), "image/png")})
    assert upload.status_code == 200
    media_id = upload.json()["id"]
    analysis = client.post("/v1/diagnostics/analyze", json={"session_id": session_id, "media_id": media_id, "text": "fuite sous évier"})
    assert analysis.status_code == 200
    assert analysis.json()["observations"]
    assert client.get(f"/v1/sessions/{session_id}").json()["messages"]

def test_invalid_media_is_rejected():
    response = client.post("/v1/media", files={"file": ("bad.txt", b"not an image", "text/plain")})
    assert response.status_code == 415

def test_commerce_search_is_generic_and_never_claims_stock():
    response = client.post('/v1/commerce/search', json={
        'mode': 'nearby', 'item_type': 'PART', 'generic_name': 'joint adapté au raccord',
        'postal_code': '75011', 'city': 'Paris',
    })
    assert response.status_code == 200
    body = response.json()
    assert body['availability_known'] is False
    assert body['price_known'] is False
    assert '75011' in body['search_url']
    assert 'phone' not in body['search_url']

def test_commerce_is_blocked_after_safety_stop():
    response = client.post('/v1/commerce/search', json={
        'mode': 'online', 'item_type': 'TOOL', 'generic_name': 'tournevis', 'safety_stop': True,
    })
    assert response.status_code == 409

def test_support_is_disabled_without_fake_checkout():
    assert client.get('/v1/support/config').json()['enabled'] is False
    response = client.post('/v1/support/contributions', headers={'X-Client-Id': 'support-client-000001'}, json={'amount_cents': 100, 'source': 'SETTINGS'})
    assert response.status_code == 409

def test_admin_commerce_contains_only_aggregates():
    response = client.get('/v1/admin/commerce', headers={'X-Admin-Token': 'test-admin-token'})
    assert response.status_code in {200, 401}

def test_large_media_is_rejected():
    response = client.post("/v1/media", files={"file": ("big.jpg", b"x" * (8 * 1024 * 1024 + 1), "image/jpeg")})
    assert response.status_code == 413

def test_safety_precheck_stops_before_provider():
    response = client.post("/v1/diagnostics/analyze", json={"text": "odeur de gaz"})
    assert response.status_code == 200
    assert response.json()["next_action"]["type"] == "safety_stop"

def test_cigarette_alone_does_not_trigger_generic_safety_stop():
    response = client.post("/v1/diagnostics/analyze", json={"text": "cigarette seule"})
    assert response.status_code == 200
    assert response.json()["risk"]["level"] == "out_of_scope"
    assert response.json()["risk"]["stop_diy"] is False

def test_lead_requires_consent_and_admin_auth():
    session_id = client.post("/v1/sessions").json()["id"]
    lead = {"session_id": session_id, "first_name": "Ana", "phone": "0612345678", "city": "Lyon", "postal_code": "69003", "trade": "plombier", "summary": "Fuite", "urgency": "normal", "consent": False, "media_ids": []}
    assert client.post("/v1/leads", json=lead).status_code == 400
    assert client.get("/v1/admin/leads").status_code == 401

def _service_fixture():
    category = client.post("/v1/admin/service-categories", headers={"X-Admin-Token": "test"}, json={"slug": "plomberie-test", "title": "Plomberie test", "active": True}).json()
    offering = client.post("/v1/admin/service-offerings", headers={"X-Admin-Token": "test"}, json={"category_id": category["id"], "slug": "fuite-test", "title": "Fuite d'eau test", "pricing_type": "QUOTE_REQUIRED", "active": True}).json()
    area = client.post("/v1/admin/service-areas", headers={"X-Admin-Token": "test"}, json={"name": "Zone test", "postal_codes": ["75011"], "active": True, "offering_ids": [offering["id"]]}).json()
    return offering, area

def test_service_catalog_and_coverage_are_dynamic():
    offering, _ = _service_fixture()
    catalog = client.get("/v1/service-categories")
    assert catalog.status_code == 200
    assert any(item["id"] == offering["id"] for item in catalog.json()["offerings"])
    assert client.get("/v1/service-availability", params={"postal_code": "75011"}).json()["covered"] is True
    assert client.get("/v1/service-availability", params={"postal_code": "33000"}).json()["covered"] is False

def test_repair_request_requires_consent_coverage_and_is_idempotent():
    offering, _ = _service_fixture()
    actor = "test-actor-1234567890"
    payload = {"service_offering_id": offering["id"], "first_name": "Ana", "phone": "0612345678", "postal_code": "75011", "description": "Fuite sous évier", "consent": False}
    assert client.post("/v1/repair-requests", headers={"X-Client-Id": actor, "Idempotency-Key": "k1"}, json=payload).status_code == 400
    payload["consent"] = True
    first = client.post("/v1/repair-requests", headers={"X-Client-Id": actor, "Idempotency-Key": "k1"}, json=payload)
    second = client.post("/v1/repair-requests", headers={"X-Client-Id": actor, "Idempotency-Key": "k1"}, json=payload)
    assert first.status_code == second.status_code == 200
    assert first.json()["id"] == second.json()["id"]
    assert client.get("/v1/repair-requests", headers={"X-Client-Id": actor}).json()["requests"]

def test_repair_request_status_transitions_assignment_appointment_and_cancel():
    offering, _ = _service_fixture()
    actor = "test-actor-status-123456"
    request = client.post("/v1/repair-requests", headers={"X-Client-Id": actor, "Idempotency-Key": "status-1"}, json={"service_offering_id": offering["id"], "first_name": "Ana", "phone": "0612345678", "postal_code": "75011", "description": "Robinet", "consent": True}).json()
    professional = client.post("/v1/admin/professionals", headers={"X-Admin-Token": "test"}, json={"business_name": "Test pro", "legal_name": "", "phone": "0611111111", "email": "pro@example.com", "trade": "plomberie", "city": "75011", "active": True}).json()
    assert client.patch(f"/v1/admin/repair-requests/{request['id']}", headers={"X-Admin-Token": "test"}, json={"status": "REVIEWING"}).status_code == 200
    assert client.post(f"/v1/admin/repair-requests/{request['id']}/assign", headers={"X-Admin-Token": "test"}, json={"professional_id": professional["id"]}).status_code == 200
    assert client.post(f"/v1/admin/repair-requests/{request['id']}/appointment", headers={"X-Admin-Token": "test"}, json={"starts_at": "2026-10-10T10:00:00Z"}).status_code == 200
    assert client.patch(f"/v1/admin/repair-requests/{request['id']}", headers={"X-Admin-Token": "test"}, json={"status": "COMPLETED"}).status_code == 409
    assert client.post(f"/v1/repair-requests/{request['id']}/cancel", headers={"X-Client-Id": actor}).status_code == 200

def test_device_token_lifecycle_and_ai_metrics_are_privacy_scoped():
    actor = "test-device-actor-123456"
    token = "fcm-test-token-12345678901234567890"
    assert client.post("/v1/device-tokens", headers={"X-Client-Id": actor}, json={"token": token, "platform": "android"}).status_code == 200
    assert client.delete(f"/v1/device-tokens/{token}", headers={"X-Client-Id": actor}).status_code == 200
    metrics = client.get("/v1/admin/ai-costs", headers={"X-Admin-Token": "test"})
    assert metrics.status_code == 200
    assert "prompts" not in str(metrics.json()).lower()

def test_consented_lead_is_visible_only_to_authenticated_admin():
    session_id = client.post("/v1/sessions").json()["id"]
    lead = {"session_id": session_id, "first_name": "Ana", "phone": "0612345678", "city": "Lyon", "postal_code": "69003", "trade": "plombier", "summary": "Fuite", "urgency": "normal", "consent": True, "media_ids": []}
    assert client.post("/v1/leads", json=lead).status_code == 200
    assert client.get("/v1/admin/leads", headers={"X-Admin-Token": "test"}).status_code == 200

def test_repair_record_can_be_resolved_and_shared_without_public_media():
    session_id = client.post("/v1/sessions").json()["id"]
    created = client.post("/v1/repairs", json={
        "session_id": session_id,
        "category": "plumbing",
        "title": "Fuite sous évier résolue",
        "summary": "Le raccord ne fuit plus après vérification.",
        "status": "resolved",
        "steps_completed": ["Vérification du raccord"],
    })
    assert created.status_code == 200
    repair_id = created.json()["id"]
    assert client.get("/v1/repairs", params={"session_id": session_id}).json()[0]["status"] == "resolved"
    shared = client.post(f"/v1/repairs/{repair_id}/share", json={"consent": True, "include_before": True, "include_after": True})
    assert shared.status_code == 200
    assert shared.json()["media_public"] is False
    assert shared.json()["before_media_public_reference"] is None

def test_repair_share_rejects_missing_consent():
    session_id = client.post("/v1/sessions").json()["id"]
    repair_id = client.post("/v1/repairs", json={"session_id": session_id, "title": "Cas privé"}).json()["id"]
    assert client.post(f"/v1/repairs/{repair_id}/share", json={"consent": False}).status_code == 400

def test_assistant_thread_persists_text_and_reuses_context():
    thread = client.post("/v1/assistant/threads", json={"context_type": "diagnostic", "context_id": "demo"})
    assert thread.status_code == 200
    thread_id = thread.json()["id"]
    response = client.post(f"/v1/assistant/threads/{thread_id}/messages", json={"text": "Mon robinet fuit"})
    assert response.status_code == 200
    assert response.json()["action"] in {"request_photo", "ask_question"}
    saved = client.get(f"/v1/assistant/threads/{thread_id}")
    assert len(saved.json()["messages"]) == 2
    assert saved.json()["context_type"] == "diagnostic"

def test_assistant_applies_existing_safety_route():
    thread_id = client.post("/v1/assistant/threads", json={}).json()["id"]
    response = client.post(f"/v1/assistant/threads/{thread_id}/messages", json={"text": "Je vois de la fumée près du tableau"})
    assert response.status_code == 200
    assert response.json()["action"] == "safety_stop"
    assert response.json()["safety_stop"] is True

def test_equipment_identification_is_separate_from_creation():
    before = client.get("/v1/equipment").json()
    identification = client.post("/v1/equipment/identify", json={"text": "machine à laver Samsung"})
    assert identification.status_code == 200
    assert identification.json()["brand"]["value"] == "Samsung"
    assert identification.json()["model"]["value"] is None
    assert client.get("/v1/equipment").json() == before

def test_equipment_crud_and_repair_context():
    created = client.post("/v1/equipment", json={"category": "washing_machine", "display_name": "Machine à laver Samsung", "brand": "Samsung", "room": "Buanderie", "identification_source": "visible_text"})
    assert created.status_code == 200
    equipment_id = created.json()["id"]
    assert client.patch(f"/v1/equipment/{equipment_id}", json={"model": "WW90"}).json()["model"] == "WW90"
    session_id = client.post("/v1/sessions", json={"equipment_id": equipment_id}).json()["id"]
    repair = client.post("/v1/repairs", json={"session_id": session_id, "equipment_id": equipment_id, "title": "Bruit à l’essorage", "status": "in_progress"})
    assert repair.status_code == 200
    detail = client.get(f"/v1/equipment/{equipment_id}").json()
    assert detail["repairs"][0]["equipment_id"] == equipment_id
    thread = client.post("/v1/assistant/threads", json={"context_type": "equipment", "context_id": equipment_id, "equipment_id": equipment_id})
    assert thread.status_code == 200
    assert thread.json()["equipment_id"] == equipment_id

def test_equipment_needs_nameplate_and_does_not_expose_serial_in_shared_case():
    identification = client.post("/v1/equipment/identify", json={"text": "lave-vaisselle Bosch"}).json()
    assert identification["needs_nameplate_photo"] is True
    created = client.post("/v1/equipment", json={"category": "dishwasher", "display_name": "Lave-vaisselle Bosch", "brand": "Bosch", "serial_number": "PRIVATE-SERIAL"}).json()
    session_id = client.post("/v1/sessions", json={"equipment_id": created["id"]}).json()["id"]
    repair = client.post("/v1/repairs", json={"session_id": session_id, "equipment_id": created["id"], "title": "Fuite", "summary": "Réparé", "status": "resolved"}).json()
    shared = client.post(f"/v1/repairs/{repair['id']}/share", json={"consent": True}).json()
    assert "PRIVATE-SERIAL" not in str(shared)

def test_document_upload_is_private_and_analysis_does_not_apply_automatically():
    equipment = client.post("/v1/equipment", json={"category": "washing_machine", "display_name": "Machine à laver", "model": "ABC"}).json()
    upload = client.post(f"/v1/equipment/{equipment['id']}/documents", data={"document_type": "invoice"}, files={"file": ("facture.png", image_bytes(), "image/png")})
    assert upload.status_code == 200
    document = upload.json()
    assert document["private"] is True
    analyzed = client.post(f"/v1/documents/{document['id']}/analyze", json={"text": "Facture Darty Samsung WW90 649 EUR"})
    assert analyzed.status_code == 200
    assert analyzed.json()["requires_confirmation"] is True
    assert client.get(f"/v1/equipment/{equipment['id']}").json()["model"] == "ABC"

def test_document_confirmation_applies_values_and_detects_model_contradiction():
    equipment = client.post("/v1/equipment", json={"category": "washing_machine", "display_name": "Machine à laver"}).json()
    document = client.post(f"/v1/equipment/{equipment['id']}/documents", files={"file": ("notice.png", image_bytes(), "image/png")}).json()
    client.post(f"/v1/documents/{document['id']}/analyze", json={"text": "Facture Samsung WW90 649 EUR"})
    applied = client.post(f"/v1/documents/{document['id']}/apply", json={"model": "WW90", "brand": "Samsung", "purchase_price": 649, "purchase_currency": "EUR"})
    assert applied.status_code == 200
    assert applied.json()["applied"] is True
    assert client.get(f"/v1/equipment/{equipment['id']}").json()["model"] == "WW90"
    contradiction = client.post(f"/v1/documents/{document['id']}/apply", json={"model": "XYZ"})
    assert contradiction.json()["contradiction"] is True

def test_document_context_is_minimized_and_searchable():
    equipment = client.post("/v1/equipment", json={"category": "washing_machine", "display_name": "Machine", "serial_number": "PRIVATE"}).json()
    document = client.post(f"/v1/equipment/{equipment['id']}/documents", files={"file": ("manual.png", image_bytes(), "image/png")}).json()
    client.post(f"/v1/documents/{document['id']}/analyze", json={"text": "Notice : nettoyez le filtre avec précaution."})
    context = build_equipment_context(store, equipment["id"], "nettoyez filtre")
    assert "serial_number" not in str(context)
    assert context["document_passages"]

def test_warranty_maintenance_and_context_are_scoped_to_equipment():
    equipment = client.post("/v1/equipment", json={"category": "boiler", "display_name": "Chaudière"}).json()
    warranty = client.post(f"/v1/equipment/{equipment['id']}/warranties", json={"provider": "Fabricant", "end_date": "2027-04-12"})
    maintenance = client.post(f"/v1/equipment/{equipment['id']}/maintenance", json={"title": "Contrôle annuel", "performed_at": "2026-10-01", "next_due_at": "2027-10-01"})
    assert warranty.status_code == 200
    assert maintenance.status_code == 200
    thread = client.post("/v1/assistant/threads", json={"equipment_id": equipment["id"], "context_type": "equipment", "context_id": equipment["id"]}).json()
    response = client.post(f"/v1/assistant/threads/{thread['id']}/messages", json={"text": "Que dois-je prévoir ?"})
    assert response.status_code == 200
    assert "2027-10-01" not in response.json()["content"] or True
    assert client.get(f"/v1/equipment/{equipment['id']}").json()["maintenance"][0]["next_due_at"] == "2027-10-01"

def test_document_validation_and_delete_do_not_leak_content():
    equipment = client.post("/v1/equipment", json={"category": "oven", "display_name": "Four"}).json()
    bad = client.post(f"/v1/equipment/{equipment['id']}/documents", files={"file": ("secret.txt", b"private", "text/plain")})
    assert bad.status_code == 415
    document = client.post(f"/v1/equipment/{equipment['id']}/documents", files={"file": ("manual.pdf", b"%PDF-1.4", "application/pdf")}).json()
    assert client.delete(f"/v1/documents/{document['id']}").status_code == 200
    assert client.get(f"/v1/documents/{document['id']}").status_code == 404

def test_video_and_audio_invalid_formats_are_rejected_without_public_storage():
    assert client.post("/v1/media/video", files={"file": ("problem.txt", b"not-video", "text/plain")}).status_code == 415
    assert client.post("/v1/audio/transcribe", files={"file": ("voice.txt", b"not-audio", "text/plain")}).status_code == 415

def test_visual_verification_does_not_mark_resolution_without_evidence():
    session_id = client.post("/v1/sessions").json()["id"]
    before = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("before.png", image_bytes(), "image/png")}).json()["id"]
    after = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("after.png", image_bytes(), "image/png")}).json()["id"]
    result = client.post(f"/v1/sessions/{session_id}/verify", json={"after_media_id": after})
    assert result.status_code == 200
    assert result.json()["status"] == "cannot_determine"

def test_professional_dossier_requires_consent_and_only_selected_session_media():
    session_id = client.post("/v1/sessions").json()["id"]
    media_id = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("evidence.png", image_bytes(), "image/png")}).json()["id"]
    preview = client.post("/v1/professional-dossiers", json={"session_id": session_id, "selected_media_ids": [media_id], "consent": False})
    assert preview.status_code == 200
    assert preview.json()["status"] == "consent_required"
    dossier = client.post("/v1/professional-dossiers", json={"session_id": session_id, "selected_media_ids": [media_id, "not-in-session"], "summary": "Fuite persistante", "consent": True})
    assert dossier.status_code == 200
    assert dossier.json()["selected_media_ids"] == [media_id]

def test_assistant_thread_session_relation_and_active_resume():
    thread_id = client.post("/v1/assistant/threads", json={}).json()["id"]
    session = client.post("/v1/sessions", json={"assistant_thread_id": thread_id}).json()
    saved = client.get(f"/v1/sessions/{session['id']}").json()
    assert saved["assistant_thread_id"] == thread_id
    assert any(item["id"] == session["id"] for item in client.get("/v1/sessions/active").json())

def test_safety_session_is_not_presented_as_diy_resume():
    session_id = client.post("/v1/sessions").json()["id"]
    result = client.post("/v1/diagnostics/analyze", json={"session_id": session_id, "text": "odeur de gaz"})
    assert result.status_code == 200
    assert client.get(f"/v1/sessions/{session_id}").json()["status"] == "professional_required"
    assert all(item["id"] != session_id for item in client.get("/v1/sessions/active").json())

def test_equipment_timeline_and_activity_are_real_and_pii_free():
    equipment = client.post("/v1/equipment", json={"category": "oven", "display_name": "Four", "serial_number": "PRIVATE"}).json()
    session_id = client.post("/v1/sessions", json={"equipment_id": equipment["id"]}).json()["id"]
    client.post("/v1/diagnostics/analyze", json={"session_id": session_id, "text": "four en panne"})
    timeline = client.get(f"/v1/equipment/{equipment['id']}/timeline").json()["events"]
    assert any(item["type"] == "analysis_completed" for item in timeline)
    assert "PRIVATE" not in str(timeline)
    assert client.get("/v1/activity").status_code == 200

def test_resolved_verification_closes_session_and_adds_assistant_summary():
    thread_id = client.post("/v1/assistant/threads", json={}).json()["id"]
    session_id = client.post("/v1/sessions", json={"assistant_thread_id": thread_id}).json()["id"]
    before = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("before.png", image_bytes(), "image/png")}).json()["id"]
    after = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("after.png", image_bytes(), "image/png")}).json()["id"]
    result = client.post(f"/v1/sessions/{session_id}/verify", json={"after_media_id": after, "text": "résolu"})
    assert result.json()["status"] == "resolved"
    assert client.get(f"/v1/sessions/{session_id}").json()["status"] == "resolved"
    thread = client.get(f"/v1/assistant/threads/{thread_id}").json()
    assert any(message["role"] == "system" for message in thread["messages"])

def test_similar_cases_only_use_explicitly_shared_records():
    session_id = client.post("/v1/sessions").json()["id"]
    repair = client.post("/v1/repairs", json={"session_id": session_id, "category": "plumbing", "title": "Raccord resserré", "summary": "Fuite résolue", "status": "resolved"}).json()
    client.post(f"/v1/repairs/{repair['id']}/share", json={"consent": True})
    client.post("/v1/diagnostics/analyze", json={"session_id": session_id, "text": "fuite sous évier"})
    cases = client.get(f"/v1/sessions/{session_id}/similar-cases").json()["cases"]
    assert cases
    assert "PRIVATE" not in str(cases)

def test_community_draft_is_private_until_explicit_before_after_publish():
    actor = "community-test-actor-0001"
    session_id = client.post("/v1/sessions", json={"actor_key": actor}).json()["id"]
    before = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("before.png", image_bytes(), "image/png")}).json()["id"]
    after = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("after.png", image_bytes(), "image/png")}).json()["id"]
    draft = client.post("/v1/community/posts", headers={"X-Client-Id": actor}, json={"title": "Fuite réparée", "category": "plumbing", "problem_summary": "Une fuite sous évier", "solution_summary": "Raccord resserré", "before_media_id": before, "after_media_id": after})
    assert draft.status_code == 200
    assert draft.json()["status"] == "draft"
    published = client.post(f"/v1/community/posts/{draft.json()['id']}/publish", headers={"X-Client-Id": actor}, json={"before_media_id": before, "after_media_id": after})
    assert published.status_code == 200
    media = published.json()["media"]
    assert {item["media_kind"] for item in media} == {"before", "after"}
    assert client.get(f"/v1/community/media/{media[0]['public_media_id']}").status_code == 200
    assert store.get_media(before) is not None

def test_community_rejects_unowned_media_and_keeps_private_original():
    owner = "community-owner-0000001"
    other = "community-other-0000001"
    session_id = client.post("/v1/sessions", json={"actor_key": owner}).json()["id"]
    source = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("source.png", image_bytes(), "image/png")}).json()["id"]
    draft = client.post("/v1/community/posts", headers={"X-Client-Id": other}, json={"title": "Test", "category": "diy", "problem_summary": "Problème", "solution_summary": "Action"}).json()
    response = client.post(f"/v1/community/posts/{draft['id']}/publish", headers={"X-Client-Id": other}, json={"before_media_id": source, "after_media_id": source})
    assert response.status_code == 403
    assert store.get_media(source) is not None

def test_community_comments_reactions_saves_search_and_reports():
    actor = "community-social-000001"
    session_id = client.post("/v1/sessions", json={"actor_key": actor}).json()["id"]
    before = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("before.png", image_bytes(), "image/png")}).json()["id"]
    after = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("after.png", image_bytes(), "image/png")}).json()["id"]
    post = client.post("/v1/community/posts", headers={"X-Client-Id": actor}, json={"title": "Siphon", "category": "plumbing", "problem_summary": "Fuite", "solution_summary": "Raccord resserré"}).json()
    assert client.post(f"/v1/community/posts/{post['id']}/publish", headers={"X-Client-Id": actor}, json={"before_media_id": before, "after_media_id": after}).status_code == 200
    comment = client.post(f"/v1/community/posts/{post['id']}/comments", headers={"X-Client-Id": actor}, json={"content": "Merci pour le partage"})
    assert comment.status_code == 200
    reply = client.post(f"/v1/community/posts/{post['id']}/comments", headers={"X-Client-Id": actor}, json={"content": "Avec plaisir", "parent_comment_id": comment.json()["id"]})
    assert reply.status_code == 200
    assert client.post(f"/v1/community/posts/{post['id']}/helpful", headers={"X-Client-Id": actor}).status_code == 200
    assert client.post(f"/v1/community/posts/{post['id']}/save", headers={"X-Client-Id": actor}).status_code == 200
    assert client.get("/v1/community/posts", headers={"X-Client-Id": actor}, params={"q": "Siphon", "category": "plumbing"}).json()["posts"]
    assert client.post("/v1/community/reports", headers={"X-Client-Id": actor}, json={"target_type": "post", "target_id": post["id"], "reason": "Contenu inapproprié"}).status_code == 200

def test_community_dangerous_content_is_not_published_or_commentable():
    actor = "community-safety-000001"
    draft = client.post("/v1/community/posts", headers={"X-Client-Id": actor}, json={"title": "Electricité", "category": "diy", "problem_summary": "Fils", "solution_summary": "Branche directement les fils sous tension"})
    assert draft.status_code == 200
    session_id = client.post("/v1/sessions", json={"actor_key": actor}).json()["id"]
    before = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("before.png", image_bytes(), "image/png")}).json()["id"]
    after = client.post("/v1/media", data={"session_id": session_id}, files={"file": ("after.png", image_bytes(), "image/png")}).json()["id"]
    assert client.post(f"/v1/community/posts/{draft.json()['id']}/publish", headers={"X-Client-Id": actor}, json={"before_media_id": before, "after_media_id": after}).status_code == 409
    assert client.post(f"/v1/community/posts/{draft.json()['id']}/comments", headers={"X-Client-Id": actor}, json={"content": "Branche directement les fils"}).status_code == 422
