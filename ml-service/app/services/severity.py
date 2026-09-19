SEVERITY_MAP = {
    "cardiac": "critical",
    "fire": "critical",
    "accident": "high",
    "medical": "high",
    "bleeding": "high",
    "assault": "high",
    "police": "medium",
    "theft": "medium",
    "flood": "high",
    "stuck": "low",
    "other": "medium",
}

KEYWORDS = {
    "critical": ["unconscious", "breathing", "cardiac", "heart", "not breathing", "severe"],
    "high": ["bleeding", "broken", "burn", "accident", "fire", "stab", "severe pain"],
    "low": ["minor", "small", "slight", "scratch"],
}


def predict_severity(incident_type: str, description: str, hour: int) -> dict:
    incident_type = (incident_type or "other").lower()
    description = (description or "").lower()

    base = SEVERITY_MAP.get(incident_type, "medium")

    # Keyword override
    for level, words in KEYWORDS.items():
        if any(w in description for w in words):
            if level == "critical":
                return {"severity": "critical", "confidence": 0.9}
            if level == "high" and base in ("low", "medium"):
                base = "high"
            if level == "low" and base == "critical":
                base = "high"

    # Night-time bump (22:00 - 05:00)
    if hour >= 22 or hour <= 5:
        if base == "low":
            base = "medium"
        elif base == "medium":
            base = "high"

    confidence = 0.75 if base != "medium" else 0.6
    return {"severity": base, "confidence": confidence}