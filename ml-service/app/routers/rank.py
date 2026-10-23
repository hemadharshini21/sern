from fastapi import APIRouter
from typing import List
from app.schemas.predict import RankRequest, RankedResponder
from app.services.ranker import rank_responders

router = APIRouter()


@router.post("/rank-ambulances", response_model=List[RankedResponder])
def rank_ambulances(req: RankRequest):
    candidates_raw = req.candidates or req.responders or []
    responders = [c.model_dump() for c in candidates_raw]
    sev = req.severity or req.incident_type or "medium"
    return rank_responders(sev, req.incident_lat, req.incident_lng, responders)


@router.post("/rank-responders", response_model=List[RankedResponder])
def rank_resp(req: RankRequest):
    candidates_raw = req.candidates or req.responders or []
    responders = [c.model_dump() for c in candidates_raw]
    sev = req.severity or req.incident_type or "medium"
    return rank_responders(sev, req.incident_lat, req.incident_lng, responders)