import heapq
from typing import Iterable, Any
from
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class SkillRelevanceForJobPositions:
    backend: float
    data_eng: float
    general_swe: float
    distrib_systems: float
    weights: list[float]

    def average(self) -> float:
        return (self.backend + self.data_eng + self.general_swe + self.distrib_systems) / 4

    def weighted_average(self) -> float:
        return (self.backend * self.weights[0] + self.data_eng * self.weights[1] + self.general_swe * self.weights[2] + self.distrib_systems * self.weights[3])/sum(self.weights)

    def __repr__(self) -> str:
        return f"{self.backend}, {self.data_eng}, {self.general_swe}, {self.distrib_systems}"

    def __str__(self) -> str:
        return f"Backend: {self.backend}, Data Eng: {self.data_eng}, General SWE: {self.general_swe}, Distrib Systems: {self.distrib_systems}"

    def __lt__(self, other: Any) -> bool:

@dataclass
class SkillFrequencyInJobPosts:
    title: int
    description: int
    required: int
    preferred: int
    raw_relevance: float|None
    normalized_relevance: float|None

    def __post_init__(self):
        # Ensure all values are integers
        self.title = int(self.title)
        self.description = int(self.description)
        self.required = int(self.required)
        self.preferred = int(self.preferred)
        self.raw_relevance = None
        self.normalized_relevance = None

    def absolute_relevance(self, sample_size: int) -> float:
        '''
        Computes the absolute relevance score of a skill based on its frequency in different sections of the job description.
        The score is weighted by section importance (title > required > preferred > description).
        The result is stored in self.non_normalized_relevance and is in the range (0,1].
        Althought values for result == 0 is possible when all counts are 0, it will never happen, as I cannot add a skill that is not mentioned in any job posting.
        '''
        # Weight the different components based on their importance
        title_weight = 4.0
        description_weight = 1.0
        required_weight = 3.0
        preferred_weight = 2.0

        # Calculate maximum possible weighted sum
        max_weighted_sum = sample_size * (title_weight + description_weight + required_weight + preferred_weight)

        # Calculate actual weighted sum
        weighted_sum = (
            self.title * title_weight +
            self.description * description_weight +
            self.required * required_weight +
            self.preferred * preferred_weight
        )

        # Normalize to range [0,1]
        non_normalized_relevance = weighted_sum / max_weighted_sum
        self.raw_relevance = non_normalized_relevance

    def __repr__(self) -> str:
        return f"{self.title}, {self.description}, {self.required}, {self.preferred}{", " if self.raw_relevance is not None else ""}{self.raw_relevance}{", " if self.normalized_relevance is not None else ""}{self.normalized_relevance}"

    def __str__(self) -> str:
        return f"Title Count: {self.title}, Description Count: {self.description}, Required Count: {self.required}, Preferred Count: {self.preferred}{", Raw Relevance: " if self.raw_relevance is not None else ""}{self.raw_relevance}{", Normalized Relevance: " if self.normalized_relevance is not None else ""}{self.normalized_relevance}"

class SkillFrequency(Skill):
    def __init__(self, name, *, title, description, required, preferred, diff_threshold=1, diff_threshold_percentage=0.10, precision=1):
        super().__init__(name, diff_threshold=diff_threshold, precision=precision)
        self.frequency = SkillFrequencyInJobPosts(title, description, required, preferred)

    def __lt__(self, other):
        return self.frequency < other.frequency

    def get_relevance(self, sample_size: int) -> float:
        self.frequency.absolute_relevance(sample_size)

    def __lt__(self, other: Any) -> bool:
        pass

    def __gt__(self, other: Any) -> bool:
        pass

    def __eq__(self, other: Any) -> bool:
        pass

    def __ne__(self, other: Any) -> bool:
        pass

    def __repr__(self) -> str:
        pass

    def __str__(self) -> str:
        pass

class SkillRelevance(Skill):
    def __init__(self, name, *, backendRelevance, dataEngRelevance, generalSWERelevance, distribSystemsRelevance, priority_order, diff_threshold=0.03, precision=1):
        super().__init__(name, diff_threshold=diff_threshold, precision=precision)
        self.relevance = SkillRelevanceForJobPositions(
            backend=backendRelevance,
            data_eng=dataEngRelevance,
            general_swe=generalSWERelevance,
            distrib_systems=distribSystemsRelevance
        )
        # Normalize priority order to handle name variants
        normalized_order = []
        for category in priority_order:
            category_lower = category.lower()
            if any(term in category_lower for term in ['backend', 'back-end', 'back end']):
                normalized_order.append('backend')
            elif any(term in category_lower for term in ['data', 'dataeng', 'data-eng', 'data eng']):
                normalized_order.append('dataeng')
            elif any(term in category_lower for term in ['general', 'swe', 'software', 'general swe']):
                normalized_order.append('generalswe')
            elif any(term in category_lower for term in ['distrib', 'distributed', 'distrib-sys', 'distrib sys']):
                normalized_order.append('distribsys')
        self.priority_order = normalized_order

    def get_relevance(self) -> float:
        pass

    def __lt__(self, other: Any) -> bool:
        pass

    def __gt__(self, other: Any) -> bool:
        pass

    def __eq__(self, other: Any) -> bool:
        pass

    def __ne__(self, other: Any) -> bool:
        pass

    def __repr__(self) -> str:
        pass

    def __str__(self) -> str:
        pass

class Skill(ABC):
    def __init__(self, name: str, *, diff_threshold: float = 0.03, precision: int = 1) -> None:
        self.name = name
        self.diff_threshold = diff_threshold
        self.print_precision = precision

    @abstractmethod
    def get_relevance(self) -> float:
        pass

    @abstractmethod
    def __lt__(self, other: Any) -> bool:
        pass

    @abstractmethod
    def __gt__(self, other: Any) -> bool:
        pass

    @abstractmethod
    def __eq__(self, other: Any) -> bool:
        pass

    @abstractmethod
    def __ne__(self, other: Any) -> bool:
        pass

    @abstractmethod
    def __repr__(self) -> str:
        pass

    @abstractmethod
    def __str__(self) -> str:
        pass

class SkillCollection(Iterable[Skill]):
    def __init__(self, skills):
        self.skills_max = skills.copy()
        self.skills_min = skills.copy()
        heapq._heapify_max(self.skills_max)
        heapq.heapify(self.skills_min)

    def pop_max(self) -> Skill:
        return heapq.heappop(self.skills_max)

    def pop_min(self) -> Skill:
        return heapq.heappop(self.skills_min)

    def __iter__(self):
        return iter(self.skills_max)

    def averageRelevance(self):
        return sum(skill.averageRelevance() for skill in self.skills_max) / len(self.skills_max)

    def averageBackendRelevance(self):
        return sum(skill.relevance.backend for skill in self.skills_max) / len(self.skills_max)

    def averageDataEngRelevance(self):
        return sum(skill.relevance.data_eng for skill in self.skills_max) / len(self.skills_max)

    def averageGeneralSWERelevance(self):
        return sum(skill.relevance.general_swe for skill in self.skills_max) / len(self.skills_max)

    def averageDistribSystemsRelevance(self):
        return sum(skill.relevance.distrib_systems for skill in self.skills_max) / len(self.skills_max)

    def resetAndPopMin(self):
        self.skills_min = self.skills_max.copy()
        heapq.heapify(self.skills_min)
        return heapq.heappop(self.skills_min)

    def fullyEmpty(self):
        return len(self.skills_min) == 0

    def __repr__(self):
        return f"Stats:\n\tAverage relevance: {self.averageRelevance()*100:.1f}%\n\tAverage backend relevance: {self.averageBackendRelevance()*100:.1f}%\n\tAverage data engineering relevance: {self.averageDataEngRelevance()*100:.1f}%\n\tAverage general SWE relevance: {self.averageGeneralSWERelevance()*100:.1f}%\n\tAverage distributed systems relevance: {self.averageDistribSystemsRelevance()*100:.1f}%\nSkills sorted by relevance (most relevant first):\n{self.skills_str()}"

    def skills_str(self):
        skills = heapq.nlargest(len(self.skills_max), self.skills_max)
        return ", ".join(str(skill) for skill in skills)
