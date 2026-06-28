import uuid
from datetime import datetime, timezone
from enum import Enum as PyEnum
from sqlalchemy import (
    Column, String, Float, Integer, Boolean, Text, DateTime,
    ForeignKey, Enum, JSON
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


def utcnow():
    return datetime.now(timezone.utc)


# ─── Enums ───────────────────────────────────────────────────────────────────

class UserRole(str, PyEnum):
    citizen = "citizen"
    authority = "authority"
    admin = "admin"


class IssueType(str, PyEnum):
    pothole = "pothole"
    garbage = "garbage"
    water_leakage = "water_leakage"
    broken_street_light = "broken_street_light"
    damaged_road = "damaged_road"
    drainage_blockage = "drainage_blockage"
    flooding = "flooding"
    property_damage = "property_damage"
    other = "other"


class SeverityLevel(str, PyEnum):
    low = "low"
    medium = "medium"
    high = "high"


class ReportStatus(str, PyEnum):
    pending = "pending"
    ai_processing = "ai_processing"
    verified = "verified"
    assigned = "assigned"
    in_progress = "in_progress"
    resolved = "resolved"
    rejected = "rejected"
    duplicate = "duplicate"


class Language(str, PyEnum):
    english = "en"
    hindi = "hi"
    tamil = "ta"
    telugu = "te"
    malayalam = "ml"
    kannada = "kn"


class PointReason(str, PyEnum):
    report_submitted = "report_submitted"
    report_verified = "report_verified"
    community_validation = "community_validation"
    report_resolved = "report_resolved"
    fake_report_penalty = "fake_report_penalty"
    streak_bonus = "streak_bonus"


# ─── Models ──────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String(128), unique=True, nullable=False, index=True)
    name = Column(String(200), nullable=False)
    phone = Column(String(20), unique=True, nullable=True)
    email = Column(String(200), unique=True, nullable=True)
    avatar_url = Column(String(500), nullable=True)
    preferred_language = Column(Enum(Language), default=Language.english)
    role = Column(Enum(UserRole), default=UserRole.citizen, nullable=False)
    trust_score = Column(Float, default=0.7)
    reward_points = Column(Integer, default=0)
    total_reports = Column(Integer, default=0)
    verified_reports = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    fcm_token = Column(String(500), nullable=True)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    reports = relationship("Report", back_populates="reporter", foreign_keys="Report.user_id")
    reward_history = relationship("RewardPoint", back_populates="user")
    validations = relationship("CommunityValidation", back_populates="validator")
    department = relationship("Department", back_populates="staff")


class Department(Base):
    __tablename__ = "departments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    contact_email = Column(String(200))
    contact_phone = Column(String(20))
    issue_types = Column(JSON)  # List of IssueType strings this dept handles
    avg_resolution_days = Column(Float, default=7.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    reports = relationship("Report", back_populates="department")
    staff = relationship("User", back_populates="department")


class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_number = Column(String(20), unique=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"), nullable=True)

    issue_type = Column(Enum(IssueType), nullable=False)
    severity = Column(Enum(SeverityLevel), nullable=False, default=SeverityLevel.medium)
    status = Column(Enum(ReportStatus), default=ReportStatus.pending, index=True)

    # Location
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(Text)
    city = Column(String(100))
    ward = Column(String(100))
    pincode = Column(String(10))

    # Content
    title = Column(String(300))
    description = Column(Text)
    ai_summary = Column(Text)
    language = Column(Enum(Language), default=Language.english)

    # AI Analysis
    confidence_score = Column(Float, default=0.0)
    yolo_detections = Column(JSON)
    ai_issue_type_raw = Column(String(100))
    severity_probability = Column(JSON)

    # Fake report prevention
    is_fake = Column(Boolean, default=False)
    is_ai_generated_image = Column(Boolean, default=False)
    duplicate_of_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=True)
    gps_verified = Column(Boolean, default=False)
    community_validation_count = Column(Integer, default=0)

    # Resolution
    assigned_to_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    resolution_note = Column(Text)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    estimated_resolution_days = Column(Integer)

    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    reporter = relationship("User", back_populates="reports", foreign_keys=[user_id])
    department = relationship("Department", back_populates="reports")
    images = relationship("ReportImage", back_populates="report", cascade="all, delete-orphan")
    status_history = relationship("IssueStatusHistory", back_populates="report", cascade="all, delete-orphan")
    validations = relationship("CommunityValidation", back_populates="report")


class ReportImage(Base):
    __tablename__ = "report_images"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    s3_url = Column(String(1000), nullable=False)
    thumbnail_url = Column(String(1000))
    is_ai_generated = Column(Boolean, default=False)
    ai_generated_confidence = Column(Float, default=0.0)
    exif_data = Column(JSON)
    exif_latitude = Column(Float)
    exif_longitude = Column(Float)
    exif_timestamp = Column(DateTime(timezone=True))
    yolo_labels = Column(JSON)
    is_resolution_photo = Column(Boolean, default=False)
    uploaded_at = Column(DateTime(timezone=True), default=utcnow)

    report = relationship("Report", back_populates="images")


class IssueStatusHistory(Base):
    __tablename__ = "issue_status_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    old_status = Column(Enum(ReportStatus))
    new_status = Column(Enum(ReportStatus), nullable=False)
    changed_by_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    note = Column(Text)
    changed_at = Column(DateTime(timezone=True), default=utcnow)

    report = relationship("Report", back_populates="status_history")
    changed_by = relationship("User")


class RewardPoint(Base):
    __tablename__ = "reward_points"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=True)
    points = Column(Integer, nullable=False)
    reason = Column(Enum(PointReason), nullable=False)
    description = Column(String(300))
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="reward_history")


class CommunityValidation(Base):
    __tablename__ = "community_validations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False)
    validator_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    is_valid = Column(Boolean, nullable=False)
    note = Column(Text)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    report = relationship("Report", back_populates="validations")
    validator = relationship("User", back_populates="validations")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=True)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    fcm_sent = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)
