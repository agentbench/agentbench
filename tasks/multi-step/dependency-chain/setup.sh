#!/usr/bin/env bash
set -euo pipefail

# Initialize git repo
git init
git config user.name "test"
git config user.email "test@test.com"

# Create pipeline doc
cat > PIPELINE.md << 'EOF'
# Data Processing Pipeline

Execute these 6 steps in order. Each step uses the output of the previous step.

## Step 1: Parse Raw Data
Parse `raw-data.txt` into `parsed-data.json`. The raw data uses a custom
format with `|` delimiters. Extract: id, name, value, type, date.

## Step 2: Validate
Validate each entry against `schema.json`. Create `validation-report.md`
listing valid and invalid entries with reasons for any failures.

## Step 3: Categorize
Categorize validated entries into groups by their `type` field. Write to
`categorized-data.json`. Note: some entries have ambiguous types (e.g.,
"service/product" could go in either category). Document your decision.

## Step 4: Statistics
Generate `category-stats.md` with per-category counts, total values,
and averages.

## Step 5: Summary CSV
Create `summary.csv` with one row per category: category, count, total_value,
avg_value, min_value, max_value.

## Step 6: Final Report
Write `final-report.md` synthesizing all findings. Include analysis,
key findings, anomalies discovered, and recommendations.
EOF

# Create schema
cat > schema.json << 'EOF'
{
  "required_fields": ["id", "name", "value", "type", "date"],
  "types": {
    "id": "string (format: ITEM-NNN)",
    "name": "string (non-empty)",
    "value": "number (positive)",
    "type": "string (one of: product, service, subscription, hybrid)",
    "date": "string (YYYY-MM-DD)"
  }
}
EOF

# Create raw data with ambiguous entries
cat > raw-data.txt << 'EOF'
ITEM-001|Widget Pro|149.99|product|2025-01-05
ITEM-002|Cloud Hosting|299.00|service|2025-01-06
ITEM-003|SaaS License|49.99|subscription|2025-01-07
ITEM-004|Managed Database|199.00|service/product|2025-01-08
ITEM-005|Hardware Kit|89.50|product|2025-01-09
ITEM-006|API Access|15.00|service/subscription|2025-01-10
ITEM-007|Training Course|500.00|service|2025-01-11
ITEM-008|Software Bundle|299.99|product/subscription|2025-01-12
ITEM-009|Consulting Hour|175.00|service|2025-01-13
ITEM-010|Premium Support|99.99|hybrid|2025-01-14
ITEM-011||45.00|product|2025-01-15
ITEM-012|Data Backup|29.99|service|2025-01-16
ITEM-013|Analytics Tool|-10.00|subscription|2025-01-17
ITEM-014|Custom Integration|750.00|service|2025-01-18
ITEM-015|Starter Kit|19.99|product|2025-01-19
ITEM-016|Enterprise Plan|999.00|subscription|2025-01-20
ITEM-017|Setup Fee|0|service|2025-01-21
ITEM-018|Monitor Pro|349.99|product|2025-01-22
ITEM-019|Compliance Audit|1200.00|service/product|2025-01-23
ITEM-020|Dev Tools|FREE|subscription|2025-01-24
EOF

git add -A
git commit -m "initial: data processing pipeline project"
