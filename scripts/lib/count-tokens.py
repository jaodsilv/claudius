#!/usr/bin/env python3
"""Estimate or exactly count tokens for any file.

Supports three counting bases:
  - char: character-based estimation using chars-per-token ratios
  - word: word-based estimation using tokens-per-word ratios
  - sdk:  exact count via Anthropic SDK's count_tokens API

When no --base is given, uses 'sdk' if available, otherwise falls back
to the best heuristic for the detected content type.
"""

import argparse
import math
import os
import sys

# ---------------------------------------------------------------------------
# Content-type detection
# ---------------------------------------------------------------------------

PROSE_EXTENSIONS = frozenset(
    ".md .txt .rst .adoc .tex .org".split()
)

CODE_EXTENSIONS = frozenset(
    ".py .js .ts .jsx .tsx .java .go .rs .c .cpp .h .hpp .rb .sh .bash .zsh "
    ".ps1 .cs .swift .kt .scala .php .lua .r .ex .exs .hs .ml .clj .vim .el "
    ".sql .html .css .scss .less .vue .svelte".split()
)

CONF_EXTENSIONS = frozenset(
    ".json .yaml .yml .toml .ini .cfg .conf .env .xml .csv .properties".split()
)

DOTFILE_NAMES = frozenset(
    ".gitignore .gitattributes .editorconfig .prettierrc .eslintrc "
    ".dockerignore .npmrc .nvmrc .flake8 .pylintrc .rubocop.yml".split()
)


def detect_content_type(filepath: str) -> str:
    """Infer content type from file extension. Never returns 'non-latin'."""
    basename = os.path.basename(filepath)
    _, ext = os.path.splitext(basename)
    ext = ext.lower()

    if basename in DOTFILE_NAMES or (not ext and basename.startswith(".")):
        return "conf"
    if ext in PROSE_EXTENSIONS:
        return "prose"
    if ext in CODE_EXTENSIONS:
        return "code"
    if ext in CONF_EXTENSIONS:
        return "conf"
    # Unknown extension → default to conf
    return "conf"


# ---------------------------------------------------------------------------
# Default base per content type (when SDK is unavailable)
# ---------------------------------------------------------------------------

DEFAULT_BASE = {
    "prose": "word",
    "code": "char",
    "conf": "char",
    "non-latin": "char",
}

# ---------------------------------------------------------------------------
# Estimation ratios
# ---------------------------------------------------------------------------

CHARS_PER_TOKEN = {
    "prose": 4.0,
    "code": 3.25,
    "conf": 2.75,
    "non-latin": 1.5,
}

TOKENS_PER_WORD = {
    "prose": 1.33,
    "code": 1.5,
    "conf": 1.8,
    "non-latin": 2.5,
}

# ---------------------------------------------------------------------------
# SDK helpers
# ---------------------------------------------------------------------------

SDK_AVAILABLE = False
_anthropic = None
_client = None


def _init_sdk():
    """Try to import anthropic and create a client. Returns True on success."""
    global SDK_AVAILABLE, _anthropic, _client
    try:
        import anthropic  # noqa: F811

        _anthropic = anthropic
        client = anthropic.Anthropic()
        if not client.api_key:
            return False
        _client = client
        SDK_AVAILABLE = True
        return True
    except Exception:
        return False


def _resolve_model(family: str) -> str:
    """Resolve a model family keyword to the latest model ID.

    1. Try client.models.list() and pick the latest matching model.
    2. Fall back to known aliases if the API call fails.
    """
    known_fallbacks = {
        "opus": "claude-opus-4-6",
        "sonnet": "claude-sonnet-4-5-20250929",
        "haiku": "claude-haiku-4-5-20251001",
    }

    try:
        models = _client.models.list()
        matches = []
        for model in models:
            model_id = model.id if hasattr(model, "id") else str(model)
            if family in model_id:
                matches.append(model_id)
        if matches:
            matches.sort()
            return matches[-1]
    except Exception:
        pass

    return known_fallbacks.get(family, known_fallbacks["sonnet"])


def count_tokens_sdk(text: str, model_family: str) -> tuple[int, str]:
    """Count tokens using the Anthropic SDK. Returns (count, resolved_model_id)."""
    model_id = _resolve_model(model_family)
    response = _client.messages.count_tokens(
        model=model_id,
        messages=[{"role": "user", "content": text}],
    )
    return response.input_tokens, model_id


# ---------------------------------------------------------------------------
# Estimation functions
# ---------------------------------------------------------------------------


def count_tokens_char(text: str, content_type: str) -> int:
    """Estimate tokens from character count."""
    char_count = len(text)
    ratio = CHARS_PER_TOKEN[content_type]
    return math.ceil(char_count / ratio)


def count_tokens_word(text: str, content_type: str) -> int:
    """Estimate tokens from word count."""
    word_count = len(text.split())
    ratio = TOKENS_PER_WORD[content_type]
    return math.ceil(word_count * ratio)


# ---------------------------------------------------------------------------
# File reading
# ---------------------------------------------------------------------------


def read_file(filepath: str) -> str:
    """Read file as UTF-8 text."""
    if not os.path.exists(filepath):
        print(f"Error: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        print(f"Error: file is not valid UTF-8: {filepath}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Estimate or count tokens for a file."
    )
    parser.add_argument(
        "--filepath", required=True, help="Path to the file to analyze"
    )
    parser.add_argument(
        "--force-content-type",
        choices=["prose", "code", "conf", "non-latin"],
        default=None,
        help="Override auto-detected content type (ignored by --base sdk)",
    )
    parser.add_argument(
        "--base",
        choices=["char", "word", "sdk"],
        default=None,
        help="Counting method (default: sdk if available, else per content-type)",
    )
    parser.add_argument(
        "--model",
        choices=["sonnet", "opus", "haiku"],
        default="sonnet",
        help="Model family for SDK counting (default: sonnet)",
    )
    parser.add_argument(
        "--porcelain",
        action="store_true",
        help="Output only the token count (machine-readable)",
    )
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    # Read file
    text = read_file(args.filepath)

    # Detect content type
    content_type = args.force_content_type or detect_content_type(args.filepath)

    # Initialize SDK (best-effort)
    _init_sdk()

    # Resolve base
    base = args.base
    if base is None:
        base = "sdk" if SDK_AVAILABLE else DEFAULT_BASE[content_type]

    # Validate SDK availability when explicitly requested
    if base == "sdk" and not SDK_AVAILABLE:
        print(
            "Error: --base sdk requires the anthropic SDK and ANTHROPIC_API_KEY",
            file=sys.stderr,
        )
        sys.exit(1)

    # Count tokens
    resolved_model = None
    if base == "sdk":
        token_count, resolved_model = count_tokens_sdk(text, args.model)
        method_desc = f"sdk ({args.model} \u2192 {resolved_model})"
    elif base == "char":
        token_count = count_tokens_char(text, content_type)
        ratio = CHARS_PER_TOKEN[content_type]
        method_desc = f"char ({ratio} chars/token for {content_type})"
    else:  # word
        token_count = count_tokens_word(text, content_type)
        ratio = TOKENS_PER_WORD[content_type]
        method_desc = f"word ({ratio} tokens/word for {content_type})"

    # Output
    if args.porcelain:
        print(token_count)
    else:
        file_size = os.path.getsize(args.filepath)
        line_count = text.count("\n") + (1 if text and not text.endswith("\n") else 0)
        char_count = len(text)
        word_count = len(text.split())

        print(f"File:         {args.filepath}")
        print(f"Size:         {file_size:,} bytes")
        print(f"Lines:        {line_count:,}")
        print(f"Characters:   {char_count:,}")
        print(f"Words:        {word_count:,}")
        print(f"Content type: {content_type}")
        print(f"Method:       {method_desc}")
        print(f"Tokens:       {token_count:,}")


if __name__ == "__main__":
    main()
