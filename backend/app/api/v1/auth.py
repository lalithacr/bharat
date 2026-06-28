"""Authentication endpoints — Firebase Google + OTP flow."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import create_access_token
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, TokenResponse
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/auth", tags=["Authentication"])


class FirebaseLoginRequest(BaseModel):
    id_token: str
    name: Optional[str] = None
    phone: Optional[str] = None
    preferred_lang: str = "en"


class OTPSendRequest(BaseModel):
    phone: str


class OTPVerifyRequest(BaseModel):
    phone: str
    otp: str  # In production: Firebase Phone Auth handles this


@router.post("/google", response_model=TokenResponse)
async def google_login(request: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)):
    """Login/register via Google OAuth (Firebase ID token)."""
    # In production: verify Firebase ID token
    # decoded = firebase_admin.auth.verify_id_token(request.id_token)
    # firebase_uid = decoded["uid"]
    # For development: use token as UID
    firebase_uid = f"google_{request.id_token[:20]}"

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    is_new = False
    if not user:
        user = User(
            firebase_uid=firebase_uid,
            name=request.name or "Citizen",
            preferred_lang=request.preferred_lang,
        )
        db.add(user)
        await db.flush()
        is_new = True

    access_token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=access_token, user=user)


@router.post("/otp/send")
async def send_otp(request: OTPSendRequest):
    """Send OTP to phone (Firebase Phone Auth in production)."""
    # Production: Firebase Phone Auth or SMS gateway
    return {"message": f"OTP sent to {request.phone}", "session_id": "dev_session_123"}


@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp(request: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    """Verify OTP and return JWT."""
    # Production: verify against Firebase session
    if request.otp != "123456" and len(request.otp) != 6:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    firebase_uid = f"phone_{request.phone}"
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        user = User(firebase_uid=firebase_uid, name="Citizen", phone=request.phone)
        db.add(user)
        await db.flush()

    access_token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=access_token, user=user)
