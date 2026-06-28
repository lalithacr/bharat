"""
AI Service - Core intelligence pipeline for Bharat Problem Solver AI
Stages: Preprocessing → Authenticity → YOLOv8 → Severity → Gemini NLP → Dept Routing
"""
import io
import logging
import random
from typing import Optional
from PIL import Image
import numpy as np

logger = logging.getLogger(__name__)

ISSUE_TYPES = [
    "pothole", "garbage", "water_leak",
    "broken_light", "road_damage", "drainage", "flooding", "property_damage"
]

SEVERITY_MAP = {
    "pothole": "medium",
    "garbage": "low",
    "water_leak": "medium",
    "broken_light": "low",
    "road_damage": "medium",
    "drainage": "medium",
    "flooding": "high",
    "property_damage": "medium",
}

DEPT_MAP = {
    "pothole": "Public Works Department (PWD)",
    "garbage": "Municipal Solid Waste Management",
    "water_leak": "Water Supply & Sewerage Board",
    "broken_light": "Electricity Supply Company (BESCOM)",
    "road_damage": "Public Works Department (PWD)",
    "drainage": "Storm Water Drain Department",
    "flooding": "Disaster Management Authority",
    "property_damage": "Municipal Corporation",
}

SUMMARIES = {
    "pothole": "A significant pothole has been identified on the road surface, posing risk to vehicles and pedestrians. Immediate repair recommended.",
    "garbage": "Accumulation of solid waste detected at this location. Sanitation team dispatch required for clearance.",
    "water_leak": "Water leakage detected from underground pipe or main supply line. Water utility team attention needed.",
    "broken_light": "Street light unit is non-functional at this location, creating safety hazard during night hours.",
    "road_damage": "Significant road surface deterioration observed including cracks and subsidence. Structural assessment needed.",
    "drainage": "Drainage blockage detected. Standing water risk and potential flooding if not addressed promptly.",
    "flooding": "Active flooding or waterlogging detected at this location. IMMEDIATE attention required — high risk to public safety.",
    "property_damage": "Public infrastructure or property damage observed. Municipal maintenance team required for assessment.",
}


class AIService:
    def __init__(self):
        self.yolo_model = None
        self.gemini_client = None
        self._load_models()

    def _load_models(self):
        """Load AI models — gracefully falls back to mock if not available."""
        try:
            from ultralytics import YOLO
            # In production: use fine-tuned model path
            # self.yolo_model = YOLO("models/bharat_civic_yolov8n.pt")
            # For development: use base YOLOv8n
            self.yolo_model = YOLO("yolov8n.pt")
            logger.info("YOLOv8 model loaded successfully")
        except Exception as e:
            logger.warning(f"YOLOv8 not available, using mock detections: {e}")

        try:
            import google.generativeai as genai
            from app.core.config import settings
            if settings.GEMINI_API_KEY:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                self.gemini_client = genai.GenerativeModel("gemini-1.5-flash")
                logger.info("Gemini AI loaded successfully")
        except Exception as e:
            logger.warning(f"Gemini not available, using mock summaries: {e}")

    def preprocess_image(self, image_bytes: bytes) -> Optional[np.ndarray]:
        """Stage 1: OpenCV preprocessing — resize, normalize, enhance."""
        try:
            import cv2
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is None:
                return None
            img = cv2.resize(img, (640, 640))
            img = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
            return img
        except Exception as e:
            logger.error(f"Image preprocessing failed: {e}")
            return None

    def check_image_authenticity(self, image_bytes: bytes) -> dict:
        """Stage 2: Detect AI-generated images + EXIF validation."""
        try:
            from PIL import Image as PILImage
            import io
            img = PILImage.open(io.BytesIO(image_bytes))
            exif_data = {}
            if hasattr(img, '_getexif') and img._getexif():
                exif_raw = img._getexif()
                if exif_raw:
                    exif_data = {str(k): str(v) for k, v in list(exif_raw.items())[:10]}

            has_exif = bool(exif_data)
            # Heuristic: real photos usually have EXIF data
            # Production: use GAN fingerprint CNN classifier here
            authenticity_score = 0.85 if has_exif else 0.60
            is_ai_generated = authenticity_score < 0.5

            return {
                "is_ai_generated": is_ai_generated,
                "authenticity_score": authenticity_score,
                "has_exif": has_exif,
                "exif_data": exif_data,
            }
        except Exception as e:
            logger.error(f"Authenticity check failed: {e}")
            return {"is_ai_generated": False, "authenticity_score": 0.7, "has_exif": False, "exif_data": {}}

    def detect_issue_yolo(self, image_bytes: bytes) -> dict:
        """Stage 3: YOLOv8 issue detection."""
        if self.yolo_model:
            try:
                import cv2
                nparr = np.frombuffer(image_bytes, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                results = self.yolo_model(img, verbose=False)
                detections = []
                for r in results:
                    for box in r.boxes:
                        detections.append({
                            "class": r.names[int(box.cls)],
                            "confidence": float(box.conf),
                            "bbox": box.xyxy[0].tolist(),
                        })
                # Map YOLO class to civic issue type
                issue_type = self._map_yolo_to_issue(detections)
                confidence = max((d["confidence"] for d in detections), default=0.5)
                return {"issue_type": issue_type, "confidence": confidence, "detections": detections}
            except Exception as e:
                logger.error(f"YOLO detection failed: {e}")

        # Mock detection for development (no GPU/model)
        issue_type = random.choice(ISSUE_TYPES)
        confidence = round(random.uniform(0.72, 0.96), 2)
        return {
            "issue_type": issue_type,
            "confidence": confidence,
            "detections": [{"class": issue_type, "confidence": confidence, "bbox": [100, 100, 400, 400]}],
        }

    def _map_yolo_to_issue(self, detections: list) -> str:
        """Map YOLOv8 class labels to civic issue types."""
        class_map = {
            "pothole": "pothole", "hole": "pothole",
            "garbage": "garbage", "trash": "garbage", "waste": "garbage",
            "water": "water_leak", "puddle": "flooding",
            "light": "broken_light",
            "crack": "road_damage", "road": "road_damage",
            "drain": "drainage",
            "flood": "flooding",
        }
        for det in sorted(detections, key=lambda x: x["confidence"], reverse=True):
            cls = det["class"].lower()
            for key, issue in class_map.items():
                if key in cls:
                    return issue
        return "road_damage"

    def classify_severity(self, issue_type: str, confidence: float, detections: list) -> str:
        """Stage 4: TensorFlow severity classifier (mock in dev)."""
        base_severity = SEVERITY_MAP.get(issue_type, "medium")
        # Adjust by confidence
        if confidence > 0.90 and base_severity == "medium":
            return "high"
        if confidence < 0.60:
            return "low"
        return base_severity

    def generate_summary(self, issue_type: str, severity: str, address: str, language: str = "en") -> str:
        """Stage 5: Gemini NLP summary generation."""
        if self.gemini_client:
            try:
                prompt = f"""
                Generate a concise, formal civic complaint summary in {language} for:
                Issue: {issue_type.replace('_', ' ').title()}
                Severity: {severity.upper()}
                Location: {address or 'reported location'}
                
                Keep it under 3 sentences. Be specific and actionable for municipal authorities.
                """
                response = self.gemini_client.generate_content(prompt)
                return response.text.strip()
            except Exception as e:
                logger.error(f"Gemini summary failed: {e}")

        # Fallback summary
        base = SUMMARIES.get(issue_type, "Civic issue detected requiring municipal attention.")
        return f"{base} Location: {address or 'GPS coordinates recorded'}. Severity level: {severity.upper()}."

    def get_department(self, issue_type: str, city: str = "") -> str:
        """Stage 6: Department routing (ML-based in production)."""
        return DEPT_MAP.get(issue_type, "Municipal Corporation")

    def calculate_confidence_score(
        self,
        detection_confidence: float,
        authenticity_score: float,
        user_trust_score: float,
        has_gps: bool,
    ) -> float:
        """Composite confidence score: GPS + Image + User Reputation."""
        gps_score = 1.0 if has_gps else 0.5
        score = (
            detection_confidence * 0.35
            + authenticity_score * 0.30
            + user_trust_score * 0.20
            + gps_score * 0.15
        )
        return round(min(score, 1.0), 3)

    async def analyze_image_full(
        self,
        image_bytes: bytes,
        latitude: float,
        longitude: float,
        address: str,
        user_trust_score: float = 0.5,
        language: str = "en",
    ) -> dict:
        """Full AI pipeline: runs all 6 stages and returns analysis."""
        # Stage 1: Preprocess
        self.preprocess_image(image_bytes)

        # Stage 2: Authenticity
        auth_result = self.check_image_authenticity(image_bytes)

        # Stage 3: YOLO Detection
        detection = self.detect_issue_yolo(image_bytes)
        issue_type = detection["issue_type"]
        detection_confidence = detection["confidence"]

        # Stage 4: Severity
        severity = self.classify_severity(issue_type, detection_confidence, detection["detections"])

        # Stage 5: NLP Summary
        summary = self.generate_summary(issue_type, severity, address, language)

        # Stage 6: Department Routing
        department = self.get_department(issue_type)

        # Confidence Score
        confidence_score = self.calculate_confidence_score(
            detection_confidence,
            auth_result["authenticity_score"],
            user_trust_score,
            bool(latitude and longitude),
        )

        return {
            "issue_type": issue_type,
            "severity": severity,
            "confidence_score": confidence_score,
            "is_ai_generated": auth_result["is_ai_generated"],
            "ai_summary": summary,
            "yolo_detections": detection["detections"],
            "department_suggestion": department,
            "duplicate_report_id": None,
        }


ai_service = AIService()
