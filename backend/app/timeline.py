from __future__ import annotations

from datetime import datetime, timezone

def _event(kind: str, title: str, date: str | None, **extra) -> dict:
    return {"type": kind, "title": title, "date": date, **extra}

class HouseholdTimelineService:
    """Read-only aggregation of real records; it never duplicates them in DB."""
    def __init__(self, store):
        self.store = store

    def equipment(self, equipment_id: str) -> list[dict]:
        equipment = self.store.get_equipment(equipment_id)
        if not equipment:
            return []
        events = [_event("equipment_created", "Équipement ajouté à Ma Maison", equipment.get("created_at"))]
        for repair in equipment.get("repairs", []):
            events.append(_event("repair_resolved" if repair.get("status") == "resolved" else "diagnostic_started", repair.get("title") or "Diagnostic", repair.get("resolved_at") or repair.get("started_at"), status=repair.get("status"), session_id=repair.get("session_id")))
        for document in equipment.get("documents", []):
            events.append(_event("document_added", document.get("display_name") or "Document ajouté", document.get("created_at"), document_type=document.get("document_type")))
        for warranty in equipment.get("warranties", []):
            events.append(_event("warranty_added", "Garantie enregistrée", warranty.get("created_at"), end_date=warranty.get("end_date")))
        for maintenance in equipment.get("maintenance", []):
            events.append(_event("maintenance_recorded", maintenance.get("title") or "Entretien enregistré", maintenance.get("performed_at") or maintenance.get("created_at"), next_due_at=maintenance.get("next_due_at")))
        for session in self.store.list_sessions():
            if not session.get("messages") and session.get("id"):
                session = self.store.get_session(session["id"]) or session
            if session.get("equipment_id") != equipment_id:
                continue
            for message in session.get("messages", []):
                content = message.get("content", {})
                analysis = content.get("analysis") if isinstance(content, dict) else None
                if analysis:
                    events.append(_event("analysis_completed", "Diagnostic — analyse effectuée", message.get("created_at"), session_id=session.get("id"), status=session.get("status")))
            for verification in self.store.list_verifications(session.get("id")):
                events.append(_event("verification_completed", "Vérification — " + verification.get("status", "résultat"), verification.get("created_at"), session_id=session.get("id"), status=verification.get("status")))
        return sorted(events, key=lambda item: item.get("date") or "", reverse=True)

    def activity(self, limit: int = 30, offset: int = 0) -> list[dict]:
        events = []
        for equipment in self.store.list_equipments():
            events.extend(self.equipment(equipment["id"]))
        for session in self.store.list_sessions():
            if not session.get("equipment_id"):
                events.append(_event("diagnostic_started", "Diagnostic commencé", session.get("created_at"), session_id=session.get("id"), status=session.get("status")))
        events.sort(key=lambda item: item.get("date") or "", reverse=True)
        return events[offset:offset + limit]

    def active_sessions(self) -> list[dict]:
        return [item for item in self.store.list_active_sessions() if item.get("status") == "active"]
