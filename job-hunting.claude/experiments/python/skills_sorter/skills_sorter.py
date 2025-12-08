from skills import Skill, SkillCollection

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Sort skills by relevance')
    parser.add_argument('--skills', type=str, default=skills_str,
                      help='Comma-separated list of skills with relevance percentages')
    parser.add_argument('--precision', type=int, default=1,
                      help='Precision of the relevance percentages')
    parser.add_argument('--diff_threshold', type=float, default=0.03,
                      help='Threshold for the relevance difference')
    parser.add_argument('--priority_order', type=str, default="backend, dataeng, generalswe, distribsys",
                      help='Priority order of the skills')
    args = parser.parse_args()

    skills_str = args.skills
    # Parse the skills string into a list of Skill objects
    skills_str = """Distributed Systems Design and Architecture (95%, 85%, 80%, 100%), Microservices Patterns (95%, 75%, 75%, 95%), High-Availability Solutions (95%, 80%, 75%, 95%), REST and gRPC API Patterns (95%, 70%, 80%, 85%), Horizontal Scalability (95%, 85%, 75%, 95%), Service Isolation (95%, 75%, 70%, 90%), Python (90%, 95%, 85%, 85%), Java (90%, 85%, 85%, 85%), Go (90%, 75%, 80%, 85%), C# (.NET/.NET Framework/.NET Core) (85%, 70%, 80%, 75%), Scala (80%, 90%, 70%, 75%), Apache Spark (75%, 95%, 65%, 80%), Stream Processing (75%, 95%, 65%, 85%), Real-time Analytics (75%, 90%, 65%, 80%), ETL/ELT Workflows (70%, 95%, 60%, 75%), Container Orchestration (Kubernetes and Docker) (85%, 80%, 75%, 85%), Apache Kafka (85%, 85%, 70%, 85%), Azure Service Bus (85%, 75%, 70%, 80%), Message Queue Systems (85%, 80%, 70%, 85%), Concurrent Programming (90%, 70%, 75%, 85%), Multi-threading (90%, 70%, 75%, 85%), Goroutines (90%, 65%, 70%, 80%), Performance Optimization (90%, 80%, 80%, 90%), System Reliability Engineering (90%, 75%, 75%, 90%), High-throughput Systems (90%, 85%, 70%, 90%), Distributed Storage Solutions (HDFS, Parquet, ORC) (80%, 95%, 65%, 85%), SQL Databases (85%, 90%, 80%, 80%), NoSQL Databases (BigTable, Azure Cosmos DB) (85%, 90%, 75%, 85%), Cloud Storage (Google Cloud Storage, Azure Data Lake) (80%, 90%, 70%, 80%), Azure Cloud Services (80%, 80%, 75%, 80%), Google Cloud Platform (GCP) Services (80%, 80%, 75%, 80%), CI/CD Pipelines (85%, 75%, 85%, 80%), Test Automation (85%, 70%, 85%, 75%), Monitoring and Observability (90%, 75%, 75%, 85%), Performance Profiling and Tuning (90%, 75%, 75%, 85%), Root Cause Analysis (85%, 70%, 75%, 80%), Incident Response (85%, 70%, 75%, 80%), SLO/SLI Management (85%, 70%, 70%, 80%), Caching Strategies (90%, 70%, 70%, 85%), Load Balancing (90%, 70%, 70%, 85%), Auto-scaling Infrastructure (85%, 75%, 70%, 85%), Infrastructure-as-Code (IaC) (80%, 75%, 70%, 80%), Security Engineering (80%, 70%, 75%, 75%), Data Pipeline Design and Development (70%, 95%, 60%, 75%), Large-Scale Data Processing (75%, 95%, 65%, 80%), Google Cloud Dataflow (70%, 90%, 60%, 75%), Apache Beam (70%, 90%, 60%, 75%), Data Governance and Quality Assurance (65%, 90%, 60%, 70%), Technical Leadership (75%, 70%, 80%, 75%), Cross-functional Collaboration (70%, 65%, 80%, 70%), Agile Methodologies (Scrum, XP) (70%, 65%, 80%, 65%), Software Design Patterns (85%, 70%, 85%, 80%), Algorithms and Data Structures (85%, 70%, 85%, 80%), Test-driven Development (TDD) (80%, 65%, 85%, 70%), Behavior-driven Development (BDD) (75%, 60%, 80%, 65%), Code Quality & Static Analysis (80%, 65%, 85%, 70%), DevOps Practices (80%, 70%, 75%, 75%), Bazel Build System (75%, 65%, 70%, 70%), C/C++ (75%, 60%, 75%, 70%), Ruby (65%, 55%, 70%, 60%), Lua (60%, 50%, 65%, 55%), Android Development (50%, 40%, 70%, 45%), Web Development (HTML, CSS, JavaScript) (55%, 45%, 75%, 50%), Technical Documentation (70%, 65%, 75%, 70%), Mentorship and Coaching (65%, 60%, 70%, 65%)"""

    skills_list = []
    # Split by the last occurrence of "), " to handle nested parentheses
    for skill_str in skills_str.split("), "):
        # Add back the closing parenthesis that was removed by split
        if not skill_str.endswith(")"):
            skill_str += ")"

        # Find the last opening parenthesis for percentages
        last_open_paren = skill_str.rfind("(")
        name = skill_str[:last_open_paren].strip()
        percentages = skill_str[last_open_paren+1:-1].split(", ")

        # Convert percentages to floats (remove % and convert to decimal)
        backend = float(percentages[0].replace("%", "")) / 100
        data_eng = float(percentages[1].replace("%", "")) / 100
        general_swe = float(percentages[2].replace("%", "")) / 100
        distrib_systems = float(percentages[3].replace("%", "")) / 100

        skills_list.append(Skill(
            name,
            backend_relevance=backend,
            data_eng_relevance=data_eng,
            general_swe_relevance=general_swe,
            distrib_systems_relevance=distrib_systems,
            priority_order=args.priority_order.split(",")
        ))

    # Create a SkillCollection and print skills in order
    collection = SkillCollection(skills_list)

    while not collection.fullyEmpty():
        print(f"Average relevance: {collection.averageRelevance()*100:.1f}%")
        print(f"Average backend relevance: {collection.averageBackendRelevance()*100:.1f}%")
        print(f"Average data engineering relevance: {collection.averageDataEngRelevance()*100:.1f}%")
        print(f"Average general SWE relevance: {collection.averageGeneralSWERelevance()*100:.1f}%")
        print(f"Average distributed systems relevance: {collection.averageDistribSystemsRelevance()*100:.1f}%")
        print("Skills sorted by relevance (most relevant first):")
        while skills_list:
            skill = collection.pop()
            print(f"{skill}", end=", " if skills_list else "\n")

        print()
        if len(collection.skills_min) > 1:
            print(f"Result Removing Mininimum Relevance: {collection.resetAndPopMin()}")
            print()


if __name__ == "__main__":
    main()
