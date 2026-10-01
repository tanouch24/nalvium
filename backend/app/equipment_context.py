from __future__ import annotations


def build_equipment_context(store, equipment_id: str | None, query: str | None = None) -> dict | None:
    """Return the minimum factual context allowed into an assistant/diagnostic prompt."""
    if not equipment_id:
        return None
    equipment = store.get_equipment(equipment_id)
    if not equipment:
        return None
    history = []
    for repair in store.list_repairs(equipment_id=equipment_id)[:5]:
        history.append({
            "issue": repair.get("title"),
            "resolution": repair.get("summary"),
            "status": repair.get("status"),
            "date": repair.get("resolved_at") or repair.get("started_at"),
        })
    documents = []
    for document in store.list_documents(equipment_id)[:5]:
        documents.append({
            "type": document.get("document_type"),
            "title": document.get("display_name"),
            "date": document.get("document_date"),
            "status": document.get("extraction_status"),
        })
    warranties = [{"provider": item.get("provider"), "start_date": item.get("start_date"), "end_date": item.get("end_date"), "notes": item.get("notes")} for item in store.list_warranties(equipment_id)[:3]]
    maintenance = [{"title": item.get("title"), "performed_at": item.get("performed_at"), "next_due_at": item.get("next_due_at"), "status": item.get("status")} for item in store.list_maintenance(equipment_id)[:5]]
    passages = []
    if query and query.strip():
        passages = [{"document_id": chunk.get("document_id"), "text": chunk.get("text"), "metadata": chunk.get("metadata", {})} for chunk in store.search_document_chunks(equipment_id, query)[:3]]
    return {
        "equipment": {
            "category": equipment.get("category"),
            "subcategory": equipment.get("subcategory"),
            "display_name": equipment.get("display_name"),
            "brand": equipment.get("brand"),
            "model": equipment.get("model"),
            "room": equipment.get("room"),
        },
        "recent_history": history,
        "documents": documents,
        "warranties": warranties,
        "maintenance": maintenance,
        "document_passages": passages,
    }
