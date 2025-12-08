"""
Indeed Job Scraper - Phase 1 Implementation
Includes company blacklisting, salary filtering, and all required filters
"""

import requests
from bs4 import BeautifulSoup
import re
import time
from datetime import datetime
from typing import List, Dict, Optional
import json
from urllib.parse import quote

class CompanyBlacklist:
    """Manages company blacklist with subsidiaries"""

    def __init__(self):
        self.blacklist = {
            'permanent': {
                'Meta': ['Meta', 'Facebook', 'Instagram', 'WhatsApp', 'Oculus', 'Reality Labs'],
                'Amazon': ['Amazon', 'AWS', 'Audible', 'Twitch', 'Whole Foods', 'Zappos',
                          'Ring', 'PillPack', 'Kiva Systems', 'Lab126', 'Amazon Web Services'],
                'Microsoft': ['Microsoft', 'LinkedIn', 'GitHub', 'Xbox', 'Activision',
                             'Activision Blizzard', 'Mojang', 'Nuance', 'Skype']
            },
            'industries': ['Aerospace', 'Defense', 'Aviation', 'Space', 'Military']
        }

    def is_blacklisted(self, company_name: str, job_description: str = "") -> bool:
        """Check if company or job is blacklisted"""
        if not company_name:
            return False

        # Normalize company name
        company_lower = company_name.lower().strip()

        # Check against all blacklisted companies and subsidiaries
        for parent, subsidiaries in self.blacklist['permanent'].items():
            for subsidiary in subsidiaries:
                if subsidiary.lower() in company_lower:
                    return True

        # Check industry keywords in company name or description
        combined_text = f"{company_name} {job_description}".lower()
        for industry in self.blacklist['industries']:
            if industry.lower() in combined_text:
                return True

        return False

class SalaryEstimator:
    """Estimates salary for jobs without listed compensation"""

    def __init__(self):
        # Base salary ranges by title level (in thousands)
        self.base_ranges = {
            'intern': (80, 120),
            'junior': (100, 140),
            'mid': (130, 170),
            'senior': (150, 200),
            'staff': (180, 250),
            'principal': (220, 300),
            'director': (250, 350),
            'vp': (300, 500)
        }

        # Company multipliers for known high-paying companies
        self.company_multipliers = {
            'google': 1.3,
            'netflix': 1.4,
            'apple': 1.25,
            'stripe': 1.35,
            'databricks': 1.35,
            'airbnb': 1.2,
            'uber': 1.15,
            'lyft': 1.15,
            'salesforce': 1.1,
            'oracle': 0.95,
            'intel': 0.9
        }

    def estimate_salary(self, title: str, company: str, description: str) -> Dict:
        """Estimate salary range based on title, company, and description"""

        # Determine level from title
        level = self._extract_level(title, description)
        base_min, base_max = self.base_ranges.get(level, (130, 180))

        # Apply company multiplier if known
        company_lower = company.lower()
        multiplier = 1.0
        for comp, mult in self.company_multipliers.items():
            if comp in company_lower:
                multiplier = mult
                break

        # Adjust for remote vs location
        if 'remote' in title.lower() or 'remote' in description.lower():
            multiplier *= 0.95  # Slight reduction for remote

        estimated_min = int(base_min * multiplier * 1000)
        estimated_max = int(base_max * multiplier * 1000)

        return {
            'estimated': True,
            'min': estimated_min,
            'max': estimated_max,
            'confidence': 'medium' if multiplier != 1.0 else 'low'
        }

    def _extract_level(self, title: str, description: str) -> str:
        """Extract seniority level from title and description"""
        text = f"{title} {description}".lower()

        if any(word in text for word in ['vp', 'vice president']):
            return 'vp'
        elif any(word in text for word in ['director']):
            return 'director'
        elif any(word in text for word in ['principal', 'distinguished']):
            return 'principal'
        elif any(word in text for word in ['staff', 'lead']):
            return 'staff'
        elif any(word in text for word in ['senior', 'sr.']):
            return 'senior'
        elif any(word in text for word in ['junior', 'jr.', 'entry']):
            return 'junior'
        elif any(word in text for word in ['intern', 'internship']):
            return 'intern'
        else:
            return 'mid'

class IndeedScraper:
    """Main Indeed job scraper with all filters"""

    def __init__(self):
        self.base_url = "https://www.indeed.com/jobs"
        self.blacklist = CompanyBlacklist()
        self.salary_estimator = SalaryEstimator()
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }

        # Search configuration
        self.search_config = {
            'queries': ['Software Engineer', 'Backend Engineer', 'Data Engineer'],
            'locations': [
                {'name': 'Redmond, WA', 'radius': 25},
                {'name': 'United States', 'remote': True}
            ],
            'salary_min': 150000,
            'experience_range': (3, 9)
        }

    def get_daily_jobs(self) -> List[Dict]:
        """Main method to get daily job listings"""
        all_jobs = []

        for query in self.search_config['queries']:
            for location in self.search_config['locations']:
                print(f"Searching: {query} in {location['name']}")
                jobs = self._search_jobs(query, location)
                all_jobs.extend(jobs)
                time.sleep(2)  # Be respectful to Indeed's servers

        # Remove duplicates based on job ID
        unique_jobs = {job['id']: job for job in all_jobs}.values()

        # Filter jobs
        filtered_jobs = self._apply_filters(list(unique_jobs))

        print(f"Total jobs found: {len(all_jobs)}, After filtering: {len(filtered_jobs)}")
        return filtered_jobs

    def _search_jobs(self, query: str, location: Dict) -> List[Dict]:
        """Search Indeed for specific query and location"""
        jobs = []

        # Build search URL
        params = {
            'q': query,
            'l': location['name'],
            'sort': 'date',
            'fromage': '1'  # Last 24 hours
        }

        if location.get('radius'):
            params['radius'] = location['radius']

        if location.get('remote'):
            params['q'] += ' remote'

        # Indeed typically shows 15 jobs per page
        for start in range(0, 50, 10):  # Get up to 50 jobs per query
            params['start'] = start

            try:
                response = requests.get(self.base_url, params=params, headers=self.headers)
                response.raise_for_status()

                soup = BeautifulSoup(response.text, 'html.parser')
                page_jobs = self._parse_search_results(soup)

                if not page_jobs:
                    break

                jobs.extend(page_jobs)

            except Exception as e:
                print(f"Error searching Indeed: {e}")
                break

        return jobs

    def _parse_search_results(self, soup: BeautifulSoup) -> List[Dict]:
        """Parse Indeed search results page"""
        jobs = []

        # Find job cards - Indeed's structure changes, so we try multiple selectors
        job_cards = soup.find_all('div', class_='job_seen_beacon') or \
                   soup.find_all('div', class_='jobsearch-SerpJobCard') or \
                   soup.find_all('div', {'data-testid': 'job-card'})

        for card in job_cards:
            try:
                job = self._extract_job_info(card)
                if job:
                    jobs.append(job)
            except Exception as e:
                print(f"Error parsing job card: {e}")
                continue

        return jobs

    def _extract_job_info(self, card) -> Optional[Dict]:
        """Extract job information from a job card"""
        try:
            # Title
            title_elem = card.find('h2', class_='jobTitle') or card.find('a', {'data-testid': 'job-title'})
            title = title_elem.get_text(strip=True) if title_elem else None

            if not title:
                return None

            # Company
            company_elem = card.find('span', class_='companyName') or card.find('div', class_='companyName')
            company = company_elem.get_text(strip=True) if company_elem else 'Unknown'

            # Location
            location_elem = card.find('div', class_='companyLocation') or card.find('div', class_='locationsContainer')
            location = location_elem.get_text(strip=True) if location_elem else 'Unknown'

            # Job ID
            job_id = card.get('data-jk') or card.find('a', {'data-testid': 'job-title'}).get('href', '').split('jk=')[-1][:16]

            # URL
            url = f"https://www.indeed.com/viewjob?jk={job_id}"

            # Salary (if available)
            salary_elem = card.find('div', class_='salary-snippet') or card.find('span', class_='salary-snippet')
            salary_text = salary_elem.get_text(strip=True) if salary_elem else None

            # Description snippet
            snippet_elem = card.find('div', class_='job-snippet')
            snippet = snippet_elem.get_text(strip=True) if snippet_elem else ''

            # Parse salary
            salary_info = self._parse_salary(salary_text) if salary_text else None

            # If no salary, fetch full job details for better estimation
            if not salary_info:
                full_description = self._fetch_job_details(url)
                if not full_description:
                    full_description = snippet

                salary_info = self.salary_estimator.estimate_salary(title, company, full_description)

            return {
                'id': job_id,
                'title': title,
                'company': company,
                'location': location,
                'url': url,
                'salary': salary_info,
                'snippet': snippet,
                'posted_date': datetime.now().isoformat(),
                'source': 'Indeed'
            }

        except Exception as e:
            print(f"Error extracting job info: {e}")
            return None

    def _parse_salary(self, salary_text: str) -> Optional[Dict]:
        """Parse salary text into structured format"""
        # Remove commas and convert to lowercase
        text = salary_text.replace(',', '').lower()

        # Try to find salary amounts
        amounts = re.findall(r'\$?(\d+)[k]?', text)

        if not amounts:
            return None

        # Convert to annual salary
        min_salary = int(amounts[0])
        max_salary = int(amounts[-1]) if len(amounts) > 1 else min_salary

        # Handle hourly rates
        if 'hour' in text or '/hr' in text:
            min_salary *= 2080  # 40 hours/week * 52 weeks
            max_salary *= 2080
        # Handle 'k' notation
        elif 'k' in text or (min_salary < 1000 and max_salary < 1000):
            min_salary *= 1000
            max_salary *= 1000

        return {
            'estimated': False,
            'min': min_salary,
            'max': max_salary,
            'original_text': salary_text
        }

    def _fetch_job_details(self, url: str) -> str:
        """Fetch full job description from job URL"""
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')
            description_elem = soup.find('div', id='jobDescriptionText') or \
                             soup.find('div', class_='jobsearch-JobComponent-description')

            return description_elem.get_text() if description_elem else ""

        except Exception as e:
            print(f"Error fetching job details: {e}")
            return ""

    def _apply_filters(self, jobs: List[Dict]) -> List[Dict]:
        """Apply all filters to job list"""
        filtered = []

        for job in jobs:
            # Check blacklist
            if self.blacklist.is_blacklisted(job['company'], job['snippet']):
                continue

            # Check salary
            if job.get('salary'):
                if job['salary']['max'] < self.search_config['salary_min']:
                    continue

            # Check education requirements (would need full description)
            # This is a simplified check - in production, you'd fetch full descriptions
            if self._requires_advanced_degree(job['title'], job['snippet']):
                continue

            # Check experience requirements
            if not self._matches_experience_range(job['title'], job['snippet']):
                continue

            filtered.append(job)

        return filtered

    def _requires_advanced_degree(self, title: str, description: str) -> bool:
        """Check if job requires Master's or PhD"""
        text = f"{title} {description}".lower()

        # Patterns that indicate advanced degree requirement
        advanced_patterns = [
            "master's required",
            "masters required",
            "ms required",
            "m.s. required",
            "phd required",
            "ph.d. required",
            "doctorate required",
            "advanced degree required"
        ]

        return any(pattern in text for pattern in advanced_patterns)

    def _matches_experience_range(self, title: str, description: str) -> bool:
        """Check if job matches experience range (3-9 years)"""
        text = f"{title} {description}".lower()

        # Extract years of experience
        exp_patterns = [
            r'(\d+)\+?\s*years?\s*(?:of\s*)?experience',
            r'(\d+)\s*-\s*(\d+)\s*years?\s*(?:of\s*)?experience',
            r'minimum\s*(\d+)\s*years?'
        ]

        min_exp, max_exp = self.search_config['experience_range']

        for pattern in exp_patterns:
            matches = re.findall(pattern, text)
            if matches:
                if isinstance(matches[0], tuple):
                    # Range pattern
                    req_min = int(matches[0][0])
                    req_max = int(matches[0][1]) if len(matches[0]) > 1 else req_min
                else:
                    # Single number
                    req_min = req_max = int(matches[0])

                # Check if requirement overlaps with our range
                if req_max < min_exp or req_min > max_exp:
                    return False

        # If no specific requirement found, assume it matches
        return True

# Example usage
if __name__ == "__main__":
    scraper = IndeedScraper()
    jobs = scraper.get_daily_jobs()

    # Save results
    with open(f"jobs_{datetime.now().strftime('%Y%m%d')}.json", 'w') as f:
        json.dump(jobs, f, indent=2)

    print(f"\nSaved {len(jobs)} jobs to file")

    # Display sample results
    for job in jobs[:3]:
        print(f"\nTitle: {job['title']}")
        print(f"Company: {job['company']}")
        print(f"Salary: ${job['salary']['min']:,} - ${job['salary']['max']:,} "
              f"({'estimated' if job['salary']['estimated'] else 'listed'})")
        print(f"URL: {job['url']}")
