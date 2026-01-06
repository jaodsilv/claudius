---
name: gitx:parsing-issue-references
description: >-
  Parses issue references from various formats into normalized issue numbers.
  Use when processing issue arguments, branch names, or PR bodies for issue linkage.
version: 1.0.0
---

# Parsing Issue References

Extract issue numbers from various input formats.

## Supported Formats

| Format | Example | Result |
|--------|---------|--------|
| Bare number | `123` | `123` |
| Hash prefix | `#123` | `123` |
| Issue prefix | `issue-123` | `123` |
| GitHub URL | `https://github.com/owner/repo/issues/123` | `123` |
| Branch name | `bugfix/issue-123-fix-login` | `123` |

## Parsing Logic

Check input against patterns in order:

### 1. Bare Number

```regex
^\d+$
```

Input: `123` → Output: `123`

### 2. Hash Prefix

```regex
^#(\d+)$
```

Input: `#123` → Output: `123`

### 3. Issue Prefix

```regex
^issue-(\d+)$
```

Input: `issue-123` → Output: `123`

### 4. GitHub URL

```regex
^https?://github\.com/[^/]+/[^/]+/issues/(\d+)
```

Input: `https://github.com/owner/repo/issues/123` → Output: `123`

### 5. Branch Name

```regex
issue-(\d+)
```

Input: `bugfix/issue-123-fix-login` → Output: `123`

## Usage

Parse the input and return:

```text
{
  issue_number: <number>,
  source_type: <"bare"|"hash"|"prefix"|"url"|"branch">
}
```

If no pattern matches, return:

```text
{
  issue_number: null,
  source_type: "unknown",
  error: "Could not parse issue reference from: <input>"
}
```

## Error Messages

| Condition | Message |
|-----------|---------|
| Empty input | "No issue reference provided" |
| No match | "Could not parse issue reference from: \<input\>" |
| Invalid number | "Invalid issue number: \<value\>" |

## Examples

```text
Input: "123"
→ { issue_number: 123, source_type: "bare" }

Input: "#456"
→ { issue_number: 456, source_type: "hash" }

Input: "https://github.com/acme/repo/issues/789"
→ { issue_number: 789, source_type: "url" }

Input: "feature/issue-42-add-auth"
→ { issue_number: 42, source_type: "branch" }

Input: "not-an-issue"
→ { issue_number: null, source_type: "unknown", error: "..." }
```
