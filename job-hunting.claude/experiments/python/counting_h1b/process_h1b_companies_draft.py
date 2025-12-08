#import sys
import re
import math
import heapq
import math
import asyncio
from collections import Counter, OrderedDict

def read_all_files(args, filter_wa=True):
    for file_path in args:
        yield from read_line_by_line(file_path, filter_wa)

def read_line_by_line(file_path, filter_wa=True):
    with open(file_path, 'r', encoding='utf-16') as file:
        # merge the equivalent companies that are in sequence
        current = None
        for line in file:  # Memory efficient iterator
            # Do not include the headers
            if line[:12] == "Line by line":
                #print(line)
                continue
            args = line.split("\t")
            # Do not include the names with a single or no character
            if len(args[2]) < 2:
                #print(args)
                continue

            # Comment to not filter by Washington state
            if filter_wa and args[6] != "WA":
                continue

            last = Company.build_company(args)
            if current is None:
                current = last
            elif current.are_same_company(last):
                current += last
            else:
                yield current
                current = last
        # yield the last one
        yield current

class Company:
    # args = [Line by line, Fiscal Year, Employer (Petitioner) Name, Tax ID, Industry (NAICS) Code, Petitioner City, Petitioner State, Petitioner Zip Code, Initial Approval, Initial Denial, Continuing Approval, Continuing Denial
    def build_company(args):
        return Company(Company.normalize_str(args[2]),
                       set(args[2]),
                       int(args[8].replace(",", "")) + int(args[10].replace(",", "")),
                       int(args[9].replace(",", "")) + int(args[11].replace(",", "")))

    def __init__(self, name, alternate_names, approved, denied):
        self.name = name
        self.alternate_names = alternate_names
        self.approved = approved
        self.denied = denied
        self.visited = False

    def __add__(self, other):
        """Defines behavior for the + operator"""
        if self.are_same_company(other):
            alternate_names = self.alternate_names | other.alternate_names
            # If they are equivalent always pick the longest name and store the smallest in alternate_names
            alternate_names.add(other.name if len(self.name) > len(other.name) else self.name)
            return Company(self.name if len(self.name) > len(other.name) else other.name,
                           alternate_names,
                           self.approved + other.approved,
                           self.denied + other.denied)

        if isinstance(other, list) and len(other) == 12:
            return self + Company.build_company(other)
        return NotImplemented

    def __radd__(self, other):
        return self.__add__(other)

    def __str__(self):
        return f"{self.name}\t{self.approved}\t{self.alternate_names}"

    def __repr__(self):
        return self.__str__()

    def __hash__(self):
        hash((self.name, self.alternate_names, self.approved, self.visited))

    def visit(self):
        self.visited = True

    def isvisited(self):
        return self.visited

    def are_same_company(self, other):
        return isinstance(other, Company) and self.are_names_equivalent(other.name)

    def are_names_equivalent(self, other_name: str):
        reg = r"\W"
        if self.name == other_name:
            return True
        min_len = min(len(self.name), len(other_name))
        trunc_name = self.name[:min_len]
        trunc_other_name = other_name[:min_len]

        # At least the first word should be equal, therefore there should exist 1 common non-word character
        return trunc_name == trunc_other_name and re.match(r'\W.', trunc_name) != None
# DBA AAA
# AAA DBA
# DBA AAA # AAA DBA
# ^(\w*\t\*)([^\n]*)((?:\n(?!\1)[^\n]*){0,1000})\n\1([^\n]*)\n
#[^A-Z\d\n\t\*]
# DBA     AAA     DBA       AAA
    # [^-\w\t ,\./&\+@\(\)\[#'!^:%$]
    # ACRONYMS: DBA, LLC,
    def normalize_str(name: str):
        regs = [(r"^(?:(?:.*\W)?FACEBOOK|^Meta)(?:\W.*)?$", r"META"),
                (r"^(.*\W)?(ALPHABET|GOOGLE)(\W.*)?$", r"GOOGLE"),
                (r"^(?:.*\W)?(AMAZON|MICROSOFT|COSTCO|APPLE|JPMORGAN|TESLA|ZOOMINFO|PROVIDENCE|STARBUCKS|NORDSTROM|F5|LULULEMON|TWITCH|POKEMON|INFOSYS|INTEL|IBM|PAYPAL|NVIDIA|AMD|ERNST YOUNG|HCL|COGNIZANT|DELOITTE|ACCENTURE|CISCO|LINKEDIN|QUALCOMM|SALESFORCE|DATABRICKS|CAPGEMINI|ORACLE|UBER|CITIBANK|CVS|ADP|TIKTOK|KPMG|COMCAST)(?:\W.*)?$", r"\1"),
                (r"^(.*\W)?(WAL MART|WALMART)(\W.*)?$", r"WALMART"),
                # (r"^GE(\W.*)?$", r"GE"),
                (r"[-/,\.\+\(\):!\\@#]", r" "),
                (r"  +", " "),
                (r"(^|\W)P\W?L\W?L\W?C(\W|$)", r"\1\2"),
                (r"(^|\W)C\W?P\W?A\W?S(\W|$)", r"\1CPAS\2"),
                (r"(^|\W)S\W?V\W?C\W?S(\W|$)", r"\1SVCS\2"),
                (r"(^|\W)O\W?P\W?C\W?O(\W|$)", r"\1OPCO\2"),
                (r"(^|\W)P\W?R\W?O\W?S(\W|$)", r"\1PROS\2"),
                (r"(^|\W)T\W?E\W?C\W?H(\W|$)", r"\1TECH\2"),
                (r"(^|\W)H\W?L\W?T\W?H(\W|$)", r"\1HLTH\2"),
                (r"(^|\W)U\W?N\W?I\W?V(\W|$)", r"\1UNIV\2"),
                (r"(^|\W)H\W?O\W?S\W?P(\W|$)", r"\1HOSP\2"),
                (r"(^|\W)C\W?O\W?R\W?P(\W|$)", r"\1\2"),
                (r"(^|\W)I\W?N\W?T\W?L(\W|$)", r"\1INTL\2"),
                (r"(^|\W)D\W?I\W?S\W?T(\W|$)", r"\1DIST\2"),
                (r"(^|\W)C\W?T\W?R\W?L(\W|$)", r"\1CTRL\2"),
                (r"(^|\W)L\W?A\W?B\W?S(\W|$)", r"\1LABS\2"),
                (r"(^|\W)M\W?E\W?D\W?S(\W|$)", r"\1MEDS\2"),

                (r"(^|\W)L\W?L\W?C(\W|$)", r"\1\2"),
                (r"(^|\W)I\W?N\W?C(\W|$)", r"\1\2"),
                (r"(^|\W)D\W?B\W?A(\W|$)", r"\1\2"),
                (r"(^|\W)L\W?T\W?E(\W|$)", r"\1\2"),
                (r"(^|\W)C\W?O\W?M(\W|$)", r"\1\2"),
                (r"(^|\W)F\W?K\W?A(\W|$)", r"\1\2"),
                (r"(^|\W)D\W?D\W?S(\W|$)", r"\1\2"),
                (r"(^|\W)L\W?L\W?P(\W|$)", r"\1\2"),
                (r"(^|\W)L\W?T\W?D(\W|$)", r"\1\2"),
                (r"(^|\W)U\W?S\W?A(\W|$)", r"\1USA\2"),
                (r"(^|\W)T\W?E\W?K(\W|$)", r"\1TEK\2"),
                (r"(^|\W)C\W?P\W?A(\W|$)", r"\1CPA\2"),
                (r"(^|\W)P\W?R\W?O(\W|$)", r"\1PRO\2"),
                (r"(^|\W)M\W?E\W?D(\W|$)", r"\1MED\2"),
                (r"(^|\W)C\W?T\W?R(\W|$)", r"\1CTR\2"),
                (r"(^|\W)L\W?E\W?E(\W|$)", r"\1LEE\2"),
                (r"(^|\W)P\W?B\W?C(\W|$)", r"\1PBC\2"),
                (r"(^|\W)D\W?M\W?D(\W|$)", r"\1DMD\2"),
                (r"(^|\W)P\W?R\W?O(\W|$)", r"\1PRO\2"),
                (r"(^|\W)S\W?C\W?I(\W|$)", r"\1SCI\2"),
                (r"(^|\W)D\W?R\W?S(\W|$)", r"\1DRS\2"),
                (r"(^|\W)C\W?A\W?T(\W|$)", r"\1CAT\2"),
                (r"(^|\W)L\W?A\W?B(\W|$)", r"\1LAB\2"),
                (r"(^|\W)A\W?V\W?E(\W|$)", r"\1AVE\2"),
                (r"(^|\W)M\W?E\W?D(\W|$)", r"\1MED\2"),

                (r"(^|\W)U\W?S(\W|$)", r"\1\2"),
                (r"(^|\W)N\W?A(\W|$)", r"\1\2"),
                (r"(^|\W)L\W?P(\W|$)", r"\1\2"),
                (r"(^|\W)I\W?T(\W|$)", r"\1IT\2"),
                (r"(^|\W)P\W?C(\W|$)", r"\1PC\2"),
                (r"(^|\W)C\W?O(\W|$)", r"\1CO\2"),
                (r"(^|\W)I\W?N(\W|$)", r"\1IN\2"),
                (r"(^|\W)P\W?A(\W|$)", r"\1PA\2"),
                (r"(^|\W)L\W?L(\W|$)", r"\1LL\2"),
                (r"(^|\W)N\W?Y(\W|$)", r"\1NY\2"),
                (r"(^|\W)N\W?A(\W|$)", r"\1NA\2"),
                (r"(^|\W)D\W?E(\W|$)", r"\1DE\2"),
                (r"(^|\W)M\W?D(\W|$)", r"\1MD\2"),
                (r"(^|\W)L\W?A(\W|$)", r"\1LA\2"),
                (r"(^|\W)D\W?B(\W|$)", r"\1DB\2"),
                (r"(^|\W)I\W?I(\W|$)", r"\1II\2"),
                (r"(^|\W)R\W?X(\W|$)", r"\1RX\2"),
                (r"(^|\W)S\W?C(\W|$)", r"\1SC\2"),
                (r"(^|\W)R\W?E(\W|$)", r"\1RE\2"),
                (r"(^|\W)B\W?U(\W|$)", r"\1BU\2"),
                (r"(^|\W)C\W?A(\W|$)", r"\1CA\2"),
                (r"(^|\W)I\W?O(\W|$)", r"\1IO\2"),
                (r"(^|\W)S\W?K(\W|$)", r"\1SK\2"),
                (r"(^|\W)V\W?A(\W|$)", r"\1VA\2"),
                (r"(^|\W)N\W?J(\W|$)", r"\1NJ\2"),
                (r"(^|\W)P\W?T(\W|$)", r"\1PT\2"),
                (r"(^|\W)A\W?G(\W|$)", r"\1AG\2"),
                (r"(^|\W)S\W?T(\W|$)", r"\1ST\2"),
                (r"(^|\W)N\W?W(\W|$)", r"\1NW\2"),
                (r"(^|\W)S\W?W(\W|$)", r"\1SW\2"),
                (r"(^|\W)N\W?E(\W|$)", r"\1NE\2"),
                (r"(^|\W)S\W?E(\W|$)", r"\1SE\2"),
                (r"(^|\W)D\W?R(\W|$)", r"\1DR\2"),

                (r"^THE ", r""),
                # Any two isolated chars
                (r"((?:\W|^)\w)\W?(\w(?:\W|$))", r"\1\2"),

                (r"(^|\W)(?:LIMITED)(\W|$)", r"\1\2"),
                (r"(^|\W)SERVICES(\W|$)", r"\1SVCS\2"),
                (r"(^|\W)INFRASTRUCTURE(\W|$)", r"\1INFRA\2"),
                (r"(^|\W)TECHNOLOG(?:Y|IES)(\W|$)", r"\1TECH\2"),
                (r"(^|\W)HEALTH(\W|$)", r"\1HLTH\2"),
                (r"(^|\W)UNIVERSITY(\W|$)", r"\1UNIV\2"),
                (r"(^|\W)HOSPITAL(\W|$)", r"\1HOSP\2"),
                (r"(^|\W)(?:CORPORATION|CORP)(\W|$)", r"\1\2"),
                (r"(^|\W)(?:INT'L|(INTERNATIONAL(?:IZATIONS?)?))(\W|$)", r"\1INTL\2"),
                (r"(^|\W)DISTRIBUTED|DISTRIBUTION(\W|$)", r"\1DIST\2"),
                (r"(^|\W)CONTROL(\W|$)", r"\1CTRL\2"),
                (r"(^|\W)LABORATORIES(\W|$)", r"\1LABS\2"),
                (r"(^|\W)MEDICINES(\W|$)", r"\1MEDS\2"),
                (r"(^|\W)SOFTWARE(\W|$)", r"\1SOFT\2"),

                (r"(^|\W)SCIENCE(\W|$)", r"\1SCI\2"),
                (r"(^|\W)DOCTORS(\W|$)", r"\1DRS\2"),
                (r"(^|\W)PREFESSIONAL((?:S)?)(\W|$)", r"\1PRO\2\3"),
                (r"(^|\W)CATEGORY(\W|$)", r"\1CAT\2"),
                (r"(^|\W)LABORATORY(\W|$)", r"\1LAB\2"),
                (r"(^|\W)AVENUE(\W|$)", r"\1AVE\2"),
                (r"(^|\W)(?:MEDICINE|MEDICAL)(\W|$)", r"\1MED\2"),

                (r"(^|\W)NORTHWEST(\W|$)", r"\1NW\2"),
                (r"(^|\W)SOUTHWEST(\W|$)", r"\1SW\2"),
                (r"(^|\W)NORTHEAST(\W|$)", r"\1NE\2"),
                (r"(^|\W)SOUTHEAST(\W|$)", r"\1SE\2"),
                (r"(^|\W)(?:DRIVE|DOCTOR|DOC)(\W|$)", r"\1DR\2"),
                (r"(^|\W)STREET(\W|$)", r"\1ST\2"),

                (r"(^|\W)NORTH(\W|$)", r"\1N\2"),
                (r"(^|\W)SOUTH(\W|$)", r"\1S\2"),
                (r"(^|\W)WEST(\W|$)", r"\1W\2"),
                (r"(^|\W)EAST(\W|$)", r"\1E\2"),

                (r"(\W)\1+", r"\1"),
                (r"  +", " ")]
        name = name.replace("&", " AND ").replace("$", "S").replace("[", "")
        for (reg, rep) in regs:
            name = re.sub(reg, rep, name)
        return name.replace("'", " ")

def group_companies(companies):
    # for this strategy to work we must materialize everything.
    companies = list(companies)
    for i, company1 in enumerate(companies):
        if company1.isvisited():
            continue
        company1.visit()
        aggregated = company1
        # I know all companies before companies[i+1] are visited already
        for company2 in companies[i+1:]:
            if aggregated.are_same_company(company2.name):
                company2.visit()
                aggregated += company2
            # do nothing if they are not the same company

        yield aggregated

def top_approvers(companies, top=100, reverse=False):
    key = lambda obj: obj.approved
    method = heapq.nlargest if reverse else heapq.nsmallest
    return method(top, companies, key=key)

def companies_to_kv(companies):
    for company in companies:
        yield (company.name, company.approved)

def companies_to_simple_dict(companies):
    agg = {}
    for company in companies:
        if company.name in agg:
            agg[company.name] += company.approved
        else:
            agg[company.name] = company.approved
    return agg

def explode_company_names(companies, func):
    for company in companies:
        for _ in range(func(company)):
            yield company.name

async def top_companies4(filenames, name, filter_wa=True):
    print(f"Starting process {name}")
    processed_files = read_all_files(filenames[-1:], filter_wa)
    strs = ["------------------------------------------------------------------"] * 2
    strs.append(f"Top approvers {name}")
    companies_exploded = explode_company_names(processed_files, lambda x: x.approved)
    companies_exploded_denied = explode_company_names(processed_files, lambda x: x.denied)
    counter = Counter(companies_exploded)
    counter_total = Counter(companies_exploded_denied) + counter
    top_companies = counter.most_common(200)

    maxlen = 0
    for rank, (company, approved) in enumerate(top_companies, start=1):
        char_count = math.floor(math.log10(rank)+1) + len(company)+ math.floor(math.log10(approved) + 1) + math.floor(math.log10(counter_total[company]) + 1) + 6
        if char_count > maxlen:
            maxlen = char_count
        strs.append(f"{rank}: {company}: {approved}, {counter_total[company]}")
    strs.append("------------------------------------------------------------------")
    strs.append("------------------------------------------------------------------")
    strs.append(f"MaxLen: {maxlen}")
    strs.append("------------------------------------------------------------------")
    strs.append("------------------------------------------------------------------")
    return '\n'.join(strs)

async def main():
    all_filenames = [r"D:\Downloads\Employer Information.2022.csv", r"D:\Downloads\Employer Information.2023.csv", r"D:\Downloads\Employer Information.2024.csv"]
    filename2024 = all_filenames[2:]
    inputs=[(all_filenames, "2022-2024 USA", False), (all_filenames, "2022-2024 WA", True), (filename2024, "2024 USA", False), (filename2024, "2024 WA", True)]
    tasks = [top_companies4(input[0], input[1], input[2]) for input in inputs]

    for completed in asyncio.as_completed(tasks):
        result = await completed
        print(result)

asyncio.run(main())


# DEPRECATED
def top_companies(filenames):
    #processed_files = read_all_files(sys.argv[1:])
    processed_files = read_all_files(filenames)

    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")
    print("top_approvers")
    companies = group_companies(processed_files)
    top_companies = top_approvers(companies)
    for rank, (company) in enumerate(top_companies):
        print(f"{rank+1}: {company}")
    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")

def top_companies2(filenames):
    #processed_files = read_all_files(sys.argv[1:])
    processed_files = read_all_files(filenames)

    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")
    print("top_approvers")
    company_approvals = companies_to_kv(processed_files)
    counter = Counter(company_approvals)
    top_companies = counter.most_common(100)

    for rank, (company, total) in enumerate(top_companies):
        print(f"{rank+1}: {company}: {total}")
    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")

def top_companies3(filenames):
    #print(sys.argv)
    processed_files = read_all_files(filenames)

    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")
    print("top_approvers")
    company_approvals = companies_to_simple_dict(processed_files)
    counter = Counter(company_approvals)
    top_companies = counter.most_common(100)

    for rank, (company, total) in enumerate(top_companies, start=1):
        print(f"{rank}: {company}: {total}")
    print("------------------------------------------------------------------")
    print("------------------------------------------------------------------")

def top_small_words():
    file = r"D:\Downloads\Job Offers\General\H1BSponsors2022To2024.tsv"

    counter = Counter(read_line_by_line_dict(file))

    top = counter.most_common(100)
    for word, total in top:
        print(word, total)

def read_line_by_line_dict(file_path):
    with open(file_path, 'r') as file:
        for line in file:  # Memory efficient iterator
            # Do not include empty lines
            if line == "" or line == "\n":
                #print(line)
                continue
            args = line.split("\t")
            total = sum([int(x) for x in args[1].split("+")])
            for _ in range(total):
                yield args[0]

def filter_singles(counter):
    for val in counter:
        print(val)
        return

def filter_greater_than(items, threshold):
    return Counter({k:v for k,v in items if v > threshold})
