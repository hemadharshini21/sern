from pydantic import BaseModel, Field
from typing import List, Optional


class SeverityRequest(BaseModel):
    type: str = Field(..., examples=["medical"])
    description: Optional[str] = None
    hour: int = Field(12, ge=0, le=23)
    lat: float
    lng: float


class SeverityResponse(BaseModel):
    severity: str
    confidence: float


class ResponderCandidate(BaseModel):
    user_id: str
    lat: float
    lng: float
    skills: List[str] = []
    avg_response_time: float = 0
    acceptance_rate: float = 0
    distance_km: Optional[float] = None


class RankRequest(BaseModel):
    incident_type: str
    incident_lat: float
    incident_lng: float
    responders: List[ResponderCandidate]


class RankedResponder(BaseModel):
    user_id: str
    match_score: float
    distance_km: float


class RankResponse(BaseModel):
    ranked: List[RankedResponder]