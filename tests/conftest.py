#!/usr/bin/env python3
"""
Shared pytest fixtures and configuration for the test suite.
"""

import os
import tempfile
import pytest
from pathlib import Path


@pytest.fixture
def temp_dir():
    """Create a temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmp_dir:
        yield Path(tmp_dir)


@pytest.fixture
def sample_html():
    """Sample HTML content for testing."""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Document</title>
    </head>
    <body>
        <h1>Main Heading</h1>
        <p>This is a paragraph with <strong>bold text</strong> and <em>italic text</em>.</p>
        <ul>
            <li>First item</li>
            <li>Second item</li>
        </ul>
        <a href="https://example.com">Example Link</a>
        <img src="image.jpg" alt="Test Image">
        <pre><code>print("Hello, World!")</code></pre>
    </body>
    </html>
    """


@pytest.fixture
def complex_html():
    """More complex HTML with navigation and ads to test cleaning."""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Complex Document</title>
    </head>
    <body>
        <nav class="navigation">
            <ul>
                <li><a href="/home">Home</a></li>
                <li><a href="/about">About</a></li>
            </ul>
        </nav>
        <header class="site-header">
            <h1>Site Title</h1>
        </header>
        <main>
            <article>
                <h1>Article Title</h1>
                <p>Main article content here.</p>
                <h2>Subsection</h2>
                <p>More content with <code>inline code</code>.</p>
            </article>
        </main>
        <aside class="sidebar">
            <div class="advertisement">
                <p>Buy our product!</p>
            </div>
        </aside>
        <footer>
            <p>Copyright 2024</p>
        </footer>
    </body>
    </html>
    """


@pytest.fixture
def sample_yaml_config(temp_dir):
    """Create a sample YAML configuration file."""
    yaml_content = """
root_path: "{}"
max_concurrent: 3
conversion_strategy: "auto"
large_file_threshold_kb: 500
medium_file_threshold_kb: 100
chunk_size_kb: 50
chunk_overlap_kb: 5
conversions:
  - input_filename: "test1.html"
    output_filename: "test1.md"
  - input_filename: "test2.html" 
    output_filename: "test2.md"
""".format(str(temp_dir))
    
    config_file = temp_dir / "config.yaml"
    config_file.write_text(yaml_content)
    return config_file


@pytest.fixture
def html_file(temp_dir, sample_html):
    """Create a temporary HTML file for testing."""
    html_file = temp_dir / "test.html"
    html_file.write_text(sample_html)
    return html_file


@pytest.fixture
def large_html_file(temp_dir):
    """Create a large HTML file for testing chunked conversion."""
    content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Large Document</title>
    </head>
    <body>
        <h1>Large Document</h1>
    """
    
    # Add content to make it large enough
    for i in range(1000):
        content += f"""
        <section>
            <h2>Section {i}</h2>
            <p>This is section {i} with some content to make the file larger. 
            It contains multiple sentences to simulate a real document structure.
            We need enough content to trigger chunked processing in our converter.</p>
        </section>
        """
    
    content += """
    </body>
    </html>
    """
    
    html_file = temp_dir / "large_test.html"
    html_file.write_text(content)
    return html_file


@pytest.fixture(scope="session")
def project_root():
    """Get the project root directory."""
    return Path(__file__).parent.parent