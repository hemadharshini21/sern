from fastapi import APIRouter
from app.schemas.predict import SeverityRequest, SeverityResponse
from app.services.severity import predict_severity

router = APIRouter()


@router.post("/severity", response_model=SeverityResponse)
def severity(req: SeverityRequest):
    result = predict_severity(req.type, req.description, req.hour)
    return SeverityResponse(**result)