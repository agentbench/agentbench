#!/usr/bin/env bash
set -euo pipefail
WS="$1"

cd "$WS"
git init
git config user.name "test-dev"
git config user.email "test@example.com"

# Initial commit on main
cat > app.py << 'EOF'
def greet(name):
    return f"Hello, {name}!"

def calculate(a, b):
    return a + b

if __name__ == "__main__":
    print(greet("World"))
EOF

cat > README.md << 'EOF'
# MyApp
A simple application.
EOF

cat > .github/workflows/ci.yml << 'BROKEN'
name: CI
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: python -m pytest tests/
        # BUG: missing 'uses: actions/setup-python@v4' step
        # BUG: missing 'with: python-version' specification
BROKEN
mkdir -p .github/workflows tests

cat > tests/test_app.py << 'EOF'
from app import greet, calculate

def test_greet():
    assert greet("Alice") == "Hello, Alice!"

def test_calculate():
    assert calculate(2, 3) == 5
EOF

git add -A
git commit -m "Initial commit"

# Create feature-a branch with changes
git checkout -b feature-a
cat > app.py << 'EOF'
def greet(name):
    return f"Hi, {name}! Welcome!"

def calculate(a, b):
    return a + b

def multiply(a, b):
    return a * b

if __name__ == "__main__":
    print(greet("World"))
    print(multiply(3, 4))
EOF
git add -A
git commit -m "Add multiply function and update greeting"

# Create feature-b branch from main with conflicting changes
git checkout main
git checkout -b feature-b
cat > app.py << 'EOF'
def greet(name):
    return f"Hello there, {name}!"

def calculate(a, b):
    return a + b

def subtract(a, b):
    return a - b

if __name__ == "__main__":
    print(greet("World"))
    print(subtract(10, 3))
EOF
git add -A
git commit -m "Add subtract function and update greeting"

# Create feature-c branch with README changes
git checkout main
git checkout -b feature-c
cat > README.md << 'EOF'
# MyApp
A simple Python application with math utilities.

## Features
- Greeting function
- Basic arithmetic
EOF
git add -A
git commit -m "Update README with features"

# Go back to main
git checkout main
