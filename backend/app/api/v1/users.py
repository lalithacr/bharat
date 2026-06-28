"""User profile endpoints"""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.security import verify_token
from app.models.user import User
from app.models.report import RewardPoint
from app.schemas.user import UserOut, UserUpdate
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

router = APIRouter(prefix="/users", tags=["Users"])
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    if not credentials:
        return None
    payload = verify_token(credentials.credentials)
    if not payload:
        return None
    result = await db.execute(select(User).where(User.id == uuid.UUID(payload["sub"])))
    return result.scalar_one_or_none()


@router.get("/me", response_model=UserOut)
async def get_me(user: Optional[User] = Depends(get_current_user)):
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return UserOut.model_validate(user)


@router.put("/me", response_model=UserOut)
async def update_me(
    update: UserUpdate,
    user: Optional[User] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if update.name:
        user.name = update.name
    if update.preferred_lang:
        user.preferred_lang = update.preferred_lang
    if update.fcm_token:
        user.fcm_token = update.fcm_token
    await db.flush()
    return UserOut.model_validate(user)
