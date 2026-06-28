"""Report endpoints — submit, analyze, track, update."""
import uuid
import random
import string
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.security import verify_token
from app.models.report import Report, ReportImage, IssueStatusHistory, ReportStatus, IssueType, Severity
from app.models.user import User
from app.schemas.report import ReportCreate, ReportResponse, ReportStatusUpdate, AIAnalysisResult
from app.services.ai_service import ai_service
from app.services.storage_service import storage_service
from app.services.notification_service import notification_service
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/reports", tags=["Reports"])
security = HTTPBearer()


def generate_ticket() -> str:
    return "BPS-" + "".join(random.choices(string.digits, k=8))


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = verify_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    result = await db.execute(select(User).where(User.id == payload["sub"]))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


# ── Helper: load a report with images eagerly ─────────────────────────────────
async def _get_report_with_images(db: AsyncSession, report_id: str) -> Optional[Report]:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.images), selectinload(Report.status_history))  # ✅ eager load — no lazy greenlet error
        .where(Report.id == report_id)
    )
    return result.scalar_one_or_none()


@router.post("/analyze-image", response_model=AIAnalysisResult)
async def analyze_image(
    image: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    address: str = Form(""),
    language: str = Form("en"),
    current_user: User = Depends(get_current_user),
):
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    image_bytes = await image.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")

    result = await ai_service.analyze_image_full(
        image_bytes, latitude, longitude, address,
        user_trust_score=current_user.trust_score,
        language=language,
    )
    return AIAnalysisResult(**result)


@router.post("", response_model=ReportResponse, status_code=201)
async def create_report(
    issue_type: str = Form(...),
    severity: str = Form("medium"),
    latitude: float = Form(...),
    longitude: float = Form(...),
    address: str = Form(""),
    description: str = Form(""),
    language: str = Form("en"),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    report = Report(
        id=str(uuid.uuid4()),
        ticket_number=generate_ticket(),
        user_id=current_user.id,
        issue_type=issue_type,
        severity=severity,
        latitude=latitude,
        longitude=longitude,
        address=address,
        description=description,
        language=language,
        confidence_score=0.75,
    )

    if image:
        image_bytes = await image.read()
        analysis = await ai_service.analyze_image_full(
            image_bytes, latitude, longitude, address,
            user_trust_score=current_user.trust_score,
            language=language,
        )
        report.issue_type = analysis["issue_type"]
        report.severity = analysis["severity"]
        report.confidence_score = analysis["confidence_score"]
        report.ai_summary = analysis["ai_summary"]
        report.yolo_detections = analysis["yolo_detections"]

        image_url = await storage_service.upload_image(image_bytes, f"{report.id}.jpg")
        report_image = ReportImage(
            id=str(uuid.uuid4()),
            report_id=report.id,
            s3_url=image_url,
            is_ai_generated=analysis["is_ai_generated"],
            yolo_labels=analysis["yolo_detections"],
        )
        db.add(report_image)

    db.add(report)
    current_user.reward_points += 10
    await db.flush()

    history = IssueStatusHistory(
        id=str(uuid.uuid4()),
        report_id=report.id,
        old_status=None,
        new_status="pending",
        changed_by=current_user.id,
        note="Report submitted by citizen",
    )
    db.add(history)

    await db.commit()  # ✅ commit before returning

    # ✅ reload with images eagerly so serialization never triggers lazy load
    refreshed = await _get_report_with_images(db, report.id)
    return refreshed


@router.get("/my", response_model=List[ReportResponse])
async def get_my_reports(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    status: Optional[str] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
):
    query = (
        select(Report)
        .options(selectinload(Report.images), selectinload(Report.status_history))  # ✅ eager load
        .where(Report.user_id == current_user.id)
    )
    if status:
        query = query.where(Report.status == status)
    query = query.order_by(Report.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/nearby", response_model=List[ReportResponse])
async def get_nearby_reports(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_km: float = Query(2.0, le=50),
    issue_type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    delta = radius_km / 111.0
    query = (
        select(Report)
        .options(selectinload(Report.images), selectinload(Report.status_history))  # ✅ eager load
        .where(
            and_(
                Report.latitude.between(lat - delta, lat + delta),
                Report.longitude.between(lng - delta, lng + delta),
            )
        )
    )
    if issue_type:
        query = query.where(Report.issue_type == issue_type)
    if status:
        query = query.where(Report.status == status)
    query = query.order_by(Report.created_at.desc()).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(report_id: str, db: AsyncSession = Depends(get_db)):
    report = await _get_report_with_images(db, report_id)  # ✅ eager load
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report


@router.put("/{report_id}/status", response_model=ReportResponse)
async def update_status(
    report_id: str,
    update: ReportStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.user import UserRole
    if current_user.role == UserRole.citizen:
        raise HTTPException(status_code=403, detail="Authority access required")

    report = await _get_report_with_images(db, report_id)  # ✅ eager load
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    old_status = report.status
    report.status = update.status

    history = IssueStatusHistory(
        id=str(uuid.uuid4()),
        report_id=report.id,
        old_status=str(old_status),
        new_status=str(update.status),
        changed_by=current_user.id,
        note=update.note,
    )
    db.add(history)

    if update.status == ReportStatus.resolved:
        reporter_result = await db.execute(select(User).where(User.id == report.user_id))
        reporter = reporter_result.scalar_one_or_none()
        if reporter:
            severity_points = {"low": 10, "medium": 20, "high": 35}
            reporter.reward_points += severity_points.get(str(report.severity), 10)
            reporter.trust_score = min(reporter.trust_score + 0.02, 1.0)

    await db.commit()  # ✅ commit before returning
    await notification_service.notify_status_update("", report.ticket_number, str(update.status))

    refreshed = await _get_report_with_images(db, report_id)  # ✅ reload after commit
    return refreshed