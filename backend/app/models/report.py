import uuid
from datetime import datetime
from sqlalchemy import String, Float, Text, ForeignKey, Enum, DateTime, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
import enum


class IssueType(str, enum.Enum):
    pothole = "pothole"
    garbage = "garbage"
    water_leak = "water_leak"
    broken_light = "broken_light"
    road_damage = "road_damage"
    drainage = "drainage"
    flooding = "flooding"
    property_damage = "property_damage"


class Severity(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"


class ReportStatus(str, enum.Enum):
    pending = "pending"
    verified = "verified"
    in_progress = "in_progress"
    resolved = "resolved"
    rejected = "rejected"


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ticket_number: Mapped[str] = mapped_column(String(20), unique=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False, index=True)
    issue_type: Mapped[IssueType] = mapped_column(Enum(IssueType), nullable=False)
    severity: Mapped[Severity] = mapped_column(Enum(Severity), default=Severity.medium)
    status: Mapped[ReportStatus] = mapped_column(Enum(ReportStatus), default=ReportStatus.pending)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    address: Mapped[str | None] = mapped_column(Text)
    description: Mapped[str | None] = mapped_column(Text)
    ai_summary: Mapped[str | None] = mapped_column(Text)
    confidence_score: Mapped[float] = mapped_column(Float, default=0.0)
    department_id: Mapped[str | None] = mapped_column(String, ForeignKey("departments.id"), nullable=True)
    language: Mapped[str] = mapped_column(String(10), default="en")
    yolo_detections: Mapped[dict | None] = mapped_column(JSON)
    is_duplicate: Mapped[bool] = mapped_column(Boolean, default=False)
    duplicate_of: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="reports")
    department = relationship("Department", back_populates="reports")
    images = relationship("ReportImage", back_populates="report")
    status_history = relationship("IssueStatusHistory", back_populates="report")


class ReportImage(Base):
    __tablename__ = "report_images"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    report_id: Mapped[str] = mapped_column(String, ForeignKey("reports.id"), nullable=False)
    s3_url: Mapped[str] = mapped_column(Text, nullable=False)
    thumbnail_url: Mapped[str | None] = mapped_column(Text)
    is_ai_generated: Mapped[bool] = mapped_column(Boolean, default=False)
    exif_data: Mapped[dict | None] = mapped_column(JSON)
    yolo_labels: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    report = relationship("Report", back_populates="images")


class IssueStatusHistory(Base):
    __tablename__ = "issue_status_history"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    report_id: Mapped[str] = mapped_column(String, ForeignKey("reports.id"), nullable=False)
    old_status: Mapped[str | None] = mapped_column(String(50))
    new_status: Mapped[str] = mapped_column(String(50), nullable=False)
    changed_by: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)
    changed_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    report = relationship("Report", back_populates="status_history")
