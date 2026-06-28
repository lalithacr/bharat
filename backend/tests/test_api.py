"""Basic API tests — run with: pytest tests/"""
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.mark.asyncio
async def test_root():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "Bharat Problem Solver AI 🇮🇳"


@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


@pytest.mark.asyncio
async def test_send_otp_invalid_phone():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/auth/otp/send", json={"phone": "12345"})
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_nearby_reports_no_auth():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/reports/nearby?lat=12.97&lng=77.59")
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_analytics_summary():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/analytics/summary")
    assert response.status_code == 200
    data = response.json()
    assert "total_reports" in data


@pytest.mark.asyncio
async def test_leaderboard():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/analytics/leaderboard")
    assert response.status_code == 200
    assert "leaderboard" in response.json()
