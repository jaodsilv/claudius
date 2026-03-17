"""Tests for scripts/lib/count-tokens.py"""

import math
import subprocess
import sys
from pathlib import Path

import pytest

# Add scripts/lib to path so we can import count_tokens
REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_LIB = REPO_ROOT / "scripts" / "lib"
sys.path.insert(0, str(SCRIPTS_LIB))

import importlib

count_tokens = importlib.import_module("count-tokens")

# ---------------------------------------------------------------------------
# detect_content_type
# ---------------------------------------------------------------------------


class TestDetectContentType:
    """Test detect_content_type() for all extension categories."""

    @pytest.mark.parametrize(
        "filepath,expected",
        [
            ("readme.md", "prose"),
            ("notes.txt", "prose"),
            ("doc.rst", "prose"),
            ("article.adoc", "prose"),
            ("paper.tex", "prose"),
            ("outline.org", "prose"),
        ],
    )
    def test_prose_extensions(self, filepath, expected):
        assert count_tokens.detect_content_type(filepath) == expected

    @pytest.mark.parametrize(
        "filepath,expected",
        [
            ("main.py", "code"),
            ("app.js", "code"),
            ("index.ts", "code"),
            ("component.jsx", "code"),
            ("page.tsx", "code"),
            ("Main.java", "code"),
            ("main.go", "code"),
            ("lib.rs", "code"),
            ("util.c", "code"),
            ("util.cpp", "code"),
            ("util.h", "code"),
            ("util.hpp", "code"),
            ("app.rb", "code"),
            ("script.sh", "code"),
            ("init.bash", "code"),
            ("rc.zsh", "code"),
            ("setup.ps1", "code"),
            ("Program.cs", "code"),
            ("main.swift", "code"),
            ("Main.kt", "code"),
            ("App.scala", "code"),
            ("index.php", "code"),
            ("script.lua", "code"),
            ("analysis.r", "code"),
            ("module.ex", "code"),
            ("module.exs", "code"),
            ("Main.hs", "code"),
            ("module.ml", "code"),
            ("core.clj", "code"),
            ("config.vim", "code"),
            ("init.el", "code"),
            ("query.sql", "code"),
            ("index.html", "code"),
            ("style.css", "code"),
            ("style.scss", "code"),
            ("style.less", "code"),
            ("App.vue", "code"),
            ("Page.svelte", "code"),
        ],
    )
    def test_code_extensions(self, filepath, expected):
        assert count_tokens.detect_content_type(filepath) == expected

    @pytest.mark.parametrize(
        "filepath,expected",
        [
            ("config.json", "conf"),
            ("config.yaml", "conf"),
            ("config.yml", "conf"),
            ("pyproject.toml", "conf"),
            ("settings.ini", "conf"),
            ("app.cfg", "conf"),
            ("nginx.conf", "conf"),
            (".env", "conf"),
            ("pom.xml", "conf"),
            ("data.csv", "conf"),
            ("app.properties", "conf"),
        ],
    )
    def test_conf_extensions(self, filepath, expected):
        assert count_tokens.detect_content_type(filepath) == expected

    @pytest.mark.parametrize(
        "filepath",
        [
            ".gitignore",
            ".gitattributes",
            ".editorconfig",
            ".prettierrc",
            ".eslintrc",
            ".dockerignore",
            ".npmrc",
            ".nvmrc",
            ".flake8",
            ".pylintrc",
            ".rubocop.yml",
        ],
    )
    def test_dotfile_names(self, filepath):
        assert count_tokens.detect_content_type(filepath) == "conf"

    def test_unknown_dotfile(self):
        """Unknown dotfiles (starting with . but not in DOTFILE_NAMES) → conf."""
        assert count_tokens.detect_content_type(".somerc") == "conf"

    def test_unknown_extension(self):
        """Unknown extensions default to conf."""
        assert count_tokens.detect_content_type("file.xyz") == "conf"


# ---------------------------------------------------------------------------
# count_tokens_char
# ---------------------------------------------------------------------------


class TestCountTokensChar:
    """Test count_tokens_char() with known inputs."""

    def test_prose(self):
        text = "a" * 400  # 400 chars / 4.0 = 100 tokens
        assert count_tokens.count_tokens_char(text, "prose") == 100

    def test_code(self):
        text = "x" * 325  # 325 chars / 3.25 = 100 tokens
        assert count_tokens.count_tokens_char(text, "code") == 100

    def test_conf(self):
        text = "c" * 275  # 275 chars / 2.75 = 100 tokens
        assert count_tokens.count_tokens_char(text, "conf") == 100

    def test_non_latin(self):
        text = "n" * 150  # 150 chars / 1.5 = 100 tokens
        assert count_tokens.count_tokens_char(text, "non-latin") == 100

    def test_rounds_up(self):
        text = "a" * 401  # 401 / 4.0 = 100.25 → ceil = 101
        assert count_tokens.count_tokens_char(text, "prose") == 101

    def test_empty(self):
        assert count_tokens.count_tokens_char("", "code") == 0


# ---------------------------------------------------------------------------
# count_tokens_word
# ---------------------------------------------------------------------------


class TestCountTokensWord:
    """Test count_tokens_word() with known inputs."""

    def test_prose(self):
        # 100 words * 1.33 = 133 tokens
        text = " ".join(["word"] * 100)
        assert count_tokens.count_tokens_word(text, "prose") == 133

    def test_code(self):
        # 100 words * 1.5 = 150 tokens
        text = " ".join(["var"] * 100)
        assert count_tokens.count_tokens_word(text, "code") == 150

    def test_conf(self):
        # 100 words * 1.8 = 180 tokens
        text = " ".join(["key"] * 100)
        assert count_tokens.count_tokens_word(text, "conf") == 180

    def test_non_latin(self):
        # 100 words * 2.5 = 250 tokens
        text = " ".join(["word"] * 100)
        assert count_tokens.count_tokens_word(text, "non-latin") == 250

    def test_rounds_up(self):
        # 3 words * 1.33 = 3.99 → ceil = 4
        text = "one two three"
        assert count_tokens.count_tokens_word(text, "prose") == 4

    def test_empty(self):
        assert count_tokens.count_tokens_word("", "code") == 0


# ---------------------------------------------------------------------------
# CLI: --stdin mode
# ---------------------------------------------------------------------------

SCRIPT_PATH = str(SCRIPTS_LIB / "count-tokens.py")


class TestStdinMode:
    """Test --stdin CLI mode."""

    def test_stdin_porcelain(self):
        """--stdin with --porcelain outputs a token count."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--stdin", "--porcelain", "--base", "char"],
            input="hello world this is a test string",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        token_count = int(result.stdout.strip())
        assert token_count > 0

    def test_stdin_force_content_type(self):
        """--stdin + --force-content-type overrides default."""
        result = subprocess.run(
            [
                sys.executable,
                SCRIPT_PATH,
                "--stdin",
                "--porcelain",
                "--base",
                "char",
                "--force-content-type",
                "prose",
            ],
            input="hello world test",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        token_count = int(result.stdout.strip())
        # prose: 16 chars / 4.0 = 4 tokens
        assert token_count == math.ceil(len("hello world test") / 4.0)

    def test_stdin_default_content_type_is_code(self):
        """--stdin defaults content type to code."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--stdin", "--porcelain", "--base", "char"],
            input="x" * 325,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        # code: 325 / 3.25 = 100
        assert int(result.stdout.strip()) == 100

    def test_stdin_empty_input(self):
        """Empty stdin → 0 tokens."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--stdin", "--porcelain"],
            input="",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert int(result.stdout.strip()) == 0

    def test_stdin_whitespace_only(self):
        """Whitespace-only stdin → 0 tokens."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--stdin", "--porcelain"],
            input="   \n\n  ",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert int(result.stdout.strip()) == 0

    def test_stdin_verbose_output(self):
        """--stdin without --porcelain shows source as <stdin>."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--stdin", "--base", "char"],
            input="some content here",
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "<stdin>" in result.stdout
        # Should NOT have "Size:" line (no file to stat)
        assert "Size:" not in result.stdout


# ---------------------------------------------------------------------------
# CLI: mutual exclusion
# ---------------------------------------------------------------------------


class TestMutualExclusion:
    """Test --stdin and --filepath are mutually exclusive."""

    def test_both_flags_errors(self):
        """Passing both --stdin and --filepath should fail."""
        result = subprocess.run(
            [
                sys.executable,
                SCRIPT_PATH,
                "--stdin",
                "--filepath",
                "somefile.txt",
                "--porcelain",
            ],
            input="data",
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0
        assert "not allowed" in result.stderr.lower() or "exclusive" in result.stderr.lower()

    def test_neither_flag_errors(self):
        """Passing neither --stdin nor --filepath should fail."""
        result = subprocess.run(
            [sys.executable, SCRIPT_PATH, "--porcelain"],
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0
        assert "required" in result.stderr.lower()


# ---------------------------------------------------------------------------
# CLI: --filepath still works (backward compat)
# ---------------------------------------------------------------------------


class TestFilepathCompat:
    """Verify --filepath mode still works after changes."""

    def test_filepath_porcelain(self, tmp_path):
        """--filepath with --porcelain outputs a token count."""
        test_file = tmp_path / "test.py"
        test_file.write_text("x" * 325, encoding="utf-8")
        result = subprocess.run(
            [
                sys.executable,
                SCRIPT_PATH,
                "--filepath",
                str(test_file),
                "--porcelain",
                "--base",
                "char",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        # .py → code → 325 / 3.25 = 100
        assert int(result.stdout.strip()) == 100

    def test_filepath_verbose(self, tmp_path):
        """--filepath without --porcelain shows file info including Size."""
        test_file = tmp_path / "test.md"
        test_file.write_text("hello world", encoding="utf-8")
        result = subprocess.run(
            [
                sys.executable,
                SCRIPT_PATH,
                "--filepath",
                str(test_file),
                "--base",
                "word",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "Size:" in result.stdout
        assert str(test_file) in result.stdout
