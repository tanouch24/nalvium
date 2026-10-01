from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class ManualCandidate:
    manufacturer: str
    model: str
    title: str
    source_url: str
    source_domain: str
    confidence: float
    verified_official_source: bool = False


class ManualProvider(Protocol):
    def lookup(self, manufacturer: str, model: str) -> list[ManualCandidate]: ...


class NoopManualProvider:
    """Explicit placeholder: no external manufacturer lookup is performed in Lot 3."""
    def lookup(self, manufacturer: str, model: str) -> list[ManualCandidate]:
        return []
