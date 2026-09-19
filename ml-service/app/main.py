from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import severity, rank

app = FastAPI(
    title="SERN ML Service",
    version="1.0.0",
    description="Severity prediction + responder ranking for SERN",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(severity.router, prefix="/ml", tags=["Severity"])
app.include_router(rank.router, prefix="/ml", tags=["Ranking"])


@app.get("/health")
def health():
    return {"status": "ok", "service": "sern-ml"}