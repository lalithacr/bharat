"""Analytics endpoints — heatmaps, leaderboard, predictions."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List
from app.core.database import get_db
from app.models.report import Report
from app.models.user import User
from datetime import datetime, timedelta
import random

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/heatmap")
async def get_heatmap(
    city: Optional[str] = Query(None),
    issue_type: Optional[str] = Query(None),
    days: int = Query(30, le=365),
    db: AsyncSession = Depends(get_db),
):
    """Return heatmap points for Google Maps overlay."""
    since = datetime.utcnow() - timedelta(days=days)
    query = select(Report.latitude, Report.longitude, Report.severity).where(
        Report.created_at >= since
    )
    if issue_type:
        query = query.where(Report.issue_type == issue_type)

    result = await db.execute(query)
    rows = result.all()

    weight_map = {"high": 1.0, "medium": 0.6, "low": 0.3}
    heatmap_points = [
        {"lat": row[0], "lng": row[1], "weight": weight_map.get(str(row[2]), 0.5)}
        for row in rows
    ]
    return {"heatmap_points": heatmap_points, "total": len(heatmap_points)}


@router.get("/leaderboard")
async def get_leaderboard(
    city: Optional[str] = Query(None),
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Top citizen contributors by reward points."""
    query = (
        select(User.id, User.name, User.reward_points, User.trust_score)
        .where(User.reward_points > 0)
        .order_by(User.reward_points.desc())
        .limit(limit)
    )
    result = await db.execute(query)
    rows = result.all()

    leaderboard = []
    for rank, row in enumerate(rows, 1):
        points = row[2]
        badge = "🥇 Civic Hero" if points > 500 else "🥈 Area Guardian" if points > 200 else "🥉 Problem Solver" if points > 50 else "🌱 New Reporter"
        leaderboard.append({
            "rank": rank,
            "user_id": row[0],
            "name": row[1],
            "reward_points": row[2],
            "trust_score": round(row[3], 2),
            "badge": badge,
        })
    return {"leaderboard": leaderboard}


@router.get("/predictions")
async def get_predictions(
    city: Optional[str] = Query(None),
    issue_type: str = Query("road"),
    horizon_days: int = Query(30, le=90),
):
    """AI predictive risk zones (ML model output — mock in dev)."""
    # Production: spatial ML model using historical report density + weather + pipe age
    risk_zones = [
        {
            "zone_id": f"zone_{i}",
            "issue_type": issue_type,
            "risk_level": random.choice(["high", "medium", "low"]),
            "confidence": round(random.uniform(0.65, 0.92), 2),
            "predicted_reports": random.randint(3, 25),
            "polygon": [
                {"lat": 12.97 + random.uniform(-0.05, 0.05), "lng": 77.59 + random.uniform(-0.05, 0.05)}
                for _ in range(4)
            ],
        }
        for i in range(5)
    ]
    return {"predictions": risk_zones, "horizon_days": horizon_days, "generated_at": datetime.utcnow()}


@router.get("/summary")
async def get_summary(db: AsyncSession = Depends(get_db)):
    """Dashboard KPI summary."""
    total = await db.scalar(select(func.count(Report.id)))
    resolved = await db.scalar(select(func.count(Report.id)).where(Report.status == "resolved"))
    pending = await db.scalar(select(func.count(Report.id)).where(Report.status == "pending"))
    in_progress = await db.scalar(select(func.count(Report.id)).where(Report.status == "in_progress"))

    return {
        "total_reports": total or 0,
        "resolved": resolved or 0,
        "pending": pending or 0,
        "in_progress": in_progress or 0,
        "resolution_rate": round((resolved / total * 100) if total else 0, 1),
    }
