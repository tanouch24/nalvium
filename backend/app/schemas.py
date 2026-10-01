from enum import Enum
from pydantic import BaseModel, Field

class RiskLevel(str, Enum):
    out_of_scope = "out_of_scope"
    insufficient_information = "insufficient_information"
    low = "low"
    moderate = "moderate"
    high = "high"
    emergency = "emergency"

class ActionType(str, Enum):
    request_photo = "request_photo"
    ask_question = "ask_question"
    instruction = "instruction"
    verify = "verify"
    safety_stop = "safety_stop"
    recommend_professional = "recommend_professional"
    resolved = "resolved"

class Hypothesis(BaseModel):
    label: str
    confidence: float = Field(ge=0, le=1)
    reason: str

class Risk(BaseModel):
    level: RiskLevel
    flags: list[str]
    stop_diy: bool

class RequiredItem(BaseModel):
    type: str = Field(pattern="^(TOOL|PART|CONSUMABLE|SAFETY_EQUIPMENT)$")
    name: str = Field(min_length=1, max_length=160)
    generic_name: str | None = Field(default=None, max_length=160)
    description: str | None = Field(default=None, max_length=300)
    required: bool = True
    quantity: str | None = Field(default=None, max_length=40)
    compatibility_required: bool = False
    identification_confidence: float | None = Field(default=None, ge=0, le=1)
    purchase_search_query: str | None = Field(default=None, max_length=180)

class NextAction(BaseModel):
    type: ActionType
    instruction: str = Field(min_length=1, max_length=500)
    required_items: list[RequiredItem] = Field(default_factory=list)
    warning: str | None = None
    expected_result: str | None = None
    verification_method: str | None = None

class RepairVerification(BaseModel):
    status: str = Field(pattern="^(improved|unchanged|worsened|resolved|cannot_determine)$")
    observations: list[str] = []
    remaining_issue: str | None = None
    risk: RiskLevel = RiskLevel.low
    next_action: NextAction | None = None
    requires_professional: bool = False
    request_another_photo: bool = False

class Diy(BaseModel):
    allowed: bool
    difficulty: str

class Analysis(BaseModel):
    category: str
    subcategory: str
    observations: list[str]
    hypotheses: list[Hypothesis]
    missing_information: list[str]
    risk: Risk
    urgency: str
    diy: Diy
    next_action: NextAction
    assistant_message: str

class AnalyzeRequest(BaseModel):
    session_id: str | None = None
    text: str = Field(default="", max_length=4000)
    media_name: str | None = None
    media_type: str | None = None
    media_id: str | None = None
    equipment_id: str | None = None

class SessionRequest(BaseModel):
    equipment_id: str | None = None
    assistant_thread_id: str | None = None
    actor_key: str | None = Field(default=None, max_length=128)

class EquipmentValue(BaseModel):
    value: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    source: str | None = None

class EquipmentIdentification(BaseModel):
    object_type: str
    category: str | None = None
    subcategory: str | None = None
    brand: EquipmentValue = EquipmentValue()
    model: EquipmentValue = EquipmentValue()
    serial_number: EquipmentValue = EquipmentValue()
    suggested_name: str | None = None
    visible_text: list[str] = []
    needs_nameplate_photo: bool = False
    uncertainties: list[str] = []

class EquipmentCreateRequest(BaseModel):
    category: str = Field(min_length=1, max_length=80)
    subcategory: str | None = Field(default=None, max_length=80)
    display_name: str = Field(min_length=1, max_length=160)
    brand: str | None = Field(default=None, max_length=120)
    model: str | None = Field(default=None, max_length=160)
    serial_number: str | None = Field(default=None, max_length=160)
    room: str | None = Field(default=None, max_length=100)
    notes: str | None = Field(default=None, max_length=2000)
    primary_media_id: str | None = None
    identification_confidence: float | None = Field(default=None, ge=0, le=1)
    identification_source: str | None = Field(default=None, max_length=40)

class EquipmentUpdateRequest(BaseModel):
    category: str | None = Field(default=None, min_length=1, max_length=80)
    subcategory: str | None = Field(default=None, max_length=80)
    display_name: str | None = Field(default=None, min_length=1, max_length=160)
    brand: str | None = Field(default=None, max_length=120)
    model: str | None = Field(default=None, max_length=160)
    serial_number: str | None = Field(default=None, max_length=160)
    room: str | None = Field(default=None, max_length=100)
    notes: str | None = Field(default=None, max_length=2000)
    purchase_date: str | None = Field(default=None, max_length=30)
    purchase_price: float | None = Field(default=None, ge=0)
    purchase_currency: str | None = Field(default=None, min_length=3, max_length=3)
    seller: str | None = Field(default=None, max_length=160)

class DocumentValue(BaseModel):
    value: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)

class DocumentExtraction(BaseModel):
    document_type: str = "other"
    document_title: str | None = None
    document_date: str | None = None
    merchant: str | None = None
    equipment_brand: DocumentValue = DocumentValue()
    equipment_model: DocumentValue = DocumentValue()
    purchase_date: str | None = None
    purchase_price: float | None = Field(default=None, ge=0)
    purchase_currency: str | None = None
    warranty_end_date: str | None = None
    serial_number: DocumentValue = DocumentValue()
    warranty_provider: str | None = None
    extracted_text: str | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    uncertainties: list[str] = []

class DocumentAnalyzeRequest(BaseModel):
    text: str = Field(default="", max_length=12000)

class DocumentApplyRequest(BaseModel):
    purchase_date: str | None = Field(default=None, max_length=30)
    purchase_price: float | None = Field(default=None, ge=0)
    purchase_currency: str | None = Field(default=None, min_length=3, max_length=3)
    seller: str | None = Field(default=None, max_length=160)
    brand: str | None = Field(default=None, max_length=120)
    model: str | None = Field(default=None, max_length=160)
    serial_number: str | None = Field(default=None, max_length=160)

class EquipmentDocumentUpdateRequest(BaseModel):
    display_name: str | None = Field(default=None, max_length=180)
    document_type: str | None = Field(default=None, max_length=40)
    document_date: str | None = Field(default=None, max_length=30)

class WarrantyRequest(BaseModel):
    source_document_id: str | None = None
    provider: str | None = Field(default=None, max_length=160)
    start_date: str | None = Field(default=None, max_length=30)
    end_date: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=2000)

class MaintenanceRequest(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=2000)
    maintenance_type: str = Field(default="other", max_length=60)
    performed_at: str | None = Field(default=None, max_length=30)
    next_due_at: str | None = Field(default=None, max_length=30)
    status: str = Field(default="completed", max_length=40)
    source: str = Field(default="user", max_length=40)

class EquipmentMediaRequest(BaseModel):
    media_id: str
    media_type: str = Field(default="other", pattern="^(primary|nameplate|other)$")

class AssistantThreadRequest(BaseModel):
    context_type: str | None = Field(default=None, max_length=40)
    context_id: str | None = Field(default=None, max_length=100)
    equipment_id: str | None = None

class AssistantMessageRequest(BaseModel):
    text: str = Field(default="", max_length=4000)
    media_id: str | None = None
    context_type: str | None = Field(default=None, max_length=40)
    context_id: str | None = Field(default=None, max_length=100)

class AssistantResponse(BaseModel):
    thread_id: str
    message_id: str
    role: str
    content: str
    action: str
    next_action: dict | None = None
    safety_stop: bool = False
    media_references: list[str] = []
    context: dict | None = None

class LeadRequest(BaseModel):
    session_id: str
    first_name: str = Field(min_length=1, max_length=80)
    phone: str = Field(min_length=8, max_length=30)
    city: str = Field(min_length=1, max_length=100)
    postal_code: str = Field(min_length=4, max_length=12)
    desired_time_window: str = Field(default="", max_length=120)
    trade: str = Field(min_length=2, max_length=80)
    summary: str = Field(min_length=1, max_length=2000)
    urgency: str = Field(default="normal", max_length=20)
    consent: bool
    media_ids: list[str] = []

class VerificationRequest(BaseModel):
    after_media_id: str
    text: str = Field(default="", max_length=4000)

class SimilarCasesRequest(BaseModel):
    limit: int = Field(default=3, ge=1, le=5)

class ProfessionalDossierRequest(BaseModel):
    session_id: str
    equipment_id: str | None = None
    selected_media_ids: list[str] = []
    summary: str = Field(default="", max_length=3000)
    first_name: str = Field(default="", max_length=80)
    phone: str = Field(default="", max_length=30)
    city: str = Field(default="", max_length=100)
    postal_code: str = Field(default="", max_length=12)
    desired_time_window: str = Field(default="", max_length=120)
    consent: bool = False

class RepairRequestCreate(BaseModel):
    service_offering_id: str
    session_id: str | None = None
    equipment_id: str | None = None
    first_name: str = Field(min_length=1, max_length=80)
    phone: str = Field(min_length=8, max_length=30)
    postal_code: str = Field(min_length=4, max_length=12)
    city: str | None = Field(default=None, max_length=100)
    description: str = Field(min_length=1, max_length=3000)
    desired_time_window: str = Field(default="", max_length=120)
    selected_media_ids: list[str] = Field(default_factory=list, max_length=12)
    consent: bool = False
    source: str = Field(default="unknown", max_length=30)
    idempotency_key: str | None = Field(default=None, max_length=120)

class RepairRequestStatusUpdate(BaseModel):
    status: str = Field(min_length=3, max_length=40)
    note: str | None = Field(default=None, max_length=500)

class RepairAssignmentRequest(BaseModel):
    professional_id: str

class AppointmentRequest(BaseModel):
    starts_at: str = Field(min_length=10, max_length=40)
    ends_at: str | None = Field(default=None, max_length=40)
    note: str | None = Field(default=None, max_length=500)

class CoverageInterestRequest(BaseModel):
    postal_code: str = Field(min_length=4, max_length=12)
    contact: str | None = Field(default=None, max_length=160)
    consent: bool = False

class DeviceTokenRequest(BaseModel):
    token: str = Field(min_length=20, max_length=4096)
    platform: str = Field(pattern="^(android|ios|web)$")

class SupportContributionRequest(BaseModel):
    amount_cents: int = Field(gt=0, le=100000)
    currency: str = Field(default="EUR", min_length=3, max_length=3)
    source: str = Field(pattern="^(RESOLUTION_SCREEN|SETTINGS)$")
    repair_session_id: str | None = None

class CommerceSearchRequest(BaseModel):
    mode: str = Field(pattern="^(nearby|online)$")
    item_type: str = Field(pattern="^(TOOL|PART|CONSUMABLE|SAFETY_EQUIPMENT)$")
    generic_name: str = Field(min_length=1, max_length=160)
    purchase_search_query: str | None = Field(default=None, max_length=180)
    postal_code: str | None = Field(default=None, max_length=12)
    city: str | None = Field(default=None, max_length=100)
    safety_stop: bool = False

class CommunityPostRequest(BaseModel):
    repair_record_id: str | None = None
    equipment_id: str | None = None
    title: str = Field(min_length=1, max_length=160)
    category: str = Field(default="other", max_length=80)
    subcategory: str | None = Field(default=None, max_length=80)
    equipment_type: str | None = Field(default=None, max_length=100)
    brand: str | None = Field(default=None, max_length=120)
    model: str | None = Field(default=None, max_length=160)
    problem_summary: str = Field(min_length=1, max_length=2000)
    solution_summary: str = Field(min_length=1, max_length=3000)
    materials_used: str | None = Field(default=None, max_length=1200)
    before_media_id: str | None = None
    after_media_id: str | None = None

class CommunityPublishRequest(BaseModel):
    before_media_id: str | None = None
    after_media_id: str | None = None
    additional_media_ids: list[str] = []

class CommunityCommentRequest(BaseModel):
    content: str = Field(min_length=1, max_length=1200)
    parent_comment_id: str | None = None

class CommunityReportRequest(BaseModel):
    target_type: str = Field(pattern="^(post|comment)$")
    target_id: str
    reason: str = Field(min_length=2, max_length=80)
    note: str | None = Field(default=None, max_length=800)

class SessionResponse(BaseModel):
    id: str
    status: str
    messages: list[dict] = []
    media: list[dict] = []

class ProfessionalInput(BaseModel):
    business_name: str = Field(min_length=2, max_length=160)
    legal_name: str = Field(default="", max_length=160)
    phone: str = Field(min_length=8, max_length=30)
    email: str = Field(min_length=3, max_length=160)
    trade: str = Field(min_length=2, max_length=80)
    city: str = Field(min_length=2, max_length=100)
    active: bool = True

class ProfessionalUpdate(BaseModel):
    business_name: str | None = Field(default=None, min_length=2, max_length=160)
    phone: str | None = Field(default=None, min_length=8, max_length=30)
    email: str | None = Field(default=None, min_length=3, max_length=160)
    active: bool | None = None

class RepairRecordRequest(BaseModel):
    session_id: str
    equipment_id: str | None = None
    category: str = Field(default="other", max_length=80)
    title: str = Field(min_length=1, max_length=160)
    summary: str = Field(default="", max_length=2000)
    before_media_id: str | None = None
    after_media_id: str | None = None
    status: str = Field(default="in_progress", max_length=40)
    steps_completed: list[str] = []
    professional_required: bool = False

class RepairRecordUpdate(BaseModel):
    equipment_id: str | None = None
    after_media_id: str | None = None
    status: str | None = Field(default=None, max_length=40)
    steps_completed: list[str] | None = None
    professional_required: bool | None = None

class ShareRepairRequest(BaseModel):
    consent: bool
    include_before: bool = False
    include_after: bool = False
