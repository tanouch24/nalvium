from __future__ import annotations

import os
import json
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI, File, Form, Header, HTTPException, Request, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from .ai import AudioTranscriptionService, MockMultimodalProvider, OpenAIMultimodalProvider, ProviderError
from .database import build_store
from .equipment_context import build_equipment_context
from .media import AUDIO_MIME, LocalPrivateMediaStore, MediaError
from .video import VideoFrameExtractor, VideoProcessingError, MAX_DURATION_SECONDS
from .timeline import HouseholdTimelineService
from .rate_limit import RateLimiter
from .schemas import ActionType, Analysis, AnalyzeRequest, AssistantMessageRequest, AssistantResponse, AssistantThreadRequest, CommunityCommentRequest, CommunityPostRequest, CommunityPublishRequest, CommunityReportRequest, Diy, DocumentAnalyzeRequest, DocumentApplyRequest, EquipmentCreateRequest, EquipmentIdentification, EquipmentMediaRequest, EquipmentUpdateRequest, EquipmentDocumentUpdateRequest, LeadRequest, MaintenanceRequest, NextAction, ProfessionalDossierRequest, ProfessionalInput, ProfessionalUpdate, RepairRecordRequest, RepairRecordUpdate, RepairVerification, Risk, RiskLevel, SessionRequest, ShareRepairRequest, SimilarCasesRequest, VerificationRequest, WarrantyRequest
from .safety import apply_postcheck, safety_precheck

app = FastAPI(title="NALVIUM API", version="0.2.0")
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:3000", "http://localhost:4173", "http://localhost:4174"], allow_methods=["*"], allow_headers=["*"])

store = build_store()
media_store = LocalPrivateMediaStore()
limit = int(os.getenv("NALVIUM_RATE_LIMIT_PER_MINUTE", "12"))
rate_limiters = {"session": RateLimiter(min(limit, 6)), "upload": RateLimiter(min(limit, 8)), "analysis": RateLimiter(limit), "assistant": RateLimiter(limit), "lead": RateLimiter(3), "transcription": RateLimiter(6), "community_post": RateLimiter(5), "community_comment": RateLimiter(20), "community_report": RateLimiter(5)}
admin_token = os.getenv("NALVIUM_ADMIN_TOKEN", "")

def build_provider():
    if os.getenv("NALVIUM_AI_PROVIDER", "").lower() == "mock" or not os.getenv("OPENAI_API_KEY"):
        return MockMultimodalProvider()
    return OpenAIMultimodalProvider()

provider = build_provider()
frame_extractor = VideoFrameExtractor()
transcription_service = AudioTranscriptionService(getattr(provider, "client", None))
timeline_service = HouseholdTimelineService(store)

def client_key(request: Request) -> str:
    return request.client.host if request.client else "local"

def require_rate(request: Request, kind: str) -> None:
    if not rate_limiters[kind].allow(client_key(request)):
        raise HTTPException(429, "Trop de demandes. Réessayez dans quelques instants.")

def require_admin(x_admin_token: str | None) -> None:
    if not admin_token or x_admin_token != admin_token:
        raise HTTPException(401, "Authentification administrateur requise")

def community_actor(x_client_id: str | None) -> str:
    import re
    if not x_client_id or not re.fullmatch(r"[A-Za-z0-9_-]{16,128}", x_client_id):
        raise HTTPException(401, "Identité communautaire requise")
    return x_client_id

def community_moderation_status(text: str) -> str:
    lowered = text.lower()
    dangerous = ("sous tension", "branche directement les fils", "relie les fils", "contourner la sécurité", "odeur de gaz", "fuite de gaz", "court-circuit", "fils exposés", "eau et électricité")
    return "restricted" if any(term in lowered for term in dangerous) else "approved"

def safety_stop_analysis(risk: Risk) -> Analysis:
    return Analysis(category="unknown", subcategory="safety_stop", observations=[], hypotheses=[], missing_information=[], risk=risk, urgency="urgent", diy=Diy(allowed=False, difficulty="stop"), next_action=NextAction(type=ActionType.safety_stop, instruction="Ne poursuivez pas la réparation. Mettez-vous en sécurité si possible et contactez le service compétent."), assistant_message="Cette situation peut être dangereuse. Je ne vais pas vous guider dans une réparation.")

@app.get("/health")
def health():
    return {"status": "ok", "environment": "local", "ai_provider": provider.__class__.__name__, "database": "postgresql" if store.persistent else "memory-fallback"}

@app.post("/v1/sessions")
def create_session(request: Request, payload: SessionRequest | None = None):
    require_rate(request, "session")
    equipment_id = payload.equipment_id if payload else None
    if equipment_id and not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    if payload and payload.assistant_thread_id and not store.get_assistant_thread(payload.assistant_thread_id):
        raise HTTPException(404, "Conversation introuvable")
    return store.create_session(equipment_id, payload.assistant_thread_id if payload else None, payload.actor_key if payload else None)

@app.get("/v1/sessions/active")
def active_sessions():
    return timeline_service.active_sessions()

@app.get("/v1/sessions/{session_id}")
def get_session(session_id: str):
    session = store.get_session(session_id)
    if not session:
        raise HTTPException(404, "Session introuvable")
    return session

@app.get("/v1/equipment/{equipment_id}/timeline")
def equipment_timeline(equipment_id: str):
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return {"events": timeline_service.equipment(equipment_id)}

@app.get("/v1/activity")
def activity(limit: int = 30, offset: int = 0):
    if limit < 1 or limit > 100 or offset < 0:
        raise HTTPException(422, "Pagination invalide")
    return {"events": timeline_service.activity(limit, offset), "limit": limit, "offset": offset}

@app.delete("/v1/sessions/{session_id}")
def delete_session(session_id: str):
    session = store.get_session(session_id)
    if not session:
        raise HTTPException(404, "Session introuvable")
    for media in session.get("media", []):
        media_store.delete(media["id"])
    store.delete_session(session_id)
    return {"deleted": True}

@app.post("/v1/media")
async def upload_media(request: Request, file: UploadFile = File(...), session_id: str | None = Form(default=None)):
    require_rate(request, "upload")
    try:
        data = await file.read()
        media = media_store.save_image(data, file.content_type)
    except MediaError as exc:
        raise HTTPException(exc.status_code, str(exc)) from exc
    store.add_media(session_id, media)
    return {"id": media["id"], "session_id": session_id, "private": True, "expires_in": 900, "media_type": media["media_type"]}

@app.post("/v1/media/video")
async def upload_video(request: Request, file: UploadFile = File(...), session_id: str | None = Form(default=None)):
    require_rate(request, "upload")
    try:
        data = await file.read()
        media = media_store.save_video(data, file.content_type, file.filename)
        duration = frame_extractor.duration(media["path"])
        if duration is not None and duration > MAX_DURATION_SECONDS:
            media_store.delete(media["id"])
            raise MediaError("Cette vidéo est un peu longue. Filmez seulement le moment où le problème apparaît.", 422)
        media["duration_ms"] = round(duration * 1000) if duration is not None else None
    except (MediaError, VideoProcessingError) as exc:
        raise HTTPException(getattr(exc, "status_code", 422), str(exc)) from exc
    store.add_media(session_id, media)
    return {"id": media["id"], "session_id": session_id, "private": True, "media_type": media["media_type"], "duration_ms": media.get("duration_ms")}

@app.post("/v1/audio/transcribe")
async def transcribe_audio(request: Request, file: UploadFile = File(...)):
    require_rate(request, "transcription")
    if file.content_type not in AUDIO_MIME:
        raise HTTPException(415, "Format audio non pris en charge")
    data = await file.read()
    if len(data) > 10 * 1024 * 1024:
        raise HTTPException(413, "Cet enregistrement est trop volumineux")
    try:
        text = transcription_service.transcribe(data, file.filename or "voice.m4a", file.content_type)
    except ProviderError as exc:
        raise HTTPException(503, "Je n'ai pas réussi à comprendre l'enregistrement. Vous pouvez réessayer ou écrire votre message.") from exc
    return {"text": text, "private": True}

@app.post("/v1/diagnostics/analyze")
def analyze(request: Request, payload: AnalyzeRequest):
    require_rate(request, "analysis")
    session = store.get_session(payload.session_id) if payload.session_id else None
    if payload.session_id and not session:
        raise HTTPException(404, "Session introuvable")
    pre = safety_precheck(payload.text)
    if pre.stop_diy:
        result = safety_stop_analysis(pre)
    else:
        image_bytes = None
        frames = None
        if payload.media_id:
            media = store.get_media(payload.media_id)
            if not media:
                raise HTTPException(404, "Média introuvable")
            if media.get("media_type", "").startswith("video/"):
                try:
                    frames = frame_extractor.extract(media["path"])
                except VideoProcessingError as exc:
                    raise HTTPException(503, str(exc)) from exc
            else:
                image_bytes = media_store.read(payload.media_id)
        equipment_id = payload.equipment_id or (session or {}).get("equipment_id")
        context = session.get("messages", []) if session else []
        equipment_context = build_equipment_context(store, equipment_id)
        if equipment_context:
            context = context + [{"equipment_context": equipment_context}]
        try:
            result = provider.analyze_frames(payload.text, frames, context) if frames is not None else provider.analyze(payload.text, payload.media_name, image_bytes, context)
        except ProviderError as exc:
            raise HTTPException(503, str(exc)) from exc
        result = apply_postcheck(result, payload.text)
    if payload.session_id:
        store.save_analysis(payload.session_id, result.model_dump())
    return result

@app.post("/v1/equipment/identify", response_model=EquipmentIdentification)
def identify_equipment(request: Request, payload: AnalyzeRequest):
    require_rate(request, "analysis")
    if not payload.text.strip() and not payload.media_id:
        raise HTTPException(422, "Une photo ou une description est requise")
    image_bytes = None
    frames = None
    if payload.media_id:
        media = store.get_media(payload.media_id)
        if not media:
            raise HTTPException(404, "Média introuvable")
        if media.get("media_type", "").startswith("video/"):
            try:
                frames = frame_extractor.extract(media["path"])
            except VideoProcessingError as exc:
                raise HTTPException(503, str(exc)) from exc
        else:
            image_bytes = media_store.read(payload.media_id)
    try:
        result = provider.identify_equipment(payload.text, image_bytes=image_bytes)
    except ProviderError as exc:
        raise HTTPException(503, str(exc)) from exc
    return result

@app.post("/v1/equipment")
def create_equipment(payload: EquipmentCreateRequest):
    if payload.primary_media_id and not store.get_media(payload.primary_media_id):
        raise HTTPException(404, "Média principal introuvable")
    equipment = store.create_equipment(payload.model_dump(exclude_none=True))
    if payload.primary_media_id:
        store.add_equipment_media(equipment["id"], payload.primary_media_id, "primary")
        equipment = store.get_equipment(equipment["id"])
    return equipment

@app.get("/v1/equipment")
def list_equipment(room: str | None = None):
    return store.list_equipments(room)

@app.get("/v1/equipment/{equipment_id}")
def get_equipment(equipment_id: str):
    equipment = store.get_equipment(equipment_id)
    if not equipment:
        raise HTTPException(404, "Équipement introuvable")
    return equipment

@app.patch("/v1/equipment/{equipment_id}")
def update_equipment(equipment_id: str, payload: EquipmentUpdateRequest):
    result = store.update_equipment(equipment_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Équipement introuvable")
    return result

@app.delete("/v1/equipment/{equipment_id}")
def delete_equipment(equipment_id: str):
    if not store.delete_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return {"deleted": True, "id": equipment_id}

@app.post("/v1/equipment/{equipment_id}/media")
def add_equipment_media(equipment_id: str, payload: EquipmentMediaRequest):
    if not store.get_media(payload.media_id):
        raise HTTPException(404, "Média introuvable")
    result = store.add_equipment_media(equipment_id, payload.media_id, payload.media_type)
    if not result:
        raise HTTPException(404, "Équipement introuvable")
    return result

@app.post("/v1/equipment/{equipment_id}/documents")
async def upload_equipment_document(request: Request, equipment_id: str, file: UploadFile = File(...), document_type: str = Form(default="other"), display_name: str | None = Form(default=None)):
    require_rate(request, "upload")
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    session = store.create_session(equipment_id)
    try:
        data = await file.read()
        media = media_store.save_document(data, file.content_type, file.filename)
    except MediaError as exc:
        raise HTTPException(exc.status_code, str(exc)) from exc
    store.add_media(session["id"], media)
    document = store.create_document(equipment_id, {"media_id": media["id"], "document_type": document_type, "display_name": display_name or file.filename or "Document", "mime_type": media["media_type"], "original_filename": file.filename})
    return document | {"private": True, "session_id": session["id"]}

@app.get("/v1/equipment/{equipment_id}/documents")
def list_equipment_documents(equipment_id: str):
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return store.list_documents(equipment_id)

@app.get("/v1/equipment/{equipment_id}/documents/search")
def search_equipment_documents(equipment_id: str, q: str):
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return store.search_document_chunks(equipment_id, q)

@app.get("/v1/documents/{document_id}")
def get_document(document_id: str):
    document = store.get_document(document_id)
    if not document:
        raise HTTPException(404, "Document introuvable")
    return document

@app.patch("/v1/documents/{document_id}")
def update_document(document_id: str, payload: EquipmentDocumentUpdateRequest):
    result = store.update_document(document_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Document introuvable")
    return result

@app.delete("/v1/documents/{document_id}")
def delete_document(document_id: str):
    document = store.get_document(document_id)
    if not document:
        raise HTTPException(404, "Document introuvable")
    if not store.delete_document(document_id):
        raise HTTPException(404, "Document introuvable")
    media_store.delete(document["media_id"])
    return {"deleted": True, "id": document_id}

@app.post("/v1/documents/{document_id}/analyze")
def analyze_document(document_id: str, payload: DocumentAnalyzeRequest):
    document = store.get_document(document_id)
    if not document:
        raise HTTPException(404, "Document introuvable")
    try:
        result = provider.extract_document(payload.text, media_store.read(document["media_id"]), document.get("mime_type"))
        extracted = result.model_dump()
        chunks = []
        source_text = result.extracted_text or payload.text
        for index in range(0, len(source_text), 1200):
            chunks.append({"chunk_index": index // 1200, "text": source_text[index:index + 1200], "metadata": {"document_id": document_id}})
        store.replace_document_chunks(document_id, chunks)
        updated = store.update_document(document_id, {"document_type": result.document_type, "display_name": result.document_title or document["display_name"], "document_date": result.document_date, "extracted_text": result.extracted_text, "extraction_status": "completed", "extraction_json": extracted})
        return {"document": updated, "extraction": extracted, "requires_confirmation": True}
    except ProviderError as exc:
        store.update_document(document_id, {"extraction_status": "failed"})
        raise HTTPException(503, str(exc)) from exc

@app.post("/v1/documents/{document_id}/apply")
def apply_document(document_id: str, payload: DocumentApplyRequest):
    document = store.get_document(document_id)
    if not document:
        raise HTTPException(404, "Document introuvable")
    equipment = store.get_equipment(document["equipment_id"])
    if not equipment:
        raise HTTPException(404, "Équipement introuvable")
    values = {key: value for key, value in payload.model_dump(exclude_unset=True).items() if value is not None}
    contradiction = equipment.get("model") and values.get("model") and equipment["model"] != values["model"]
    if contradiction:
        return {"applied": False, "contradiction": True, "existing_model": equipment["model"], "document_model": values["model"], "document": document}
    if values:
        store.update_equipment(document["equipment_id"], values)
    extracted = document.get("extraction_json") or {}
    warranty_end = extracted.get("warranty_end_date")
    if warranty_end:
        store.create_warranty(document["equipment_id"], {"source_document_id": document_id, "provider": extracted.get("warranty_provider"), "end_date": warranty_end, "start_date": extracted.get("purchase_date")})
    return {"applied": True, "contradiction": False, "equipment": store.get_equipment(document["equipment_id"]), "document": store.get_document(document_id)}

@app.post("/v1/equipment/{equipment_id}/warranties")
def create_warranty(equipment_id: str, payload: WarrantyRequest):
    result = store.create_warranty(equipment_id, payload.model_dump(exclude_none=True))
    if not result:
        raise HTTPException(404, "Équipement introuvable")
    return result

@app.get("/v1/equipment/{equipment_id}/warranties")
def list_warranties(equipment_id: str):
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return store.list_warranties(equipment_id)

@app.patch("/v1/warranties/{warranty_id}")
def update_warranty(warranty_id: str, payload: WarrantyRequest):
    result = store.update_warranty(warranty_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Garantie introuvable")
    return result

@app.delete("/v1/warranties/{warranty_id}")
def delete_warranty(warranty_id: str):
    if not store.delete_warranty(warranty_id):
        raise HTTPException(404, "Garantie introuvable")
    return {"deleted": True, "id": warranty_id}

@app.post("/v1/equipment/{equipment_id}/maintenance")
def create_maintenance(equipment_id: str, payload: MaintenanceRequest):
    result = store.create_maintenance(equipment_id, payload.model_dump())
    if not result:
        raise HTTPException(404, "Équipement introuvable")
    return result

@app.get("/v1/equipment/{equipment_id}/maintenance")
def list_maintenance(equipment_id: str):
    if not store.get_equipment(equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return store.list_maintenance(equipment_id)

@app.patch("/v1/maintenance/{maintenance_id}")
def update_maintenance(maintenance_id: str, payload: MaintenanceRequest):
    result = store.update_maintenance(maintenance_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Entretien introuvable")
    return result

@app.delete("/v1/maintenance/{maintenance_id}")
def delete_maintenance(maintenance_id: str):
    if not store.delete_maintenance(maintenance_id):
        raise HTTPException(404, "Entretien introuvable")
    return {"deleted": True, "id": maintenance_id}

def _assistant_action(result: Analysis) -> str:
    if result.next_action.type == ActionType.safety_stop:
        return "safety_stop"
    if result.next_action.type == ActionType.recommend_professional:
        return "recommend_professional"
    if result.next_action.type == ActionType.resolved:
        return "resolved"
    return result.next_action.type.value

@app.post("/v1/assistant/threads")
def create_assistant_thread(payload: AssistantThreadRequest):
    if payload.equipment_id and not store.get_equipment(payload.equipment_id):
        raise HTTPException(404, "Équipement introuvable")
    return store.create_assistant_thread(payload.context_type, payload.context_id, payload.equipment_id)

@app.get("/v1/assistant/threads/{thread_id}")
def get_assistant_thread(thread_id: str):
    thread = store.get_assistant_thread(thread_id)
    if not thread:
        raise HTTPException(404, "Conversation introuvable")
    return thread

@app.post("/v1/assistant/threads/{thread_id}/messages", response_model=AssistantResponse)
def send_assistant_message(request: Request, thread_id: str, payload: AssistantMessageRequest):
    require_rate(request, "assistant")
    thread = store.get_assistant_thread(thread_id)
    if not thread:
        raise HTTPException(404, "Conversation introuvable")
    if not payload.text.strip() and not payload.media_id:
        raise HTTPException(422, "Un message ou une photo est requis")
    media_ids = [payload.media_id] if payload.media_id else []
    image_bytes = None
    frames = None
    if payload.media_id:
        media = store.get_media(payload.media_id)
        if not media:
            raise HTTPException(404, "Média introuvable")
        if media.get("media_type", "").startswith("video/"):
            try:
                frames = frame_extractor.extract(media["path"])
            except VideoProcessingError as exc:
                raise HTTPException(503, str(exc)) from exc
        else:
            image_bytes = media_store.read(payload.media_id)
    source_text = payload.text.strip()
    context = {"type": payload.context_type, "id": payload.context_id} if payload.context_type and payload.context_id else None
    store.add_assistant_message(thread_id, "user", source_text, media_ids, context)
    pre = safety_precheck(source_text)
    if pre.stop_diy:
        result = safety_stop_analysis(pre)
    else:
        equipment_context = build_equipment_context(store, thread.get("equipment_id"), source_text)
        previous = [{"role": item["role"], "content": item["content"]} for item in thread.get("messages", [])[-8:]]
        if equipment_context:
            previous.append({"role": "system", "content": json.dumps({"equipment_context": equipment_context}, ensure_ascii=False)})
        try:
            result = provider.analyze_frames(source_text, frames, previous) if frames is not None else provider.continue_session(source_text, None, image_bytes, previous)
        except ProviderError as exc:
            raise HTTPException(503, str(exc)) from exc
        result = apply_postcheck(result, source_text)
    content = result.assistant_message
    assistant = store.add_assistant_message(thread_id, "assistant", content, [], context)
    return AssistantResponse(thread_id=thread_id, message_id=assistant["id"], role="assistant", content=content, action=_assistant_action(result), next_action=result.next_action.model_dump(), safety_stop=result.risk.stop_diy, media_references=media_ids, context=context)

@app.post("/v1/leads")
def create_lead(request: Request, payload: LeadRequest):
    require_rate(request, "lead")
    if not payload.consent:
        raise HTTPException(400, "Le consentement explicite est requis avant toute transmission")
    if not store.get_session(payload.session_id):
        raise HTTPException(404, "Session introuvable")
    lead = store.create_lead(payload.model_dump(), payload.media_ids)
    return {"id": lead["id"], "status": "new", "message": "Votre demande est enregistrée. Aucun professionnel n'est confirmé à ce stade."}

@app.post("/v1/repairs")
def create_repair(payload: RepairRecordRequest):
    if not store.get_session(payload.session_id):
        raise HTTPException(404, "Session introuvable")
    return store.create_repair(payload.model_dump())

@app.post("/v1/sessions/{session_id}/verify", response_model=RepairVerification)
def verify_session(request: Request, session_id: str, payload: VerificationRequest):
    require_rate(request, "analysis")
    session = store.get_session(session_id)
    if not session:
        raise HTTPException(404, "Session introuvable")
    pre = safety_precheck(payload.text)
    if pre.stop_diy:
        raise HTTPException(409, "La vérification est arrêtée pour des raisons de sécurité")
    after = store.get_media(payload.after_media_id)
    if not after:
        raise HTTPException(404, "Média après introuvable")
    before_media = next((item for item in reversed(session.get("media", [])) if item.get("id") != payload.after_media_id), None)
    def frames_for(media):
        if not media:
            return []
        if media.get("media_type", "").startswith("video/"):
            return frame_extractor.extract(media["path"])
        return [media_store.read(media["id"])]
    try:
        result = provider.verify_repair(payload.text, frames_for(before_media), frames_for(after))
    except (ProviderError, VideoProcessingError) as exc:
        raise HTTPException(503, str(exc)) from exc
    store.create_verification({"session_id": session_id, "before_media_id": before_media.get("id") if before_media else None, "after_media_id": payload.after_media_id, **result.model_dump()})
    if result.status == "resolved":
        store.update_session_status(session_id, "resolved")
    elif result.status == "worsened" or result.requires_professional:
        store.update_session_status(session_id, "professional_required")
    if session.get("assistant_thread_id"):
        summary = {"status": result.status, "session_id": session_id, "observations": result.observations, "requires_professional": result.requires_professional}
        store.add_assistant_message(session["assistant_thread_id"], "system", "Vérification du diagnostic terminée.", [], {"diagnostic_summary": summary})
    return result

@app.get("/v1/sessions/{session_id}/similar-cases")
def similar_cases(session_id: str, payload: SimilarCasesRequest = SimilarCasesRequest()):
    session = store.get_session(session_id)
    if not session:
        raise HTTPException(404, "Session introuvable")
    analysis = next((item.get("content", {}).get("analysis") for item in reversed(session.get("messages", [])) if item.get("role") == "assistant" and item.get("content", {}).get("analysis")), {})
    return {"cases": store.list_similar_cases(analysis.get("category", "other"), analysis.get("subcategory"), payload.limit)}

@app.post("/v1/professional-dossiers")
def create_professional_dossier(payload: ProfessionalDossierRequest):
    session = store.get_session(payload.session_id)
    if not session:
        raise HTTPException(404, "Session introuvable")
    equipment_id = payload.equipment_id or session.get("equipment_id")
    session_media = {item.get("id") for item in session.get("media", [])}
    selected = [media_id for media_id in payload.selected_media_ids if media_id in session_media]
    if not payload.consent:
        return {"status": "consent_required", "selected_media_ids": selected, "message": "Aucun dossier n'est transmis sans votre consentement explicite."}
    analysis = next((item.get("content", {}).get("analysis") for item in reversed(session.get("messages", [])) if item.get("content", {}).get("analysis")), {})
    equipment = store.get_equipment(equipment_id) if equipment_id else None
    dossier = {"session_id": payload.session_id, "equipment_id": equipment_id, "category": analysis.get("category"), "equipment": {key: equipment.get(key) for key in ("display_name", "brand", "model", "room")} if equipment else None, "summary": payload.summary, "observations": analysis.get("observations", []), "hypotheses": analysis.get("hypotheses", []), "urgency": analysis.get("urgency"), "risk": analysis.get("risk"), "selected_media_ids": selected, "contact": {"first_name": payload.first_name, "phone": payload.phone, "city": payload.city, "postal_code": payload.postal_code, "desired_time_window": payload.desired_time_window} if payload.consent else None}
    result = store.create_professional_dossier(dossier)
    store.update_session_status(payload.session_id, "professional_required")
    return result

@app.get("/v1/repairs")
def list_repairs(session_id: str | None = None):
    return store.list_repairs(session_id)

@app.patch("/v1/repairs/{repair_id}")
def update_repair(repair_id: str, payload: RepairRecordUpdate):
    result = store.update_repair(repair_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Dossier de réparation introuvable")
    return result

@app.post("/v1/repairs/{repair_id}/share")
def share_repair(repair_id: str, payload: ShareRepairRequest):
    if not payload.consent:
        raise HTTPException(400, "Le consentement explicite est requis")
    result = store.share_repair(repair_id, payload.model_dump())
    if not result:
        raise HTTPException(404, "Dossier de réparation introuvable")
    return {**result, "media_public": False, "message": "Cas anonymisé enregistré. Les médias restent privés tant qu'une dérivation publique n'est pas configurée."}

@app.post("/v1/community/posts")
def create_community_post(request: Request, payload: CommunityPostRequest, x_client_id: str | None = Header(default=None)):
    require_rate(request, "community_post")
    actor = community_actor(x_client_id)
    if payload.repair_record_id:
        repairs = store.list_repairs()
        repair = next((item for item in repairs if item.get("id") == payload.repair_record_id), None)
        if not repair:
            raise HTTPException(404, "Réparation introuvable")
        if repair.get("status") != "resolved":
            raise HTTPException(409, "Seule une réparation résolue peut être proposée à la communauté")
        session = store.get_session(repair.get("session_id"))
        if session and session.get("actor_key") and session.get("actor_key") != actor:
            raise HTTPException(403, "Cette réparation ne vous appartient pas")
    combined = " ".join(filter(None, [payload.title, payload.problem_summary, payload.solution_summary, payload.materials_used]))
    data = payload.model_dump()
    data["moderation_status"] = community_moderation_status(combined)
    return store.create_community_post(actor, data, data["moderation_status"])

@app.get("/v1/community/posts")
def list_community_posts(x_client_id: str | None = Header(default=None), q: str = "", category: str = "all", offset: int = 0, limit: int = 20, saved: bool = False):
    actor = community_actor(x_client_id)
    if offset < 0 or limit < 1 or limit > 50:
        raise HTTPException(422, "Pagination invalide")
    return {"posts": store.list_community_posts(actor, q, category, offset, limit, saved), "offset": offset, "limit": limit}

@app.get("/v1/community/posts/{post_id}")
def get_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    post = store.get_community_post(post_id, actor)
    if not post:
        raise HTTPException(404, "Publication introuvable")
    return post

@app.patch("/v1/community/posts/{post_id}")
def update_community_post(post_id: str, payload: CommunityPostRequest, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    data = payload.model_dump(exclude_unset=True)
    data["moderation_status"] = community_moderation_status(" ".join(str(value) for value in data.values() if value))
    post = store.update_community_post(post_id, actor, data)
    if not post:
        raise HTTPException(403, "Publication introuvable ou non autorisée")
    return post

@app.post("/v1/community/posts/{post_id}/publish")
def publish_community_post(request: Request, post_id: str, payload: CommunityPublishRequest, x_client_id: str | None = Header(default=None)):
    require_rate(request, "community_post")
    actor = community_actor(x_client_id)
    draft = store.get_community_post(post_id, actor)
    if not draft:
        raise HTTPException(404, "Brouillon introuvable")
    if draft.get("status") == "published":
        raise HTTPException(409, "Cette publication est déjà publiée")
    selected = [("before", payload.before_media_id), ("after", payload.after_media_id)] + [("additional", item) for item in payload.additional_media_ids]
    selected = [(kind, media_id) for kind, media_id in selected if media_id]
    if not any(kind == "before" for kind, _ in selected) or not any(kind == "after" for kind, _ in selected):
        raise HTTPException(422, "Sélectionnez une photo avant et une photo après")
    created_public = []
    try:
        for kind, source_id in selected:
            source = store.get_media(source_id)
            if not source or not source.get("media_type", "").startswith("image/"):
                raise HTTPException(422, "Chaque média communautaire doit être une image privée valide")
            source_session = store.get_session(source.get("session_id")) if source.get("session_id") else None
            if not source_session:
                raise HTTPException(403, "Ce média privé ne vous appartient pas")
            if draft.get("repair_record_id"):
                repair = next((item for item in store.list_repairs() if item.get("id") == draft["repair_record_id"]), None)
                if repair and repair.get("session_id") != source.get("session_id"):
                    raise HTTPException(403, "Le média ne correspond pas à cette réparation")
                if source_session.get("actor_key") not in (None, actor):
                    raise HTTPException(403, "Ce média privé ne vous appartient pas")
            elif source_session.get("actor_key") != actor:
                raise HTTPException(403, "Ce média privé ne vous appartient pas")
            public = media_store.save_public_image_copy(media_store.read(source_id))
            item = store.add_community_media(post_id, actor, source_id, public["id"], public["path"], kind)
            if not item:
                raise HTTPException(403, "Média non autorisé")
            created_public.append(public["id"])
    except Exception:
        for public_id in created_public:
            media_store.delete(public_id)
        raise
    published = store.publish_community_post(post_id, actor)
    if not published:
        for public_id in created_public:
            media_store.delete(public_id)
        raise HTTPException(409, "Cette publication ne peut pas être publiée")
    return published

@app.delete("/v1/community/posts/{post_id}")
def delete_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    public_ids = store.delete_community_post(post_id, actor)
    if public_ids is None:
        raise HTTPException(403, "Publication introuvable ou non autorisée")
    for public_id in public_ids:
        media_store.delete(public_id)
    return {"deleted": True}

@app.get("/v1/community/media/{public_media_id}")
def get_public_community_media(public_media_id: str):
    item = store.get_community_media(public_media_id)
    if not item:
        raise HTTPException(404, "Média communautaire introuvable")
    try:
        return Response(content=media_store.read(public_media_id), media_type="image/jpeg", headers={"Cache-Control": "private, max-age=300"})
    except MediaError as exc:
        raise HTTPException(404, "Média communautaire introuvable") from exc

@app.get("/v1/community/posts/{post_id}/comments")
def list_community_comments(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    post = store.get_community_post(post_id, actor)
    if not post:
        raise HTTPException(404, "Publication introuvable")
    return {"comments": post.get("comments", [])}

@app.post("/v1/community/posts/{post_id}/comments")
def create_community_comment(request: Request, post_id: str, payload: CommunityCommentRequest, x_client_id: str | None = Header(default=None)):
    require_rate(request, "community_comment")
    actor = community_actor(x_client_id)
    status = community_moderation_status(payload.content)
    if status == "restricted":
        raise HTTPException(422, "Ce commentaire contient un conseil qui ne peut pas être publié")
    comment = store.add_community_comment(post_id, actor, payload.content.strip(), payload.parent_comment_id, status)
    if not comment:
        raise HTTPException(404, "Publication ou réponse introuvable")
    return comment

@app.delete("/v1/community/comments/{comment_id}")
def delete_community_comment(comment_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    if not store.delete_community_comment(comment_id, actor):
        raise HTTPException(403, "Commentaire introuvable ou non autorisé")
    return {"deleted": True}

@app.post("/v1/community/posts/{post_id}/helpful")
def helpful_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    result = store.toggle_community_helpful(post_id, actor, True)
    if not result: raise HTTPException(404, "Publication introuvable")
    return result

@app.delete("/v1/community/posts/{post_id}/helpful")
def remove_helpful_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    result = store.toggle_community_helpful(post_id, actor, False)
    if not result: raise HTTPException(404, "Publication introuvable")
    return result

@app.post("/v1/community/posts/{post_id}/save")
def save_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    result = store.toggle_community_saved(post_id, actor, True)
    if not result: raise HTTPException(404, "Publication introuvable")
    return result

@app.delete("/v1/community/posts/{post_id}/save")
def unsave_community_post(post_id: str, x_client_id: str | None = Header(default=None)):
    actor = community_actor(x_client_id)
    result = store.toggle_community_saved(post_id, actor, False)
    if not result: raise HTTPException(404, "Publication introuvable")
    return result

@app.post("/v1/community/reports")
def report_community_content(request: Request, payload: CommunityReportRequest, x_client_id: str | None = Header(default=None)):
    require_rate(request, "community_report")
    actor = community_actor(x_client_id)
    return store.create_community_report(actor, payload.model_dump())

@app.get("/v1/admin/leads")
def list_leads(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return store.list_leads()

@app.get("/v1/admin/diagnostics")
def list_diagnostics(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return store.list_sessions()

@app.get("/v1/admin/metrics")
def metrics(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    sessions = store.list_sessions()
    leads = store.list_leads()
    community = store.list_community_admin()
    reports = store.list_community_reports()
    return {"diagnostics": len(sessions), "leads": len(leads), "safety_stops": sum(1 for s in sessions if s.get("risk_level") in {"high", "emergency"}), "resolved": sum(1 for s in sessions if s.get("status") == "resolved"), "community_posts": len(community), "community_reports_pending": sum(1 for item in reports if item.get("status") == "pending")}

@app.get("/v1/admin/community/posts")
def admin_community_posts(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return {"posts": store.list_community_admin()}

@app.get("/v1/admin/community/reports")
def admin_community_reports(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return {"reports": store.list_community_reports()}

@app.patch("/v1/admin/community/posts/{post_id}/moderation")
def admin_moderate_community_post(post_id: str, payload: dict, x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    result = store.moderate_community_post(post_id, str(payload.get("moderation_status", "")))
    if not result:
        raise HTTPException(404, "Publication introuvable ou statut invalide")
    return result

@app.get("/v1/admin/professionals")
def list_professionals(x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return store.list_professionals()

@app.post("/v1/admin/professionals")
def create_professional(payload: ProfessionalInput, x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    return store.create_professional(payload.model_dump())

@app.patch("/v1/admin/professionals/{professional_id}")
def update_professional(professional_id: str, payload: ProfessionalUpdate, x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    result = store.update_professional(professional_id, payload.model_dump(exclude_unset=True))
    if not result:
        raise HTTPException(404, "Professionnel introuvable")
    return result

@app.patch("/v1/admin/leads/{lead_id}")
def update_lead(lead_id: str, status: str = Form(...), x_admin_token: str | None = Header(default=None)):
    require_admin(x_admin_token)
    if status not in {"new", "viewed", "accepted", "declined", "contacted", "won", "lost", "expired"}:
        raise HTTPException(422, "Statut de lead invalide")
    if not store.update_lead_status(lead_id, status):
        raise HTTPException(404, "Lead introuvable")
    return {"id": lead_id, "status": status}
