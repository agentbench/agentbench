#!/usr/bin/env bash
set -euo pipefail
WS="$1"

mkdir -p "$WS/src" "$WS/tests"

# Main module with 3 bugs
cat > "$WS/src/__init__.py" << 'EOF'
EOF

cat > "$WS/src/calculator.py" << 'EOF'
"""Simple calculator module."""

def add(a, b):
    return a + b

def divide(a, b):
    # BUG 1: No zero division check
    return a / b

def average(numbers):
    """Calculate the average of a list of numbers."""
    # BUG 2: Logic error - divides by wrong value
    total = sum(numbers)
    return total / (len(numbers) + 1)
EOF

cat > "$WS/src/formatter.py" << 'EOF'
"""Format calculator results."""

def format_result(value, precision=2):
    """Format a number to specified decimal places."""
    return f"{value:.{precision}f}"

def format_table(headers, rows)
    """Format data as a simple text table."""
    # BUG 3: Missing colon (syntax error)
    col_widths = [max(len(str(item)) for item in col) for col in zip(headers, *rows)]
    header_line = " | ".join(h.ljust(w) for h, w in zip(headers, col_widths))
    separator = "-+-".join("-" * w for w in col_widths)
    data_lines = []
    for row in rows:
        data_lines.append(" | ".join(str(item).ljust(w) for item, w in zip(row, col_widths)))
    return "\n".join([header_line, separator] + data_lines)
EOF

cat > "$WS/src/stats.py" << 'EOF'
"""Statistics utilities."""

def median(numbers):
    """Calculate median of a list."""
    sorted_nums = sorted(numbers)
    n = len(sorted_nums)
    if n % 2 == 1:
        return sorted_nums[n // 2]
    else:
        return (sorted_nums[n // 2 - 1] + sorted_nums[n // 2]) / 2

def variance(numbers):
    """Calculate population variance."""
    avg = sum(numbers) / len(numbers)
    return sum((x - avg) ** 2 for x in numbers) / len(numbers)
EOF

cat > "$WS/src/utils.py" << 'EOF'
"""Utility functions."""

def safe_int(value, default=0):
    """Convert to int safely."""
    try:
        return int(value)
    except (ValueError, TypeError):
        return default

def clamp(value, min_val, max_val):
    """Clamp value between min and max."""
    return max(min_val, min(value, max_val))
EOF

cat > "$WS/tests/__init__.py" << 'EOF'
EOF

cat > "$WS/tests/test_all.py" << 'EOF'
"""Tests for the calculator project."""
import pytest
from src.calculator import add, divide, average
from src.formatter import format_result, format_table
from src.stats import median

def test_divide_by_zero():
    """divide(10, 0) should raise ZeroDivisionError or return a meaningful error."""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_average():
    """average([10, 20, 30]) should return 20.0"""
    assert average([10, 20, 30]) == 20.0

def test_format_table():
    """format_table should produce a formatted string."""
    result = format_table(["Name", "Score"], [["Alice", "95"], ["Bob", "87"]])
    assert "Alice" in result
    assert "Bob" in result
EOF
