#!/bin/bash
#
# Create a git worktree with proper setup for playwright-elixir development
#
# Usage: ./scripts/create-worktree.sh <feature-name>
#
# Example:
#   ./scripts/create-worktree.sh frame-locator
#   ./scripts/create-worktree.sh api-v2
#

set -e

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 <feature-name>"
  echo ""
  echo "Examples:"
  echo "  $0 frame-locator"
  echo "  $0 api-v2"
  echo ""
  echo "This will create:"
  echo "  - Branch: <feature-name>"
  echo "  - Directory: ../playwright-elixir-<feature-name>"
  exit 1
fi

# Derive branch and directory names from feature name
BRANCH_NAME="$FEATURE_NAME"

# Get the directory where the main repo is
MAIN_DIR=$(cd "$(dirname "$0")/.." && pwd)
PARENT_DIR=$(dirname "$MAIN_DIR")
WORKTREE_DIR="$PARENT_DIR/playwright-elixir-$FEATURE_NAME"

echo "Creating worktree for branch: $BRANCH_NAME"
echo "  Location: $WORKTREE_DIR"
echo ""

# Check if worktree already exists
if [ -d "$WORKTREE_DIR" ]; then
  echo "Error: Directory $WORKTREE_DIR already exists"
  exit 1
fi

# Create the worktree
echo "==> Creating git worktree..."
git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME" 2>/dev/null || \
git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"

cd "$WORKTREE_DIR"

# Trust mise configuration
echo "==> Trusting mise configuration..."
mise trust

# Copy commit-msg hook
echo "==> Copying commit-msg hook..."
if [ -f "$MAIN_DIR/.git/hooks/commit-msg" ]; then
  cp "$MAIN_DIR/.git/hooks/commit-msg" "$WORKTREE_DIR/.git/hooks/commit-msg"
  chmod +x "$WORKTREE_DIR/.git/hooks/commit-msg"
  echo "   Copied commit-msg hook"
fi

# Copy .claude directory
echo "==> Copying .claude directory..."
if [ -d "$MAIN_DIR/.claude" ]; then
  cp -r "$MAIN_DIR/.claude" "$WORKTREE_DIR/.claude"
  echo "   Copied .claude directory"
fi

# Install Elixir dependencies
echo "==> Installing Elixir dependencies..."
mix deps.get

echo ""
echo "==> Worktree ready!"
echo ""
echo "To start working:"
echo "  cd $WORKTREE_DIR"
echo "  mix test"
echo ""
echo "Or run Claude Code in the new worktree:"
echo "  cd $WORKTREE_DIR && claude"
