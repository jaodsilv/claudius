# Testing Framework Documentation

## Overview

This project now includes a comprehensive testing framework with automated CI/CD workflows. The testing setup includes unit tests, integration tests, and automated testing on pull requests.

## Testing Architecture

### 1. Test Structure

```text
tests/
├── conftest.py              # Shared fixtures and configuration
├── unit/                    # Unit tests
│   ├── test_shared.py       # Tests for shared components
│   ├── test_simple_converter.py # Tests for SimpleHTMLToMarkdownConverter
│   └── test_converter.py    # Tests for main converter (future)
├── integration/             # Integration tests
│   ├── test_imports.py      # Circular import and module loading tests
│   └── test_end_to_end.py   # End-to-end workflow tests
└── fixtures/                # Test data
    ├── sample.html          # Sample HTML for testing
    └── expected.md          # Expected Markdown output
```

### 2. Testing Framework

- **pytest**: Main testing framework with async support
- **pytest-cov**: Code coverage reporting
- **pytest-mock**: Mocking capabilities for isolated testing
- **pytest-asyncio**: Support for async test functions

### 3. Configuration Files

- `pytest.ini`: Pytest configuration and test discovery
- `pyproject.toml`: Modern Python project configuration
- `.coveragerc`: Code coverage settings

## Circular Import Resolution

### Problem Solved

The original codebase had circular import dependencies:

- `converter.py` imported from `simple_converter.py` and `chunked_converter.py`
- `simple_converter.py` and `chunked_converter.py` imported shared components from `converter.py`

### Solution Implemented

Created `src/download2md/shared.py` module containing:

- `ConversionItem` namedtuple
- `load_conversions_from_yaml` function
- Shared type definitions

All modules now import shared components from `shared.py`, eliminating circular dependencies while maintaining backward compatibility.

### Backward Compatibility

The `converter.py` module re-exports all shared components, so existing code continues to work:

```python
# Both of these work:
from src.download2md.converter import ConversionItem  # Old way (still works)
from src.download2md.shared import ConversionItem     # New way (recommended)
```

## Running Tests

### Option 1: Using pytest (Recommended)

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test types
pytest -m unit          # Unit tests only
pytest -m integration   # Integration tests only
pytest -m import_test   # Import resolution tests
```

### Option 2: Basic Test Runner

For environments where pytest is not available:

```bash
python3 run_tests.py
```

### Option 3: Manual Import Testing

```bash
python3 -c "
import sys
sys.path.insert(0, '.')
from src.download2md.shared import ConversionItem
from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter
print('✓ All imports successful')
"
```

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/test.yml` file provides:

- **Multi-Python Testing**: Python 3.9, 3.10, 3.11, 3.12
- **Multi-OS Testing**: Ubuntu, Windows, macOS
- **Code Quality Checks**: 
  - Linting with flake8
  - Code formatting with black
  - Type checking with mypy
- **Security Scanning**: 
  - Dependency vulnerability checks with safety
  - Security issue detection with bandit
- **Coverage Reporting**: Automated coverage reports

### Workflow Triggers

- Pull request creation/updates
- Pushes to main/develop branches
- Manual workflow dispatch

## Test Categories

### Unit Tests (`tests/unit/`)

- **test_shared.py**: Tests for `ConversionItem` and YAML loading
- **test_simple_converter.py**: Tests for HTML to Markdown conversion logic
- Focused on individual components and functions
- Fast execution with mocked dependencies

### Integration Tests (`tests/integration/`)

- **test_imports.py**: Validates circular import resolution
- **test_end_to_end.py**: Complete workflow testing
- Tests component interaction and real file I/O
- Validates backward compatibility

### Test Fixtures

- **conftest.py**: Shared test fixtures and utilities
- **fixtures/**: Sample HTML and expected Markdown files
- Temporary directory fixtures for file-based testing

## Coverage Goals

- **Target**: 85% code coverage minimum
- **Excludes**: Test files, `__init__.py`, abstract methods
- **Reports**: HTML and XML coverage reports generated
- **CI Integration**: Coverage failure blocks PR merging

## Quality Gates

1. **Import Resolution**: All modules must import without circular dependency errors
2. **Backward Compatibility**: Existing import patterns must continue to work
3. **Code Coverage**: Minimum 85% coverage required
4. **Code Quality**: Linting and formatting checks must pass
5. **Security**: No high-severity security issues allowed

## Adding New Tests

### Unit Test Example

```python
@pytest.mark.unit
def test_new_functionality():
    \"\"\"Test description.\"\"\"
    # Test implementation
    assert True
```

### Integration Test Example

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_async_functionality(temp_dir, sample_html):
    \"\"\"Test async functionality.\"\"\"
    # Test implementation with fixtures
    pass
```

### Custom Fixtures

Add new fixtures to `conftest.py`:

```python
@pytest.fixture
def custom_fixture():
    \"\"\"Custom fixture description.\"\"\"
    return "test_data"
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure `PYTHONPATH` includes project root
2. **Missing Dependencies**: Install test dependencies with `pip install -r requirements.txt`
3. **Async Test Issues**: Use `@pytest.mark.asyncio` decorator for async tests
4. **Coverage Issues**: Check `.coveragerc` configuration for exclusions

### Debug Commands

```bash
# Verbose test output
pytest -v

# Stop on first failure
pytest -x

# Run specific test
pytest tests/unit/test_shared.py::TestConversionItem::test_conversion_item_creation

# Debug imports
python3 -c "import sys; sys.path.insert(0, '.'); import src.download2md.converter"
```

## Future Enhancements

1. Add performance benchmarking tests
2. Add property-based testing with Hypothesis
3. Add mutation testing with mutmut
4. Expand security testing coverage
5. Add API contract testing for public interfaces
