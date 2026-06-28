import uuid
from datetime import datetime
from sqlalchemy import String, Integer, ForeignKey, Enum, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
import enum


class RewardReason(str, enum.Enum):
    report_submitted = "report_submitted"
    report_verified = "report_verified"
    report_resolved = "report_resolved"
    community_validation = "community_validation"
    fake_report_penalty = "fake_report_penalty"


class RewardPoint(Base):
    __tablename__ = "reward_points"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False, index=True)
    points: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[RewardReason] = mapped_column(Enum(RewardReason))
    report_id: Mapped[str | None] = mapped_column(String, nullable=True)
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="reward_history")
