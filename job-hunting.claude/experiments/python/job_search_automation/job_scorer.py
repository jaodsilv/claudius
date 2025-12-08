# Local Python script - job_scorer.py
# Run daily via cron/Task Scheduler
import requests
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd

TARGET_ROLES = [
    "Software Engineer", "Backend Engineer", "Data Engineer",
    "Distributed Systems Engineer", "Software Developer"
]
EXPERIENCE_RANGE = (3, 9)  # years
TARGET_LOCATIONS = ["Remote in the United States", "Redmond, WA"]
