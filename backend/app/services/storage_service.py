"""Image storage service — AWS S3 with local fallback for development."""
import os
import uuid
import logging
import aiofiles
from pathlib import Path
from app.core.config import settings

logger = logging.getLogger(__name__)

LOCAL_UPLOAD_DIR = Path("uploads")
LOCAL_UPLOAD_DIR.mkdir(exist_ok=True)


class StorageService:
    def __init__(self):
        self.s3_client = None
        self._init_s3()

    def _init_s3(self):
        if settings.AWS_ACCESS_KEY_ID and settings.AWS_SECRET_ACCESS_KEY:
            try:
                import boto3
                self.s3_client = boto3.client(
                    "s3",
                    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                    region_name=settings.AWS_REGION,
                )
                logger.info("S3 client initialized")
            except Exception as e:
                logger.warning(f"S3 not available: {e}")

    async def upload_image(self, image_bytes: bytes, filename: str = None) -> str:
        """Upload image, returns URL."""
        if not filename:
            filename = f"{uuid.uuid4()}.jpg"

        if self.s3_client:
            return await self._upload_to_s3(image_bytes, filename)
        return await self._save_locally(image_bytes, filename)

    async def _upload_to_s3(self, image_bytes: bytes, filename: str) -> str:
        import io
        try:
            key = f"reports/{filename}"
            self.s3_client.put_object(
                Bucket=settings.AWS_BUCKET_NAME,
                Key=key,
                Body=image_bytes,
                ContentType="image/jpeg",
            )
            return f"https://{settings.AWS_BUCKET_NAME}.s3.{settings.AWS_REGION}.amazonaws.com/{key}"
        except Exception as e:
            logger.error(f"S3 upload failed: {e}")
            return await self._save_locally(image_bytes, filename)

    async def _save_locally(self, image_bytes: bytes, filename: str) -> str:
        path = LOCAL_UPLOAD_DIR / filename
        async with aiofiles.open(path, "wb") as f:
            await f.write(image_bytes)
        return f"/uploads/{filename}"


storage_service = StorageService()
