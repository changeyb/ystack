#!/usr/bin/env python3
"""Optional Codex Stop hook for metadata-only local audit."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sys

event = json.load(sys.stdin)
if event.get("hook_event_name") == "Stop" and (path := os.environ.get("YSTACK_CODEX_AUDIT")):
    record = {
        "time": datetime.now(timezone.utc).isoformat(),
        "session_id": event.get("session_id"),
        "turn_id": event.get("turn_id"),
        "event": "Stop",
    }
    fd = os.open(Path(path), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
    with os.fdopen(fd, "a") as audit:
        audit.write(json.dumps(record) + "\n")
print("{}")
