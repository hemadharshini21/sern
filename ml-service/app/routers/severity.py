from fastapi import APIRouter
from app.schemas.predict import SeverityRequest, SeverityResponse
from app.services.severity import predict_severity

router = APIRouter()


@router.post("/severity", response_model=SeverityResponse)
def severity(req: SeverityRequest):
    it = req.incident_type or req.type or "stable_urgent"
    hr = req.hour if req.hour is not None else 12
    sev, conf = predict_severity(it, hr)
    return SeverityResponse(severity=sev, confidence=conf)