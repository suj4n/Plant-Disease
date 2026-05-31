"""Supabase client and operations for PlantDoc backend."""

import os
from datetime import datetime
from typing import Optional

from supabase import create_client
from supabase.lib.client_options import ClientOptions

from app.core.config import get_settings

settings = get_settings()

# Initialize Supabase client
_supabase_url = os.getenv("SUPABASE_URL")
_supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if _supabase_url and _supabase_key:
    supabase_client = create_client(
        _supabase_url,
        _supabase_key,
        options=ClientOptions(auto_refresh_token=False),
    )
else:
    supabase_client = None


def is_supabase_enabled() -> bool:
    """Check if Supabase is properly configured."""
    return supabase_client is not None


async def save_scan(
    user_id: str,
    disease_name: str,
    confidence: float,
    is_healthy: bool,
    recommendations: str,
    image_url: Optional[str] = None,
) -> dict:
    """Save scan result to Supabase.
    
    Args:
        user_id: UUID of authenticated user
        disease_name: Name of detected disease
        confidence: Prediction confidence (0-1)
        is_healthy: Whether plant is healthy
        recommendations: Treatment/prevention recommendations
        image_url: URL of uploaded scan image
    
    Returns:
        Inserted scan record
    """
    if not is_supabase_enabled():
        raise RuntimeError("Supabase not configured")
    
    data = {
        "user_id": user_id,
        "disease_name": disease_name,
        "confidence": min(max(confidence, 0), 1),  # Clamp 0-1
        "is_healthy": is_healthy,
        "recommendations": recommendations,
        "image_url": image_url,
        "created_at": datetime.utcnow().isoformat(),
    }
    
    response = supabase_client.table("scans").insert(data).execute()
    return response.data[0] if response.data else data


async def get_user_scans(user_id: str, limit: int = 50) -> list:
    """Get scan history for a user.
    
    Args:
        user_id: UUID of user
        limit: Maximum number of scans to return
    
    Returns:
        List of scan records
    """
    if not is_supabase_enabled():
        return []
    
    response = (
        supabase_client.table("scans")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    return response.data or []


async def get_scan_by_id(scan_id: str) -> Optional[dict]:
    """Get a specific scan by ID.
    
    Args:
        scan_id: UUID of scan
    
    Returns:
        Scan record or None
    """
    if not is_supabase_enabled():
        return None
    
    response = (
        supabase_client.table("scans")
        .select("*")
        .eq("id", scan_id)
        .single()
        .execute()
    )
    return response.data


async def delete_scan(scan_id: str, user_id: str) -> bool:
    """Delete a scan (owner only).
    
    Args:
        scan_id: UUID of scan
        user_id: UUID of owner (for verification)
    
    Returns:
        Success status
    """
    if not is_supabase_enabled():
        return False
    
    response = (
        supabase_client.table("scans")
        .delete()
        .eq("id", scan_id)
        .eq("user_id", user_id)
        .execute()
    )
    return len(response.data) > 0 if response.data else True


async def get_disease_info(disease_name: str) -> Optional[dict]:
    """Get disease information from catalog.
    
    Args:
        disease_name: Name of disease
    
    Returns:
        Disease info record or None
    """
    if not is_supabase_enabled():
        return None
    
    response = (
        supabase_client.table("disease_info")
        .select("*")
        .eq("name", disease_name)
        .single()
        .execute()
    )
    return response.data


async def get_all_diseases() -> list:
    """Get all diseases from catalog.
    
    Returns:
        List of disease records
    """
    if not is_supabase_enabled():
        return []
    
    response = (
        supabase_client.table("disease_info")
        .select("*")
        .order("name")
        .execute()
    )
    return response.data or []


async def add_favorite(user_id: str, disease_id: int) -> bool:
    """Add disease to user favorites.
    
    Args:
        user_id: UUID of user
        disease_id: ID of disease
    
    Returns:
        Success status
    """
    if not is_supabase_enabled():
        return False
    
    try:
        supabase_client.table("favorites").insert({
            "user_id": user_id,
            "disease_id": disease_id,
        }).execute()
        return True
    except Exception:
        return False


async def remove_favorite(user_id: str, disease_id: int) -> bool:
    """Remove disease from user favorites.
    
    Args:
        user_id: UUID of user
        disease_id: ID of disease
    
    Returns:
        Success status
    """
    if not is_supabase_enabled():
        return False
    
    response = (
        supabase_client.table("favorites")
        .delete()
        .eq("user_id", user_id)
        .eq("disease_id", disease_id)
        .execute()
    )
    return True


async def get_user_favorites(user_id: str) -> list:
    """Get user's favorite diseases.
    
    Args:
        user_id: UUID of user
    
    Returns:
        List of favorite disease records
    """
    if not is_supabase_enabled():
        return []
    
    response = (
        supabase_client.table("favorites")
        .select("disease_info(*)")
        .eq("user_id", user_id)
        .execute()
    )
    return response.data or []


async def upload_scan_image(user_id: str, file_content: bytes, file_name: str) -> Optional[str]:
    """Upload scan image to Supabase Storage.
    
    Args:
        user_id: UUID of user
        file_content: Image file bytes
        file_name: Original file name
    
    Returns:
        Public URL of uploaded image or None
    """
    if not is_supabase_enabled():
        return None
    
    try:
        # Create path: user_id/filename
        path = f"{user_id}/{file_name}"
        
        # Upload to 'scan-images' bucket
        response = supabase_client.storage.from_("scan-images").upload(
            path,
            file_content,
        )
        
        # Get public URL
        public_url = supabase_client.storage.from_("scan-images").get_public_url(path)
        return public_url
    except Exception as e:
        print(f"Image upload failed: {e}")
        return None
