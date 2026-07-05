#!/bin/bash
#
# Remove a git worktree
#
# Usage: ./scripts/remove-worktree.sh <feature-name>
#

set -e

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 <feature-name>"
  echo ""
  echo "Current worktrees:"
  git worktree list
  exit 1
fi

BRANCH_NAME="$FEATURE_NAME"
MAIN_DIR=$(cd "$(dirname "$0")/.." && pwd)
PARENT_DIR=$(dirname "$MAIN_DIR")
WORKTREE_DIR="$PARENT_DIR/playwright-elixir-$FEATURE_NAME"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "Error: Worktree not found at $WORKTREE_DIR"
  echo ""
  echo "Current worktrees:"
  git worktree list
  exit 1
fi

echo "Removing worktree: $WORKTREE_DIR"
echo ""

# Remove the worktree
git worktree remove "$WORKTREE_DIR"

echo "==> Worktree removed"
echo ""
echo "Note: Branch '$BRANCH_NAME' still exists. To delete it:"
echo "  git branch -d $BRANCH_NAME"
