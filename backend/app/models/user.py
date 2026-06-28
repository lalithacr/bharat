import uuid
from datetime import datetime
from sqlalchemy import String, Float, Integer, Enum, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
import enum


class UserRole(str, enum.Enum):
    citizen = "citizen"
    authority = "authority"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    firebase_uid: Mapped[str] = mapped_column(String, unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(200), unique=True, nullable=True)
    preferred_lang: Mapped[str] = mapped_column(String(10), default="en")
    trust_score: Mapped[float] = mapped_column(Float, default=0.5)
    reward_points: Mapped[int] = mapped_column(Integer, default=0)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.citizen)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    reports = relationship("Report", back_populates="user")
    reward_history = relationship("RewardPoint", back_populates="user")
