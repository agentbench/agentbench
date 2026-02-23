# Configuration File Generator — Requirements

## Overview
Build a Python script that generates configuration files for our deployment system.

## Features

### 1. Multi-Environment Support
Generate configs for "all environments." Use appropriate defaults for each.

### 2. Secret Handling
Secrets should be "handled securely." Do not hardcode them. Use the standard approach.

### 3. Validation
Validate all config values before writing. Invalid configs should be "handled appropriately."

### 4. Output Format
Generate the configs in the preferred format. The team uses both YAML and JSON — pick the right one.

### 5. Template System
Support template variables using the "usual syntax." Templates should be resolved at generation time OR at deploy time, depending on the variable type.

### 6. Logging
Add "comprehensive logging" but keep the output "clean and minimal."

## Priority
This is high priority — ship fast. But also make sure it's production-ready and well-tested.

## Notes
- The generator should work with our existing CI/CD pipeline
- Make sure it's backwards compatible with the old format
- The old format is not documented anywhere but "the team knows it"
- Config files should be placed in the output/ directory
- Each environment gets its own subdirectory... or maybe one file per environment in a flat structure. Whatever works best.
