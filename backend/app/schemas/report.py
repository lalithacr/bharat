from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from app.models.report import IssueType, Severity, ReportStatus


class ReportCreate(BaseModel):
    issue_type: IssueType
    severity: Severity = Severity.medium
    latitude: float
    longitude: float
    address: Optional[str] = None
    description: Optional[str] = None
    language: str = "en"


class ReportStatusUpdate(BaseModel):
    status: ReportStatus
    note: Optional[str] = None


class AIAnalysisResult(BaseModel):
    issue_type: IssueType
    severity: Severity
    confidence_score: float
    is_ai_generated: bool
    ai_summary: str
    yolo_detections: Optional[dict] = None
    duplicate_report_id: Optional[str] = None
    department_suggestion: Optional[str] = None


class ReportImageResponse(BaseModel):
    id: str
    s3_url: str
    thumbnail_url: Optional[str]
    is_ai_generated: bool

    class Config:
        from_attributes = True


class StatusHistoryResponse(BaseModel):
    old_status: Optional[str]
    new_status: str
    note: Optional[str]
    changed_at: datetime

    class Config:
        from_attributes = True


class ReportResponse(BaseModel):
    id: str
    ticket_number: str
    issue_type: IssueType
    severity: Severity
    status: ReportStatus
    latitude: float
    longitude: float
    address: Optional[str]
    description: Optional[str]
    ai_summary: Optional[str]
    confidence_score: float
    language: str
    created_at: datetime
    images: List[ReportImageResponse] = []
    status_history: List[StatusHistoryResponse] = []

    class Config:
        from_attributes = True
