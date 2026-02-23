#!/bin/bash
set -e
cp "${CLAUDE_PLUGIN_ROOT}/tasks/memory/factual-qa-recall/inputs/questions.json" .answers-key.json
cp "${CLAUDE_PLUGIN_ROOT}/tasks/memory/factual-qa-recall/inputs/briefing.md" briefing.md
cp "${CLAUDE_PLUGIN_ROOT}/tasks/memory/factual-qa-recall/inputs/questions.json" questions.json
