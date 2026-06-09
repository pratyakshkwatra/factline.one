from typing import List, Dict, Any
from abc import ABC, abstractmethod
from app.models.database import CandidateItem

class BaseDiscoveryProvider(ABC):
    @abstractmethod
    async def discover(self, session) -> List[Dict[str, Any]]:
        """
        Executes discovery and returns a list of dictionaries with keys:
        - source: str
        - items: List[CandidateItem]
        - status: str
        - time: float
        """
        pass
