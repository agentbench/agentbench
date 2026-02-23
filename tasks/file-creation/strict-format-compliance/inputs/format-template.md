# Document Format Template

All project status documents MUST follow this exact format:

## Frontmatter (YAML, between `---` delimiters)
Required fields in this exact order:
```
---
title: [Document Title]
author: [Author Name]
date: [YYYY-MM-DD format, ISO 8601]
status: [draft|review|approved|final]
revision: [integer, starting at 1]
---
```

## Document Structure

After frontmatter, the document must contain these sections IN THIS EXACT ORDER:

1. `# [Project Name]` — Single H1 heading (only one in the entire document)
2. `## Executive Summary` — 2-3 paragraph overview
3. `---` — Horizontal rule separator
4. `## Timeline` — Must include:
   - `### Milestones` subsection with dates in YYYY-MM-DD format
   - `### Current Phase` subsection
5. `---` — Horizontal rule separator  
6. `## Budget` — Must include:
   - `### Allocated` subsection
   - `### Spent` subsection
   - `### Remaining` subsection
7. `---` — Horizontal rule separator
8. `## Risks` — Numbered list, each with severity (High/Medium/Low)
9. `## Next Steps` — Bulleted list with owner in parentheses

## Formatting Rules
- All monetary values: `$X,XXX.XX` format
- All dates in body text: YYYY-MM-DD format
- No H4 or deeper headings allowed
- Exactly one blank line between sections
- No trailing whitespace on any line
