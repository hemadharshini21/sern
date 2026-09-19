from fastapi import APIRouter
from app.schemas.predict import RankRequest, RankResponse
from app.services.ranker import rank_responders

router = APIRouter()


@router.post("/rank-responders", response_model=RankResponse)
def rank(req: RankRequest):
    responders = [r.model_dump() for r in req.responders]
    ranked = rank_responders(req.incident_type, req.incident_lat, req.incident_lng, responders)
    return RankResponse(ranked=ranked)