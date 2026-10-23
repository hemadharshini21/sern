from math import radians, sin, cos, atan2, sqrt

EARTH_R = 6371.0

WEIGHTS = {
    "distance": 0.50,
    "response_time": 0.20,
    "acceptance": 0.15,
    "skill": 0.15,
}


def haversine(lat1, lng1, lat2, lng2):
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
    return EARTH_R * 2 * atan2(sqrt(a), sqrt(1 - a))


def _skill_match(severity, equipment_tags):
    tags = set((t or "").upper() for t in (equipment_tags or []))
    if (severity or "").lower() in ("critical", "high"):
        return 1.0 if "ALS" in tags else 0.3
    else:  # medium, low
        return 1.0 if tags & {"ALS", "BLS"} else 0.3


def rank_responders(severity, incident_lat, incident_lng, responders):
    if not responders:
        return []

    scored = []
    for r in responders:
        d = haversine(incident_lat, incident_lng, r["lat"], r["lng"])
        # Normalize: closer = higher. Cap distance at 20km → 0.
        distance_score = max(0.0, 1.0 - min(d, 20.0) / 20.0)
        # Faster = higher. Cap at 60 min.
        rt = float(r.get("avg_response_time") or 0)
        response_score = max(0.0, 1.0 - min(rt, 60.0) / 60.0)
        acceptance_score = float(r.get("acceptance_rate") or 0)
        
        equipment = r.get("equipment") or r.get("skills") or []
        skill_score = _skill_match(severity, equipment)

        score = (
            WEIGHTS["distance"] * distance_score
            + WEIGHTS["response_time"] * response_score
            + WEIGHTS["acceptance"] * acceptance_score
            + WEIGHTS["skill"] * skill_score
        )
        scored.append(
            {
                "user_id": r["user_id"],
                "match_score": round(score, 4),
                "distance_km": round(d, 3),
            }
        )

    scored.sort(key=lambda x: x["match_score"], reverse=True)
    return scored