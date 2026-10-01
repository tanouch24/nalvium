from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from uuid import uuid4

class MemoryStore:
    persistent = False
    def __init__(self):
        self.sessions: dict[str, dict] = {}
        self.media: dict[str, dict] = {}
        self.leads: dict[str, dict] = {}
        self.assistant_threads: dict[str, dict] = {}
        self.assistant_messages: dict[str, list[dict]] = {}
        self.equipments: dict[str, dict] = {}
        self.equipment_media: dict[str, list[dict]] = {}
        self.documents: dict[str, dict] = {}
        self.document_chunks: dict[str, list[dict]] = {}
        self.warranties: dict[str, dict] = {}
        self.maintenance: dict[str, dict] = {}
        self.verifications: dict[str, dict] = {}
        self.professional_dossiers: dict[str, dict] = {}
        self.shared_cases: list[dict] = []
        self.community_profiles: dict[str, dict] = {}
        self.community_posts: dict[str, dict] = {}
        self.community_post_media: dict[str, list[dict]] = {}
        self.community_comments: dict[str, dict] = {}
        self.community_reactions: set[tuple[str, str]] = set()
        self.community_saved_posts: set[tuple[str, str]] = set()
        self.community_reports: dict[str, dict] = {}

    def create_session(self, equipment_id: str | None = None, assistant_thread_id: str | None = None, actor_key: str | None = None) -> dict:
        session = {"id": str(uuid4()), "status": "active", "equipment_id": equipment_id, "assistant_thread_id": assistant_thread_id, "actor_key": actor_key, "messages": [], "media": [], "created_at": datetime.now(timezone.utc).isoformat()}
        self.sessions[session["id"]] = session
        return session

    def get_session(self, session_id: str) -> dict | None:
        return self.sessions.get(session_id)

    def add_media(self, session_id: str | None, media: dict) -> None:
        self.media[media["id"]] = media | {"session_id": session_id, "consent_for_pro": False}
        if session_id and session_id in self.sessions:
            self.sessions[session_id]["media"].append(self.media[media["id"]])

    def get_media(self, media_id: str) -> dict | None:
        return self.media.get(media_id)

    def add_message(self, session_id: str, role: str, content: dict) -> None:
        if session_id in self.sessions:
            self.sessions[session_id]["messages"].append({"role": role, "content": content, "created_at": datetime.now(timezone.utc).isoformat()})

    def save_analysis(self, session_id: str, analysis: dict) -> None:
        session = self.sessions.get(session_id)
        if session:
            session.update({"category": analysis.get("category"), "subcategory": analysis.get("subcategory"), "urgency": analysis.get("urgency"), "risk_level": analysis.get("risk", {}).get("level"), "diy_allowed": analysis.get("diy", {}).get("allowed")})
            if analysis.get("risk", {}).get("stop_diy"):
                session["status"] = "professional_required"
        self.add_message(session_id, "assistant", {"analysis": analysis})

    def update_session_status(self, session_id: str, status: str) -> dict | None:
        session = self.sessions.get(session_id)
        if not session:
            return None
        session["status"] = status
        if status == "resolved":
            session["resolved_at"] = datetime.now(timezone.utc).isoformat()
        return session

    def list_active_sessions(self) -> list[dict]:
        return [session for session in self.sessions.values() if session.get("status") == "active"]

    def list_verifications(self, session_id: str | None = None) -> list[dict]:
        items = list(self.verifications.values())
        if session_id:
            items = [item for item in items if item.get("session_id") == session_id]
        return sorted(items, key=lambda item: item.get("created_at", ""), reverse=True)

    def create_lead(self, request: dict, media_ids: list[str]) -> dict:
        lead = request | {"id": str(uuid4()), "status": "new", "media_transmitted": media_ids, "created_at": datetime.now(timezone.utc).isoformat()}
        self.leads[lead["id"]] = lead
        return lead

    def list_leads(self) -> list[dict]:
        return list(self.leads.values())

    def list_sessions(self) -> list[dict]:
        return list(self.sessions.values())

    def list_professionals(self) -> list[dict]:
        return getattr(self, "professionals", [])

    def create_professional(self, data: dict) -> dict:
        if not hasattr(self, "professionals"):
            self.professionals = []
        item = data | {"id": str(uuid4()), "verification_status": "unverified"}
        self.professionals.append(item)
        return item

    def update_lead_status(self, lead_id: str, status: str) -> bool:
        if lead_id not in self.leads:
            return False
        self.leads[lead_id]["status"] = status
        return True

    def update_professional(self, professional_id: str, data: dict) -> dict | None:
        for item in self.list_professionals():
            if item["id"] == professional_id:
                item.update({key: value for key, value in data.items() if value is not None})
                return item
        return None

    def delete_session(self, session_id: str) -> None:
        self.sessions.pop(session_id, None)

    def create_assistant_thread(self, context_type: str | None = None, context_id: str | None = None, equipment_id: str | None = None) -> dict:
        thread = {"id": str(uuid4()), "context_type": context_type, "context_id": context_id, "equipment_id": equipment_id, "created_at": datetime.now(timezone.utc).isoformat()}
        self.assistant_threads[thread["id"]] = thread
        self.assistant_messages[thread["id"]] = []
        return thread | {"messages": []}

    def get_assistant_thread(self, thread_id: str) -> dict | None:
        thread = self.assistant_threads.get(thread_id)
        if not thread:
            return None
        return thread | {"messages": list(self.assistant_messages.get(thread_id, []))}

    def add_assistant_message(self, thread_id: str, role: str, content: str, media_references: list[str] | None = None, context: dict | None = None) -> dict:
        message = {"id": str(uuid4()), "thread_id": thread_id, "role": role, "content": content, "media_references": media_references or [], "context": context, "created_at": datetime.now(timezone.utc).isoformat()}
        self.assistant_messages.setdefault(thread_id, []).append(message)
        return message

    def identify_equipment(self, identification: dict, primary_media_id: str | None = None) -> dict:
        return identification | {"primary_media_id": primary_media_id}

    def create_equipment(self, data: dict) -> dict:
        item = {key: value for key, value in data.items() if value is not None} | {"id": str(uuid4()), "created_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat(), "deleted_at": None}
        self.equipments[item["id"]] = item
        self.equipment_media[item["id"]] = []
        if item.get("primary_media_id"):
            self.add_equipment_media(item["id"], item["primary_media_id"], "primary")
        return self.get_equipment(item["id"])

    def get_equipment(self, equipment_id: str) -> dict | None:
        item = self.equipments.get(equipment_id)
        if not item or item.get("deleted_at"):
            return None
        return item | {"media": list(self.equipment_media.get(equipment_id, [])), "repairs": self.list_repairs(equipment_id=equipment_id), "documents": self.list_documents(equipment_id), "warranties": self.list_warranties(equipment_id), "maintenance": self.list_maintenance(equipment_id)}

    def list_equipments(self, room: str | None = None) -> list[dict]:
        items = [self.get_equipment(item["id"]) for item in self.equipments.values()]
        items = [item for item in items if item and (not room or item.get("room") == room)]
        return sorted(items, key=lambda item: item.get("updated_at", ""), reverse=True)

    def update_equipment(self, equipment_id: str, data: dict) -> dict | None:
        item = self.equipments.get(equipment_id)
        if not item or item.get("deleted_at"):
            return None
        item.update({key: value for key, value in data.items() if value is not None})
        item["updated_at"] = datetime.now(timezone.utc).isoformat()
        return self.get_equipment(equipment_id)

    def delete_equipment(self, equipment_id: str) -> bool:
        item = self.equipments.get(equipment_id)
        if not item or item.get("deleted_at"):
            return False
        item["deleted_at"] = datetime.now(timezone.utc).isoformat()
        return True

    def add_equipment_media(self, equipment_id: str, media_id: str, media_type: str) -> dict | None:
        if equipment_id not in self.equipments or self.equipments[equipment_id].get("deleted_at"):
            return None
        item = {"equipment_id": equipment_id, "media_id": media_id, "media_type": media_type}
        self.equipment_media.setdefault(equipment_id, []).append(item)
        if media_type == "primary":
            self.equipments[equipment_id]["primary_media_id"] = media_id
        return item

    def create_document(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        item = data | {"id": str(uuid4()), "equipment_id": equipment_id, "extraction_status": "pending", "created_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat()}
        self.documents[item["id"]] = item
        self.document_chunks[item["id"]] = []
        return item

    def get_document(self, document_id: str) -> dict | None:
        item = self.documents.get(document_id)
        if not item:
            return None
        return item | {"chunks": list(self.document_chunks.get(document_id, []))}

    def list_documents(self, equipment_id: str) -> list[dict]:
        return sorted([self.get_document(doc_id) for doc_id, item in self.documents.items() if item.get("equipment_id") == equipment_id], key=lambda item: item.get("created_at", ""), reverse=True)

    def update_document(self, document_id: str, data: dict) -> dict | None:
        item = self.documents.get(document_id)
        if not item:
            return None
        item.update({key: value for key, value in data.items() if value is not None})
        item["updated_at"] = datetime.now(timezone.utc).isoformat()
        return self.get_document(document_id)

    def delete_document(self, document_id: str) -> bool:
        if document_id not in self.documents:
            return False
        self.documents.pop(document_id)
        self.document_chunks.pop(document_id, None)
        return True

    def replace_document_chunks(self, document_id: str, chunks: list[dict]) -> None:
        self.document_chunks[document_id] = [chunk | {"id": str(uuid4()), "document_id": document_id, "created_at": datetime.now(timezone.utc).isoformat()} for chunk in chunks]

    def search_document_chunks(self, equipment_id: str, query: str) -> list[dict]:
        terms = [term.lower() for term in query.split() if len(term) > 2]
        return [chunk for document in self.list_documents(equipment_id) for chunk in document.get("chunks", []) if any(term in chunk.get("text", "").lower() for term in terms)][:5]

    def create_warranty(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        item = data | {"id": str(uuid4()), "equipment_id": equipment_id, "created_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat()}
        self.warranties[item["id"]] = item
        return item

    def list_warranties(self, equipment_id: str) -> list[dict]:
        return sorted([item for item in self.warranties.values() if item.get("equipment_id") == equipment_id], key=lambda item: item.get("end_date") or "", reverse=True)

    def update_warranty(self, warranty_id: str, data: dict) -> dict | None:
        item = self.warranties.get(warranty_id)
        if not item:
            return None
        item.update({key: value for key, value in data.items() if value is not None})
        item["updated_at"] = datetime.now(timezone.utc).isoformat()
        return item

    def delete_warranty(self, warranty_id: str) -> bool:
        return self.warranties.pop(warranty_id, None) is not None

    def create_maintenance(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        item = data | {"id": str(uuid4()), "equipment_id": equipment_id, "created_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat()}
        self.maintenance[item["id"]] = item
        return item

    def list_maintenance(self, equipment_id: str) -> list[dict]:
        return sorted([item for item in self.maintenance.values() if item.get("equipment_id") == equipment_id], key=lambda item: item.get("performed_at") or item.get("created_at", ""), reverse=True)

    def update_maintenance(self, maintenance_id: str, data: dict) -> dict | None:
        item = self.maintenance.get(maintenance_id)
        if not item:
            return None
        item.update({key: value for key, value in data.items() if value is not None})
        item["updated_at"] = datetime.now(timezone.utc).isoformat()
        return item

    def delete_maintenance(self, maintenance_id: str) -> bool:
        return self.maintenance.pop(maintenance_id, None) is not None

    def create_repair(self, data: dict) -> dict:
        item = data | {
            "id": str(uuid4()),
            "started_at": datetime.now(timezone.utc).isoformat(),
            "resolved_at": datetime.now(timezone.utc).isoformat() if data.get("status") == "resolved" else None,
            "share_status": "private",
        }
        if not hasattr(self, "repairs"):
            self.repairs = {}
        self.repairs[item["id"]] = item
        return item

    def update_repair(self, repair_id: str, data: dict) -> dict | None:
        item = getattr(self, "repairs", {}).get(repair_id)
        if not item:
            return None
        item.update({key: value for key, value in data.items() if value is not None})
        if item.get("status") == "resolved" and not item.get("resolved_at"):
            item["resolved_at"] = datetime.now(timezone.utc).isoformat()
        return item

    def list_repairs(self, session_id: str | None = None, equipment_id: str | None = None) -> list[dict]:
        items = list(getattr(self, "repairs", {}).values())
        if session_id:
            items = [item for item in items if item.get("session_id") == session_id]
        if equipment_id:
            items = [item for item in items if item.get("equipment_id") == equipment_id]
        return sorted(items, key=lambda item: item.get("started_at", ""), reverse=True)

    def share_repair(self, repair_id: str, data: dict) -> dict | None:
        item = getattr(self, "repairs", {}).get(repair_id)
        if not item:
            return None
        item["share_status"] = "consented"
        case = {"id": str(uuid4()), "repair_record_id": repair_id, "category": item.get("category", "other"), "problem_summary": item.get("summary", ""), "solution_summary": item.get("title", ""), "before_media_public_reference": None, "after_media_public_reference": None, "created_at": datetime.now(timezone.utc).isoformat()}
        self.shared_cases.append(case)
        return case

    def create_verification(self, data: dict) -> dict:
        item = data | {"id": str(uuid4()), "created_at": datetime.now(timezone.utc).isoformat()}
        self.verifications[item["id"]] = item
        return item

    def create_professional_dossier(self, data: dict) -> dict:
        item = data | {"id": str(uuid4()), "status": "ready", "created_at": datetime.now(timezone.utc).isoformat()}
        self.professional_dossiers[item["id"]] = item
        return item

    def list_similar_cases(self, category: str, subcategory: str | None = None, limit: int = 3) -> list[dict]:
        cases = [case for case in self.shared_cases if case.get("category") == category]
        return [{"category": c.get("category"), "problem_summary": c.get("problem_summary", ""), "solution_summary": c.get("solution_summary", "")} for c in cases[:limit]]

    # Community data is deliberately separate from shared_cases.
    def ensure_community_profile(self, actor_key: str, handle: str | None = None) -> dict:
        profile = self.community_profiles.get(actor_key)
        if profile:
            return profile
        profile = {"actor_key": actor_key, "handle": (handle or "Membre Nalvium")[:60], "created_at": datetime.now(timezone.utc).isoformat()}
        self.community_profiles[actor_key] = profile
        return profile

    def create_community_post(self, actor_key: str, data: dict, moderation_status: str = "approved") -> dict:
        self.ensure_community_profile(actor_key)
        post = data | {"id": str(uuid4()), "actor_key": actor_key, "author_handle": self.community_profiles[actor_key]["handle"], "status": "draft", "moderation_status": moderation_status, "created_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat(), "published_at": None}
        self.community_posts[post["id"]] = post
        self.community_post_media[post["id"]] = []
        return self.get_community_post(post["id"], actor_key)

    def get_community_post(self, post_id: str, actor_key: str | None = None) -> dict | None:
        post = self.community_posts.get(post_id)
        if not post:
            return None
        if post.get("status") == "deleted" or (post.get("status") != "published" and actor_key != post.get("actor_key")):
            return None
        comments = [self._community_comment(item, actor_key) for item in self.community_comments.values() if item.get("post_id") == post_id and not item.get("deleted_at") and item.get("moderation_status") == "approved"]
        return post | {"media": list(self.community_post_media.get(post_id, [])), "comments": sorted(comments, key=lambda item: item.get("created_at", "")), "helpful_count": sum(1 for item in self.community_reactions if item[0] == post_id), "helpful": (post_id, actor_key) in self.community_reactions if actor_key else False, "saved": (post_id, actor_key) in self.community_saved_posts if actor_key else False}

    def _community_comment(self, comment: dict, actor_key: str | None = None) -> dict:
        return comment | {"author_handle": self.community_profiles.get(comment.get("actor_key"), {}).get("handle", "Membre Nalvium"), "mine": actor_key == comment.get("actor_key")}

    def list_community_posts(self, actor_key: str, query: str = "", category: str | None = None, offset: int = 0, limit: int = 20, saved: bool = False) -> list[dict]:
        query = query.lower().strip()
        posts = [post for post in self.community_posts.values() if post.get("status") == "published" and post.get("moderation_status") == "approved"]
        if saved:
            posts = [post for post in posts if (post["id"], actor_key) in self.community_saved_posts]
        if category and category != "all":
            posts = [post for post in posts if post.get("category") == category]
        if query:
            posts = [post for post in posts if query in " ".join(str(post.get(key, "")) for key in ("title", "category", "equipment_type", "problem_summary", "solution_summary")).lower()]
        posts.sort(key=lambda item: item.get("published_at") or "", reverse=True)
        return [self.get_community_post(post["id"], actor_key) for post in posts[offset:offset + limit]]

    def update_community_post(self, post_id: str, actor_key: str, data: dict) -> dict | None:
        post = self.community_posts.get(post_id)
        if not post or post.get("actor_key") != actor_key or post.get("status") == "deleted":
            return None
        post.update({key: value for key, value in data.items() if value is not None})
        post["updated_at"] = datetime.now(timezone.utc).isoformat()
        return self.get_community_post(post_id, actor_key)

    def publish_community_post(self, post_id: str, actor_key: str) -> dict | None:
        post = self.community_posts.get(post_id)
        if not post or post.get("actor_key") != actor_key or post.get("moderation_status") != "approved":
            return None
        post.update({"status": "published", "published_at": datetime.now(timezone.utc).isoformat(), "updated_at": datetime.now(timezone.utc).isoformat()})
        return self.get_community_post(post_id, actor_key)

    def delete_community_post(self, post_id: str, actor_key: str) -> list[str] | None:
        post = self.community_posts.get(post_id)
        if not post or post.get("actor_key") != actor_key:
            return None
        post["status"] = "deleted"
        return [item["public_media_id"] for item in self.community_post_media.get(post_id, [])]

    def add_community_media(self, post_id: str, actor_key: str, source_media_id: str | None, public_media_id: str, storage_key: str, media_kind: str) -> dict | None:
        post = self.community_posts.get(post_id)
        if not post or post.get("actor_key") != actor_key or media_kind not in {"before", "after", "additional"}:
            return None
        item = {"id": str(uuid4()), "post_id": post_id, "source_media_id": source_media_id, "public_media_id": public_media_id, "storage_key": storage_key, "media_kind": media_kind}
        self.community_post_media.setdefault(post_id, []).append(item)
        return item

    def add_community_comment(self, post_id: str, actor_key: str, content: str, parent_comment_id: str | None, moderation_status: str = "approved") -> dict | None:
        if not self.get_community_post(post_id):
            return None
        if parent_comment_id and (parent_comment_id not in self.community_comments or self.community_comments[parent_comment_id].get("post_id") != post_id):
            return None
        item = {"id": str(uuid4()), "post_id": post_id, "actor_key": actor_key, "parent_comment_id": parent_comment_id, "content": content, "moderation_status": moderation_status, "created_at": datetime.now(timezone.utc).isoformat(), "deleted_at": None}
        self.ensure_community_profile(actor_key)
        self.community_comments[item["id"]] = item
        return self._community_comment(item, actor_key)

    def delete_community_comment(self, comment_id: str, actor_key: str) -> bool:
        item = self.community_comments.get(comment_id)
        if not item or item.get("actor_key") != actor_key:
            return False
        item["deleted_at"] = datetime.now(timezone.utc).isoformat()
        item["content"] = "Commentaire supprimé"
        return True

    def toggle_community_helpful(self, post_id: str, actor_key: str, enabled: bool) -> dict | None:
        if not self.get_community_post(post_id):
            return None
        key = (post_id, actor_key)
        if enabled: self.community_reactions.add(key)
        else: self.community_reactions.discard(key)
        return self.get_community_post(post_id, actor_key)

    def toggle_community_saved(self, post_id: str, actor_key: str, enabled: bool) -> dict | None:
        if not self.get_community_post(post_id):
            return None
        key = (post_id, actor_key)
        if enabled: self.community_saved_posts.add(key)
        else: self.community_saved_posts.discard(key)
        return self.get_community_post(post_id, actor_key)

    def create_community_report(self, actor_key: str, data: dict) -> dict:
        item = data | {"id": str(uuid4()), "actor_key": actor_key, "status": "pending", "created_at": datetime.now(timezone.utc).isoformat()}
        self.community_reports[item["id"]] = item
        return {key: value for key, value in item.items() if key != "actor_key"}

    def list_community_admin(self) -> list[dict]:
        return [self.get_community_post(item["id"], item.get("actor_key")) for item in self.community_posts.values() if item.get("status") != "deleted"]

    def list_community_reports(self) -> list[dict]:
        return [{key: value for key, value in item.items() if key != "actor_key"} for item in self.community_reports.values()]

    def moderate_community_post(self, post_id: str, moderation_status: str) -> dict | None:
        post = self.community_posts.get(post_id)
        if not post or moderation_status not in {"approved", "restricted", "removed"}:
            return None
        post["moderation_status"] = moderation_status
        if moderation_status == "removed": post["status"] = "hidden"
        post["updated_at"] = datetime.now(timezone.utc).isoformat()
        return self.get_community_post(post_id, post.get("actor_key"))

    def get_community_media(self, public_media_id: str) -> dict | None:
        for post_id, media_items in self.community_post_media.items():
            post = self.community_posts.get(post_id, {})
            if post.get("status") == "published" and post.get("moderation_status") == "approved":
                for item in media_items:
                    if item.get("public_media_id") == public_media_id:
                        return item
        return None

class PostgresStore(MemoryStore):
    persistent = True
    def __init__(self, url: str):
        import psycopg
        self.url = url
        with psycopg.connect(url) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")

    def _connect(self):
        import psycopg
        return psycopg.connect(self.url)

    def create_session(self, equipment_id: str | None = None, assistant_thread_id: str | None = None, actor_key: str | None = None) -> dict:
        session_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO diagnostic_sessions (id, status, equipment_id, assistant_thread_id, actor_key) VALUES (%s, 'active', %s, %s, %s)", (session_id, equipment_id, assistant_thread_id, actor_key))
        return {"id": session_id, "status": "active", "equipment_id": equipment_id, "assistant_thread_id": assistant_thread_id, "actor_key": actor_key, "messages": [], "media": []}

    def get_session(self, session_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, status, category, subcategory, urgency, risk_level, diy_allowed, equipment_id::text, assistant_thread_id::text, actor_key, created_at, resolved_at FROM diagnostic_sessions WHERE id=%s", (session_id,))
            row = cur.fetchone()
            if not row:
                return None
            cur.execute("SELECT role, content_json, created_at FROM diagnostic_messages WHERE session_id=%s ORDER BY created_at", (session_id,))
            messages = [{"role": r[0], "content": r[1], "created_at": r[2].isoformat()} for r in cur.fetchall()]
            cur.execute("SELECT id::text, storage_key, media_type, consent_for_pro FROM diagnostic_media WHERE session_id=%s AND deleted_at IS NULL", (session_id,))
            media = [{"id": r[0], "storage_key": r[1], "media_type": r[2], "consent_for_pro": r[3]} for r in cur.fetchall()]
            return {"id": row[0], "status": row[1], "category": row[2], "subcategory": row[3], "urgency": row[4], "risk_level": row[5], "diy_allowed": row[6], "equipment_id": row[7], "assistant_thread_id": row[8], "actor_key": row[9], "created_at": row[10].isoformat(), "resolved_at": row[11].isoformat() if row[11] else None, "messages": messages, "media": media}

    def add_media(self, session_id: str | None, media: dict) -> None:
        if not session_id:
            return
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO diagnostic_media (id, session_id, storage_key, media_type, byte_size, duration_ms) VALUES (%s,%s,%s,%s,%s,%s)", (media["id"], session_id, media["path"], media["media_type"], media.get("byte_size"), media.get("duration_ms")))

    def get_media(self, media_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, session_id::text, storage_key, media_type, consent_for_pro, byte_size, duration_ms, width, height FROM diagnostic_media WHERE id=%s AND deleted_at IS NULL", (media_id,))
            row = cur.fetchone()
            return None if not row else {"id": row[0], "session_id": row[1], "path": row[2], "media_type": row[3], "consent_for_pro": row[4], "byte_size": row[5], "duration_ms": row[6], "width": row[7], "height": row[8]}

    def create_equipment(self, data: dict) -> dict:
        equipment_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("""INSERT INTO equipments
                (id, category, subcategory, display_name, brand, model, serial_number, room, notes, primary_media_id, identification_confidence, identification_source, purchase_date, purchase_price, purchase_currency, seller)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", (equipment_id, data["category"], data.get("subcategory"), data["display_name"], data.get("brand"), data.get("model"), data.get("serial_number"), data.get("room"), data.get("notes"), data.get("primary_media_id"), data.get("identification_confidence"), data.get("identification_source"), data.get("purchase_date"), data.get("purchase_price"), data.get("purchase_currency"), data.get("seller")))
        return self.get_equipment(equipment_id)

    def get_equipment(self, equipment_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, category, subcategory, display_name, brand, model, serial_number, room, notes, primary_media_id::text, identification_confidence, identification_source, purchase_date, purchase_price, purchase_currency, seller, created_at, updated_at FROM equipments WHERE id=%s AND deleted_at IS NULL", (equipment_id,))
            row = cur.fetchone()
            if not row:
                return None
            cur.execute("SELECT media_id::text, media_type FROM equipment_media WHERE equipment_id=%s ORDER BY created_at", (equipment_id,))
            media = [{"equipment_id": equipment_id, "media_id": r[0], "media_type": r[1]} for r in cur.fetchall()]
            return {"id": row[0], "category": row[1], "subcategory": row[2], "display_name": row[3], "brand": row[4], "model": row[5], "serial_number": row[6], "room": row[7], "notes": row[8], "primary_media_id": row[9], "identification_confidence": row[10], "identification_source": row[11], "purchase_date": row[12].isoformat() if row[12] else None, "purchase_price": float(row[13]) if row[13] is not None else None, "purchase_currency": row[14], "seller": row[15], "created_at": row[16].isoformat(), "updated_at": row[17].isoformat(), "media": media, "repairs": self.list_repairs(equipment_id=equipment_id), "documents": self.list_documents(equipment_id), "warranties": self.list_warranties(equipment_id), "maintenance": self.list_maintenance(equipment_id)}

    def create_document(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        document_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("""INSERT INTO equipment_documents
                (id, equipment_id, media_id, document_type, display_name, mime_type, original_filename, document_date, extracted_text, extraction_status, extraction_json)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", (document_id, equipment_id, data["media_id"], data.get("document_type", "other"), data["display_name"], data["mime_type"], data.get("original_filename"), data.get("document_date"), data.get("extracted_text"), data.get("extraction_status", "pending"), json.dumps(data.get("extraction_json"), ensure_ascii=False) if data.get("extraction_json") else None))
        return self.get_document(document_id)

    def get_document(self, document_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, equipment_id::text, media_id::text, document_type, display_name, mime_type, original_filename, document_date, extracted_text, extraction_status, extraction_json, created_at, updated_at FROM equipment_documents WHERE id=%s", (document_id,))
            row = cur.fetchone()
            if not row:
                return None
            cur.execute("SELECT id::text, chunk_index, text, metadata, created_at FROM equipment_document_chunks WHERE document_id=%s ORDER BY chunk_index", (document_id,))
            chunks = [{"id": c[0], "document_id": document_id, "chunk_index": c[1], "text": c[2], "metadata": c[3], "created_at": c[4].isoformat()} for c in cur.fetchall()]
            return {"id": row[0], "equipment_id": row[1], "media_id": row[2], "document_type": row[3], "display_name": row[4], "mime_type": row[5], "original_filename": row[6], "document_date": row[7].isoformat() if row[7] else None, "extracted_text": row[8], "extraction_status": row[9], "extraction_json": row[10], "created_at": row[11].isoformat(), "updated_at": row[12].isoformat(), "chunks": chunks}

    def list_documents(self, equipment_id: str) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text FROM equipment_documents WHERE equipment_id=%s ORDER BY created_at DESC", (equipment_id,))
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_document(document_id) for document_id in ids]

    def update_document(self, document_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            return self.get_document(document_id)
        fields = ", ".join(f"{key}=%s" for key in allowed) + ", updated_at=now()"
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE equipment_documents SET {fields} WHERE id=%s", (*allowed.values(), document_id))
            if cur.rowcount != 1:
                return None
        return self.get_document(document_id)

    def delete_document(self, document_id: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM equipment_documents WHERE id=%s", (document_id,))
            return cur.rowcount == 1

    def replace_document_chunks(self, document_id: str, chunks: list[dict]) -> None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM equipment_document_chunks WHERE document_id=%s", (document_id,))
            for chunk in chunks:
                cur.execute("INSERT INTO equipment_document_chunks (document_id, chunk_index, text, metadata) VALUES (%s,%s,%s,%s)", (document_id, chunk["chunk_index"], chunk["text"], json.dumps(chunk.get("metadata", {}), ensure_ascii=False)))

    def search_document_chunks(self, equipment_id: str, query: str) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("""SELECT c.id::text, c.document_id::text, c.chunk_index, c.text, c.metadata
                FROM equipment_document_chunks c JOIN equipment_documents d ON d.id=c.document_id
                WHERE d.equipment_id=%s AND to_tsvector('simple', c.text) @@ plainto_tsquery('simple', %s)
                ORDER BY c.chunk_index LIMIT 5""", (equipment_id, query))
            return [{"id": row[0], "document_id": row[1], "chunk_index": row[2], "text": row[3], "metadata": row[4]} for row in cur.fetchall()]

    def create_warranty(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        warranty_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO equipment_warranties (id, equipment_id, source_document_id, provider, start_date, end_date, notes) VALUES (%s,%s,%s,%s,%s,%s,%s)", (warranty_id, equipment_id, data.get("source_document_id"), data.get("provider"), data.get("start_date"), data.get("end_date"), data.get("notes")))
        return self.get_warranty(warranty_id)

    def get_warranty(self, warranty_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, equipment_id::text, source_document_id::text, provider, start_date, end_date, notes, created_at, updated_at FROM equipment_warranties WHERE id=%s", (warranty_id,))
            row = cur.fetchone()
            return None if not row else {"id": row[0], "equipment_id": row[1], "source_document_id": row[2], "provider": row[3], "start_date": row[4].isoformat() if row[4] else None, "end_date": row[5].isoformat() if row[5] else None, "notes": row[6], "created_at": row[7].isoformat(), "updated_at": row[8].isoformat()}

    def list_warranties(self, equipment_id: str) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text FROM equipment_warranties WHERE equipment_id=%s ORDER BY end_date DESC NULLS LAST", (equipment_id,))
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_warranty(warranty_id) for warranty_id in ids]

    def update_warranty(self, warranty_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            return self.get_warranty(warranty_id)
        fields = ", ".join(f"{key}=%s" for key in allowed) + ", updated_at=now()"
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE equipment_warranties SET {fields} WHERE id=%s", (*allowed.values(), warranty_id))
            if cur.rowcount != 1:
                return None
        return self.get_warranty(warranty_id)

    def delete_warranty(self, warranty_id: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM equipment_warranties WHERE id=%s", (warranty_id,))
            return cur.rowcount == 1

    def create_maintenance(self, equipment_id: str, data: dict) -> dict | None:
        if not self.get_equipment(equipment_id):
            return None
        maintenance_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO equipment_maintenance (id, equipment_id, title, description, maintenance_type, performed_at, next_due_at, status, source) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)", (maintenance_id, equipment_id, data["title"], data.get("description"), data.get("maintenance_type", "other"), data.get("performed_at"), data.get("next_due_at"), data.get("status", "completed"), data.get("source", "user")))
        return self.get_maintenance(maintenance_id)

    def get_maintenance(self, maintenance_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, equipment_id::text, title, description, maintenance_type, performed_at, next_due_at, status, source, created_at, updated_at FROM equipment_maintenance WHERE id=%s", (maintenance_id,))
            row = cur.fetchone()
            return None if not row else {"id": row[0], "equipment_id": row[1], "title": row[2], "description": row[3], "maintenance_type": row[4], "performed_at": row[5].isoformat() if row[5] else None, "next_due_at": row[6].isoformat() if row[6] else None, "status": row[7], "source": row[8], "created_at": row[9].isoformat(), "updated_at": row[10].isoformat()}

    def list_maintenance(self, equipment_id: str) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text FROM equipment_maintenance WHERE equipment_id=%s ORDER BY COALESCE(performed_at, created_at) DESC", (equipment_id,))
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_maintenance(maintenance_id) for maintenance_id in ids]

    def update_maintenance(self, maintenance_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            return self.get_maintenance(maintenance_id)
        fields = ", ".join(f"{key}=%s" for key in allowed) + ", updated_at=now()"
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE equipment_maintenance SET {fields} WHERE id=%s", (*allowed.values(), maintenance_id))
            if cur.rowcount != 1:
                return None
        return self.get_maintenance(maintenance_id)

    def delete_maintenance(self, maintenance_id: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM equipment_maintenance WHERE id=%s", (maintenance_id,))
            return cur.rowcount == 1

    def list_equipments(self, room: str | None = None) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            query = "SELECT id::text FROM equipments WHERE deleted_at IS NULL"
            params: tuple = ()
            if room:
                query += " AND room=%s"
                params = (room,)
            query += " ORDER BY updated_at DESC"
            cur.execute(query, params)
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_equipment(equipment_id) for equipment_id in ids]

    def update_equipment(self, equipment_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            return self.get_equipment(equipment_id)
        fields = ", ".join(f"{key}=%s" for key in allowed) + ", updated_at=now()"
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE equipments SET {fields} WHERE id=%s AND deleted_at IS NULL", (*allowed.values(), equipment_id))
            if cur.rowcount != 1:
                return None
        return self.get_equipment(equipment_id)

    def delete_equipment(self, equipment_id: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE equipments SET deleted_at=COALESCE(deleted_at, now()), updated_at=now() WHERE id=%s AND deleted_at IS NULL", (equipment_id,))
            return cur.rowcount == 1

    def add_equipment_media(self, equipment_id: str, media_id: str, media_type: str) -> dict | None:
        if not self.get_equipment(equipment_id) or not self.get_media(media_id):
            return None
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO equipment_media (equipment_id, media_id, media_type) VALUES (%s,%s,%s) ON CONFLICT (equipment_id, media_id) DO UPDATE SET media_type=EXCLUDED.media_type", (equipment_id, media_id, media_type))
            if media_type == "primary":
                cur.execute("UPDATE equipments SET primary_media_id=%s, updated_at=now() WHERE id=%s", (media_id, equipment_id))
        return {"equipment_id": equipment_id, "media_id": media_id, "media_type": media_type}

    def add_message(self, session_id: str, role: str, content: dict) -> None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO diagnostic_messages (session_id, role, type, content_json) VALUES (%s,%s,%s,%s)", (session_id, role, "analysis", json.dumps(content, ensure_ascii=False)))

    def save_analysis(self, session_id: str, analysis: dict) -> None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE diagnostic_sessions SET category=%s, subcategory=%s, urgency=%s, risk_level=%s, diy_allowed=%s WHERE id=%s", (analysis["category"], analysis["subcategory"], analysis["urgency"], analysis["risk"]["level"], analysis["diy"]["allowed"], session_id))
            if analysis.get("risk", {}).get("stop_diy"):
                cur.execute("UPDATE diagnostic_sessions SET status='professional_required' WHERE id=%s", (session_id,))
            cur.execute("INSERT INTO diagnostic_messages (session_id, role, type, content_json) VALUES (%s,%s,%s,%s)", (session_id, "assistant", "analysis", json.dumps(analysis, ensure_ascii=False)))

    def update_session_status(self, session_id: str, status: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE diagnostic_sessions SET status=%s, resolved_at=CASE WHEN %s='resolved' THEN COALESCE(resolved_at, now()) ELSE resolved_at END WHERE id=%s", (status, status, session_id))
            if cur.rowcount != 1:
                return None
        return self.get_session(session_id)

    def list_active_sessions(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text FROM diagnostic_sessions WHERE status='active' ORDER BY created_at DESC LIMIT 20")
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_session(item) for item in ids]

    def list_verifications(self, session_id: str | None = None) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            query = "SELECT id::text, session_id::text, before_media_id::text, after_media_id::text, status, observations, remaining_issue, risk_level, next_action, requires_professional, request_another_photo, created_at FROM repair_verifications"
            params: tuple = ()
            if session_id:
                query += " WHERE session_id=%s"
                params = (session_id,)
            query += " ORDER BY created_at DESC"
            cur.execute(query, params)
            return [{"id": row[0], "session_id": row[1], "before_media_id": row[2], "after_media_id": row[3], "status": row[4], "observations": row[5], "remaining_issue": row[6], "risk": row[7], "next_action": row[8], "requires_professional": row[9], "request_another_photo": row[10], "created_at": row[11].isoformat()} for row in cur.fetchall()]

    def create_lead(self, request: dict, media_ids: list[str]) -> dict:
        lead_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO leads (id, session_id, first_name, phone, city, postal_code, desired_time_window, trade, summary, urgency, consent_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,now())", (lead_id, request["session_id"], request["first_name"], request["phone"], request["city"], request["postal_code"], request["desired_time_window"], request["trade"], request["summary"], request["urgency"]))
            for media_id in media_ids:
                cur.execute("UPDATE diagnostic_media SET consent_for_pro=true WHERE id=%s AND session_id=%s", (media_id, request["session_id"]))
            cur.execute("INSERT INTO consent_events (subject_id, consent_type, version, granted) VALUES (%s,'lead_transmission','v1',true)", (lead_id,))
        return request | {"id": lead_id, "status": "new", "media_transmitted": media_ids}

    def list_leads(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, session_id::text, first_name, phone, city, postal_code, desired_time_window, trade, summary, urgency, status, created_at FROM leads ORDER BY created_at DESC")
            return [{"id": r[0], "session_id": r[1], "first_name": r[2], "phone": r[3], "city": r[4], "postal_code": r[5], "desired_time_window": r[6], "trade": r[7], "summary": r[8], "urgency": r[9], "status": r[10], "created_at": r[11].isoformat()} for r in cur.fetchall()]

    def list_sessions(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, status, category, subcategory, risk_level, equipment_id::text, created_at, resolved_at FROM diagnostic_sessions ORDER BY created_at DESC LIMIT 100")
            return [{"id": r[0], "status": r[1], "category": r[2], "subcategory": r[3], "risk_level": r[4], "equipment_id": r[5], "created_at": r[6].isoformat(), "resolved_at": r[7].isoformat() if r[7] else None} for r in cur.fetchall()]

    def list_professionals(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, business_name, legal_name, phone, email, verification_status, active FROM professionals ORDER BY business_name")
            return [{"id": r[0], "business_name": r[1], "legal_name": r[2], "phone": r[3], "email": r[4], "verification_status": r[5], "active": r[6]} for r in cur.fetchall()]

    def create_professional(self, data: dict) -> dict:
        professional_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO professionals (id, business_name, legal_name, phone, email) VALUES (%s,%s,%s,%s,%s)", (professional_id, data["business_name"], data["legal_name"], data["phone"], data["email"]))
            cur.execute("INSERT INTO professional_trades (professional_id, trade) VALUES (%s,%s)", (professional_id, data["trade"]))
            cur.execute("INSERT INTO professional_zones (professional_id, postal_prefix) VALUES (%s,%s)", (professional_id, data["city"]))
        return data | {"id": professional_id, "verification_status": "unverified"}

    def update_lead_status(self, lead_id: str, status: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE leads SET status=%s WHERE id=%s", (status, lead_id))
            return cur.rowcount == 1

    def update_professional(self, professional_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            return next((p for p in self.list_professionals() if p["id"] == professional_id), None)
        fields = ", ".join(f"{key}=%s" for key in allowed)
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE professionals SET {fields} WHERE id=%s", (*allowed.values(), professional_id))
            if cur.rowcount != 1:
                return None
        return next((p for p in self.list_professionals() if p["id"] == professional_id), None)

    def delete_session(self, session_id: str) -> None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM diagnostic_sessions WHERE id=%s", (session_id,))

    def create_assistant_thread(self, context_type: str | None = None, context_id: str | None = None, equipment_id: str | None = None) -> dict:
        thread_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO assistant_threads (id, context_type, context_id, equipment_id) VALUES (%s,%s,%s,%s)", (thread_id, context_type, context_id, equipment_id))
        return {"id": thread_id, "context_type": context_type, "context_id": context_id, "equipment_id": equipment_id, "messages": []}

    def get_assistant_thread(self, thread_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, context_type, context_id, equipment_id::text, created_at FROM assistant_threads WHERE id=%s", (thread_id,))
            row = cur.fetchone()
            if not row:
                return None
            cur.execute("SELECT id::text, role, content, media_references, context_json, created_at FROM assistant_messages WHERE thread_id=%s ORDER BY created_at", (thread_id,))
            messages = [{"id": r[0], "thread_id": thread_id, "role": r[1], "content": r[2], "media_references": r[3] or [], "context": r[4], "created_at": r[5].isoformat()} for r in cur.fetchall()]
            return {"id": row[0], "context_type": row[1], "context_id": row[2], "equipment_id": row[3], "created_at": row[4].isoformat(), "messages": messages}

    def add_assistant_message(self, thread_id: str, role: str, content: str, media_references: list[str] | None = None, context: dict | None = None) -> dict:
        message_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO assistant_messages (id, thread_id, role, content, media_references, context_json) VALUES (%s,%s,%s,%s,%s,%s)", (message_id, thread_id, role, content, media_references or [], json.dumps(context, ensure_ascii=False) if context else None))
        return {"id": message_id, "thread_id": thread_id, "role": role, "content": content, "media_references": media_references or [], "context": context}

    def create_repair(self, data: dict) -> dict:
        repair_id = str(uuid4())
        status = data.get("status", "in_progress")
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(
                """INSERT INTO repair_records
                (id, session_id, equipment_id, category, title, summary, before_media_id, after_media_id, status, steps_completed, professional_required, resolved_at)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,CASE WHEN %s='resolved' THEN now() ELSE NULL END)""",
                (repair_id, data["session_id"], data.get("equipment_id"), data.get("category", "other"), data["title"], data.get("summary", ""), data.get("before_media_id"), data.get("after_media_id"), status, json.dumps(data.get("steps_completed", [])), data.get("professional_required", False), status),
            )
        return {**data, "id": repair_id, "share_status": "private"}

    def update_repair(self, repair_id: str, data: dict) -> dict | None:
        allowed = {key: value for key, value in data.items() if value is not None}
        if not allowed:
            rows = self.list_repairs()
            return next((row for row in rows if row["id"] == repair_id), None)
        fields = []
        values = []
        for key, value in allowed.items():
            if key == "steps_completed":
                fields.append("steps_completed=%s")
                values.append(json.dumps(value))
            else:
                fields.append(f"{key}=%s")
                values.append(value)
        if allowed.get("status") == "resolved":
            fields.append("resolved_at=COALESCE(resolved_at, now())")
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE repair_records SET {', '.join(fields)} WHERE id=%s", (*values, repair_id))
            if cur.rowcount != 1:
                return None
        return next((row for row in self.list_repairs() if row["id"] == repair_id), None)

    def list_repairs(self, session_id: str | None = None, equipment_id: str | None = None) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            query = "SELECT id::text, session_id::text, equipment_id::text, category, title, summary, before_media_id::text, after_media_id::text, started_at, resolved_at, status, steps_completed, professional_required, share_status FROM repair_records"
            params: tuple = ()
            if session_id:
                query += " WHERE session_id=%s"
                params = (session_id,)
            if equipment_id:
                query += " WHERE equipment_id=%s" if not session_id else " AND equipment_id=%s"
                params = (*params, equipment_id)
            query += " ORDER BY started_at DESC"
            cur.execute(query, params)
            return [{"id": r[0], "session_id": r[1], "equipment_id": r[2], "category": r[3], "title": r[4], "summary": r[5], "before_media_id": r[6], "after_media_id": r[7], "started_at": r[8].isoformat(), "resolved_at": r[9].isoformat() if r[9] else None, "status": r[10], "steps_completed": r[11], "professional_required": r[12], "share_status": r[13]} for r in cur.fetchall()]

    def share_repair(self, repair_id: str, data: dict) -> dict | None:
        repair = next((row for row in self.list_repairs() if row["id"] == repair_id), None)
        if not repair:
            return None
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE repair_records SET share_status='consented' WHERE id=%s", (repair_id,))
            case_id = str(uuid4())
            cur.execute("INSERT INTO shared_cases (id, repair_record_id, category, problem_summary, solution_summary) VALUES (%s,%s,%s,%s,%s)", (case_id, repair_id, repair["category"], repair["summary"], repair["title"]))
        return {"id": case_id, "repair_record_id": repair_id, "category": repair["category"], "problem_summary": repair["summary"], "solution_summary": repair["title"], "before_media_public_reference": None, "after_media_public_reference": None}

    def create_verification(self, data: dict) -> dict:
        verification_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO repair_verifications (id, session_id, before_media_id, after_media_id, status, observations, remaining_issue, risk_level, next_action, requires_professional, request_another_photo) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", (verification_id, data["session_id"], data.get("before_media_id"), data.get("after_media_id"), data["status"], json.dumps(data.get("observations", [])), data.get("remaining_issue"), str(data.get("risk", "low")), json.dumps(data.get("next_action")) if data.get("next_action") else None, data.get("requires_professional", False), data.get("request_another_photo", False)))
        return data | {"id": verification_id}

    def create_professional_dossier(self, data: dict) -> dict:
        dossier_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO professional_case_dossiers (id, session_id, equipment_id, dossier_json, status) VALUES (%s,%s,%s,%s,'ready')", (dossier_id, data["session_id"], data.get("equipment_id"), json.dumps(data)))
        return data | {"id": dossier_id, "status": "ready"}

    def list_similar_cases(self, category: str, subcategory: str | None = None, limit: int = 3) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT category, problem_summary, solution_summary FROM shared_cases WHERE category=%s ORDER BY created_at DESC LIMIT %s", (category, limit))
            return [{"category": row[0], "problem_summary": row[1], "solution_summary": row[2]} for row in cur.fetchall()]

    def ensure_community_profile(self, actor_key: str, handle: str | None = None) -> dict:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO community_profiles (actor_key, handle) VALUES (%s,%s) ON CONFLICT (actor_key) DO NOTHING", (actor_key, (handle or "Membre Nalvium")[:60]))
            cur.execute("SELECT actor_key, handle, created_at FROM community_profiles WHERE actor_key=%s", (actor_key,))
            row = cur.fetchone()
        return {"actor_key": row[0], "handle": row[1], "created_at": row[2].isoformat()}

    def _community_post(self, row, actor_key: str | None = None) -> dict:
        post_id = row[0]
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT public_media_id::text, media_kind FROM community_post_media WHERE post_id=%s ORDER BY created_at", (post_id,))
            media = [{"public_media_id": item[0], "media_kind": item[1]} for item in cur.fetchall()]
            cur.execute("SELECT c.id::text, c.parent_comment_id::text, c.content, c.actor_key, p.handle, c.created_at FROM community_comments c JOIN community_profiles p ON p.actor_key=c.actor_key WHERE c.post_id=%s AND c.deleted_at IS NULL AND c.moderation_status='approved' ORDER BY c.created_at", (post_id,))
            comments = [{"id": item[0], "parent_comment_id": item[1], "content": item[2], "author_handle": item[4], "mine": item[3] == actor_key, "created_at": item[5].isoformat()} for item in cur.fetchall()]
            cur.execute("SELECT count(*) FROM community_reactions WHERE post_id=%s", (post_id,))
            helpful_count = cur.fetchone()[0]
            cur.execute("SELECT 1 FROM community_reactions WHERE post_id=%s AND actor_key=%s", (post_id, actor_key)) if actor_key else None
            helpful = bool(cur.fetchone()) if actor_key else False
            cur.execute("SELECT 1 FROM community_saved_posts WHERE post_id=%s AND actor_key=%s", (post_id, actor_key)) if actor_key else None
            saved = bool(cur.fetchone()) if actor_key else False
        return {"id": row[0], "author_handle": row[1], "repair_record_id": row[2], "equipment_id": row[3], "title": row[4], "category": row[5], "subcategory": row[6], "equipment_type": row[7], "brand": row[8], "model": row[9], "problem_summary": row[10], "solution_summary": row[11], "materials_used": row[12], "status": row[13], "moderation_status": row[14], "created_at": row[15].isoformat(), "updated_at": row[16].isoformat(), "published_at": row[17].isoformat() if row[17] else None, "media": media, "comments": comments, "helpful_count": helpful_count, "helpful": helpful, "saved": saved}

    def create_community_post(self, actor_key: str, data: dict, moderation_status: str = "approved") -> dict:
        self.ensure_community_profile(actor_key)
        post_id = str(uuid4())
        values = (post_id, actor_key, data.get("repair_record_id"), data.get("equipment_id"), data["title"], data.get("category", "other"), data.get("subcategory"), data.get("equipment_type"), data.get("brand"), data.get("model"), data["problem_summary"], data["solution_summary"], data.get("materials_used"), moderation_status)
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO community_posts (id, actor_key, repair_record_id, equipment_id, title, category, subcategory, equipment_type, brand, model, problem_summary, solution_summary, materials_used, moderation_status) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", values)
            cur.execute("SELECT p.id::text, cp.handle, p.repair_record_id::text, p.equipment_id::text, p.title, p.category, p.subcategory, p.equipment_type, p.brand, p.model, p.problem_summary, p.solution_summary, p.materials_used, p.status, p.moderation_status, p.created_at, p.updated_at, p.published_at FROM community_posts p JOIN community_profiles cp ON cp.actor_key=p.actor_key WHERE p.id=%s", (post_id,))
            row = cur.fetchone()
        return self._community_post(row, actor_key)

    def get_community_post(self, post_id: str, actor_key: str | None = None) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT p.id::text, cp.handle, p.repair_record_id::text, p.equipment_id::text, p.title, p.category, p.subcategory, p.equipment_type, p.brand, p.model, p.problem_summary, p.solution_summary, p.materials_used, p.status, p.moderation_status, p.created_at, p.updated_at, p.published_at, p.actor_key FROM community_posts p JOIN community_profiles cp ON cp.actor_key=p.actor_key WHERE p.id=%s AND (p.status='published' OR p.actor_key=%s)", (post_id, actor_key))
            row = cur.fetchone()
        if not row or row[13] == "deleted": return None
        return self._community_post(row, actor_key)

    def list_community_posts(self, actor_key: str, query: str = "", category: str | None = None, offset: int = 0, limit: int = 20, saved: bool = False) -> list[dict]:
        clauses = ["p.status='published'", "p.moderation_status='approved'"]
        params: list = []
        if category and category != "all": clauses.append("p.category=%s"); params.append(category)
        if query: clauses.append("to_tsvector('simple', p.title || ' ' || p.problem_summary || ' ' || p.solution_summary) @@ plainto_tsquery('simple', %s)"); params.append(query)
        if saved: clauses.append("EXISTS (SELECT 1 FROM community_saved_posts s WHERE s.post_id=p.id AND s.actor_key=%s)"); params.append(actor_key)
        params.extend([limit, offset])
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"SELECT p.id::text, cp.handle, p.repair_record_id::text, p.equipment_id::text, p.title, p.category, p.subcategory, p.equipment_type, p.brand, p.model, p.problem_summary, p.solution_summary, p.materials_used, p.status, p.moderation_status, p.created_at, p.updated_at, p.published_at FROM community_posts p JOIN community_profiles cp ON cp.actor_key=p.actor_key WHERE {' AND '.join(clauses)} ORDER BY p.published_at DESC LIMIT %s OFFSET %s", params)
            rows = cur.fetchall()
        return [self._community_post(row, actor_key) for row in rows]

    def update_community_post(self, post_id: str, actor_key: str, data: dict) -> dict | None:
        allowed = {key: data[key] for key in ("title", "category", "subcategory", "equipment_type", "brand", "model", "problem_summary", "solution_summary", "materials_used", "moderation_status") if key in data}
        if not allowed: return self.get_community_post(post_id, actor_key)
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute(f"UPDATE community_posts SET {', '.join(f'{key}=%s' for key in allowed)}, updated_at=now() WHERE id=%s AND actor_key=%s", (*allowed.values(), post_id, actor_key))
            if cur.rowcount != 1: return None
        return self.get_community_post(post_id, actor_key)

    def publish_community_post(self, post_id: str, actor_key: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE community_posts SET status='published', published_at=now(), updated_at=now() WHERE id=%s AND actor_key=%s AND moderation_status='approved'", (post_id, actor_key))
            if cur.rowcount != 1: return None
        return self.get_community_post(post_id, actor_key)

    def delete_community_post(self, post_id: str, actor_key: str) -> list[str] | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT public_media_id::text FROM community_post_media pm JOIN community_posts p ON p.id=pm.post_id WHERE p.id=%s AND p.actor_key=%s", (post_id, actor_key))
            media = [row[0] for row in cur.fetchall()]
            cur.execute("UPDATE community_posts SET status='deleted', updated_at=now() WHERE id=%s AND actor_key=%s", (post_id, actor_key))
            if cur.rowcount != 1: return None
        return media

    def add_community_media(self, post_id: str, actor_key: str, source_media_id: str | None, public_media_id: str, storage_key: str, media_kind: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO community_post_media (post_id, source_media_id, public_media_id, media_kind, storage_key) SELECT %s,%s,%s,%s,%s WHERE EXISTS (SELECT 1 FROM community_posts WHERE id=%s AND actor_key=%s) RETURNING id::text", (post_id, source_media_id, public_media_id, media_kind, storage_key, post_id, actor_key))
            row = cur.fetchone()
        return None if not row else {"id": row[0], "post_id": post_id, "source_media_id": source_media_id, "public_media_id": public_media_id, "storage_key": storage_key, "media_kind": media_kind}

    def get_community_media(self, public_media_id: str) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT pm.public_media_id::text, pm.storage_key FROM community_post_media pm JOIN community_posts p ON p.id=pm.post_id WHERE pm.public_media_id=%s AND p.status='published' AND p.moderation_status='approved'", (public_media_id,))
            row = cur.fetchone()
        return None if not row else {"public_media_id": row[0], "storage_key": row[1]}

    def add_community_comment(self, post_id: str, actor_key: str, content: str, parent_comment_id: str | None, moderation_status: str = "approved") -> dict | None:
        self.ensure_community_profile(actor_key)
        comment_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO community_comments (id, post_id, actor_key, parent_comment_id, content, moderation_status) SELECT %s,%s,%s,%s,%s,%s WHERE EXISTS (SELECT 1 FROM community_posts WHERE id=%s AND status='published' AND moderation_status='approved') RETURNING created_at", (comment_id, post_id, actor_key, parent_comment_id, content, moderation_status, post_id))
            row = cur.fetchone()
        return None if not row else {"id": comment_id, "post_id": post_id, "parent_comment_id": parent_comment_id, "content": content, "author_handle": self.ensure_community_profile(actor_key)["handle"], "mine": True, "created_at": row[0].isoformat()}

    def delete_community_comment(self, comment_id: str, actor_key: str) -> bool:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE community_comments SET deleted_at=now(), content='Commentaire supprimé' WHERE id=%s AND actor_key=%s", (comment_id, actor_key))
            return cur.rowcount == 1

    def toggle_community_helpful(self, post_id: str, actor_key: str, enabled: bool) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            if enabled: cur.execute("INSERT INTO community_reactions (post_id, actor_key) VALUES (%s,%s) ON CONFLICT DO NOTHING", (post_id, actor_key))
            else: cur.execute("DELETE FROM community_reactions WHERE post_id=%s AND actor_key=%s", (post_id, actor_key))
        return self.get_community_post(post_id, actor_key)

    def toggle_community_saved(self, post_id: str, actor_key: str, enabled: bool) -> dict | None:
        with self._connect() as conn, conn.cursor() as cur:
            if enabled: cur.execute("INSERT INTO community_saved_posts (post_id, actor_key) VALUES (%s,%s) ON CONFLICT DO NOTHING", (post_id, actor_key))
            else: cur.execute("DELETE FROM community_saved_posts WHERE post_id=%s AND actor_key=%s", (post_id, actor_key))
        return self.get_community_post(post_id, actor_key)

    def create_community_report(self, actor_key: str, data: dict) -> dict:
        self.ensure_community_profile(actor_key)
        report_id = str(uuid4())
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO community_reports (id, target_type, target_id, actor_key, reason, note) VALUES (%s,%s,%s,%s,%s,%s)", (report_id, data["target_type"], data["target_id"], actor_key, data["reason"], data.get("note")))
        return data | {"id": report_id, "status": "pending"}

    def list_community_admin(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text FROM community_posts WHERE status <> 'deleted' ORDER BY created_at DESC")
            ids = [row[0] for row in cur.fetchall()]
        return [self.get_community_post(item, None) for item in ids]

    def list_community_reports(self) -> list[dict]:
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT id::text, target_type, target_id::text, reason, note, status, created_at FROM community_reports ORDER BY created_at DESC")
            return [{"id": row[0], "target_type": row[1], "target_id": row[2], "reason": row[3], "note": row[4], "status": row[5], "created_at": row[6].isoformat()} for row in cur.fetchall()]

    def moderate_community_post(self, post_id: str, moderation_status: str) -> dict | None:
        if moderation_status not in {"approved", "restricted", "removed"}:
            return None
        with self._connect() as conn, conn.cursor() as cur:
            cur.execute("UPDATE community_posts SET moderation_status=%s, status=CASE WHEN %s='removed' THEN 'hidden' ELSE status END, updated_at=now() WHERE id=%s", (moderation_status, moderation_status, post_id))
            if cur.rowcount != 1: return None
        return self.get_community_post(post_id, None)

def build_store():
    url = os.getenv("NALVIUM_DATABASE_URL")
    if url:
        try:
            return PostgresStore(url)
        except Exception:
            pass
    return MemoryStore()
