from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from app.models.user import UserRole


class UserCreate(BaseModel):
    firebase_uid: str
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    preferred_lang: str = "en"


class UserUpdate(BaseModel):
    name: Optional[str] = None
    preferred_lang: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    name: str
    phone: Optional[str]
    email: Optional[str]
    preferred_lang: str
    trust_score: float
    reward_points: int
    role: UserRole
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
