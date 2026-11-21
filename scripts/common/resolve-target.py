#!/usr/bin/env python3
"""Resolve a public alias from the trusted runtime mapping, fail closed."""
import json
import os
import re
import sys

ALIASES = {f"repo-{n:02d}" for n in range(1, 7)}

try:
    mapping = json.loads(os.environ["PRIVATE_REPOS_JSON"])
    target = os.environ["TARGET_ALIAS"]
    if not isinstance(mapping, dict) or not set(mapping).issubset(ALIASES):
        raise ValueError
    if target not in ALIASES or target not in mapping:
        raise ValueError
    # Reject malformed, empty, or non-unique identities. The requested alias is
    # the only identity accepted from the event; repo slugs come from the secret.
    values = list(mapping.values())
    if any(not isinstance(v, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", v) for v in values):
        raise ValueError
    if len({v.casefold() for v in values}) != len(values):
        raise ValueError
except (KeyError, TypeError, ValueError, json.JSONDecodeError):
    print("Invalid or unsupported target mapping.", file=sys.stderr)
    sys.exit(2)

print(mapping[target])
