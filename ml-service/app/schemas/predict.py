from pydantic import BaseModel, Field
from typing import List, Optional


class SeverityRequest(BaseModel):
    incident_type: Optional[str] = None
    type: Optional[str] = None
    hour: Optional[int] = 12


class SeverityResponse(BaseModel):
    severity: str
    confidence: float


class ResponderCandidate(BaseModel):
    user_id: str
    lat: float
    lng: float
    skills: Optional[List[str]] = []
    equipment: Optional[List[str]] = None
    avg_response_time: float = 0.0
    acceptance_rate: float = 0.0
    avg_response_min: Optional[float] = None

    def model_post_init(self, __context):
        if self.avg_response_min is not None and self.avg_response_time == 0.0:
            self.avg_response_time = self.avg_response_min
        if self.equipment is not None and not self.skills:
            self.skills = self.equipment


class RankRequest(BaseModel):
    severity: Optional[str] = None
    incident_type: Optional[str] = None
    incident_lat: float
    incident_lng: float
    candidates: Optional[List[ResponderCandidate]] = None
    responders: Optional[List[ResponderCandidate]] = None


class RankedResponder(BaseModel):
    user_id: str
    match_score: float
    distance_km: float


class RankResponse(BaseModel):
    ranked: List[RankedResponder]