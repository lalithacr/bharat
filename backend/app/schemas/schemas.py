from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Any
from uuid import UUID
from datetime import datetime
from app.models.models import (
    UserRole, IssueType, SeverityLevel, ReportStatus, Language, PointReason
)


# ─── Auth ────────────────────────────────────────────────────────────────────

class GoogleAuthRequest(BaseModel):
    id_token: str

class OTPSendRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+91[6-9]\d{9}$", description="+91XXXXXXXXXX")

class OTPVerifyRequest(BaseModel):
    session_id: str
    otp: str = Field(..., min_length=6, max_length=6)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: "UserResponse"


# ─── User ────────────────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    id: UUID
    name: str
    email: Optional[str]
    phone: Optional[str]
    avatar_url: Optional[str]
    role: UserRole
    trust_score: float
    reward_points: int
    total_reports: int
    preferred_language: Language
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    preferred_language: Optional[Language] = None
    fcm_token: Optional[str] = None


# ─── Report ──────────────────────────────────────────────────────────────────

class ReportCreateRequest(BaseModel):
    issue_type: IssueType
    severity: Optional[SeverityLevel] = SeverityLevel.medium
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None
    city: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    language: Language = Language.english
    image_ids: Optional[List[UUID]] = []

class ReportStatusUpdate(BaseModel):
    status: ReportStatus
    note: Optional[str] = None
    assigned_to_id: Optional[UUID] = None
    estimated_resolution_days: Optional[int] = None

class ImageUploadResponse(BaseModel):
    image_id: UUID
    s3_url: str
    thumbnail_url: Optional[str]
    is_ai_generated: bool
    ai_generated_confidence: float
    exif_gps_match: bool
    yolo_detections: Optional[List[dict]]

class AIAnalysisResponse(BaseModel):
    issue_type: IssueType
    severity: SeverityLevel
    confidence_score: float
    ai_summary: str
    yolo_detections: List[dict]
    is_ai_generated: bool
    duplicate_report_id: Optional[UUID]
    suggested_department: Optional[str]
    estimated_resolution_days: int

class StatusHistoryItem(BaseModel):
    old_status: Optional[ReportStatus]
    new_status: ReportStatus
    note: Optional[str]
    changed_at: datetime

    class Config:
        from_attributes = True

class ReportResponse(BaseModel):
    id: UUID
    ticket_number: str
    issue_type: IssueType
    severity: SeverityLevel
    status: ReportStatus
    latitude: float
    longitude: float
    address: Optional[str]
    city: Optional[str]
    title: Optional[str]
    description: Optional[str]
    ai_summary: Optional[str]
    confidence_score: float
    is_fake: bool
    community_validation_count: int
    language: Language
    created_at: datetime
    updated_at: datetime
    images: List[Any] = []
    status_history: List[StatusHistoryItem] = []
    reporter: Optional[UserResponse]

    class Config:
        from_attributes = True


# ─── Validation ──────────────────────────────────────────────────────────────

class CommunityValidationRequest(BaseModel):
    is_valid: bool
    note: Optional[str] = None


# ─── Analytics ───────────────────────────────────────────────────────────────

class HeatmapPoint(BaseModel):
    lat: float
    lng: float
    weight: float
    issue_type: Optional[str]

class HeatmapResponse(BaseModel):
    points: List[HeatmapPoint]
    total_reports: int

class PredictionZone(BaseModel):
    lat: float
    lng: float
    risk_level: str
    confidence: float
    issue_type: str
    predicted_days: int

class LeaderboardUser(BaseModel):
    rank: int
    user_id: UUID
    name: str
    avatar_url: Optional[str]
    reward_points: int
    total_reports: int
    trust_score: float

class DashboardStats(BaseModel):
    total_reports: int
    pending: int
    in_progress: int
    resolved: int
    avg_resolution_days: float
    top_issue_type: str
    reports_this_week: int


# ─── Notifications ───────────────────────────────────────────────────────────

class NotificationResponse(BaseModel):
    id: UUID
    title: str
    body: str
    is_read: bool
    report_id: Optional[UUID]
    created_at: datetime

    class Config:
        from_attributes = True
