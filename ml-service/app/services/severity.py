"""
Severity Classifier Module for SERN ML Service
Binary urgency toggle (critical_emergency vs stable_urgent) with time-of-day elevation.
"""

BASELINE_MAPPING = {
    "critical_emergency": ("critical", 0.90),
    "stable_urgent": ("medium", 0.75),
}

SEVERITY_LEVELS = ["low", "medium", "high", "critical"]

def _elevate_severity(level: str) -> str:
    try:
        idx = SEVERITY_LEVELS.index(level.lower())
        if idx < len(SEVERITY_LEVELS) - 1:
            return SEVERITY_LEVELS[idx + 1]
        return level
    except ValueError:
        return level

def predict_severity(incident_type: str, hour: int = 12) -> tuple[str, float]:
    """
    Predict medical emergency severity and confidence score.
    Returns (severity_string, confidence_float).
    """
    it_clean = (incident_type or "").lower().strip()
    
    # 1. Baseline mapping from binary urgency toggle
    severity, confidence = BASELINE_MAPPING.get(it_clean, ("medium", 0.75))

    # 2. Time-of-day elevation (22:00 to 05:00)
    is_night = (hour >= 22) or (hour < 5)
    if is_night and severity != "critical":
        severity = _elevate_severity(severity)

    return severity, confidence