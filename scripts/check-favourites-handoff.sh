#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TASK_ROOT"
TASK_CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wb-favourites-checks.XXXXXX")"
trap 'rm -rf "$TASK_CHECK_DIR"' EXIT
TASK_CACHE="$TASK_CHECK_DIR/module-cache"
run_check() {
  local task_name="$1"
  shift
  swiftc -module-cache-path "$TASK_CACHE" "$@" "scripts/check-$task_name.swift" -o "$TASK_CHECK_DIR/$task_name"
  "$TASK_CHECK_DIR/$task_name"
}
run_check favourites-feed WBSandbox/Model/PaymentsFeedPolicy.swift
run_check favourite-amount WBSandbox/Model/Money.swift WBSandbox/Model/FavouriteAmountDraft.swift
run_check favourites-editing WBSandbox/Model/FavouritesRemoval.swift WBSandbox/Model/SavedUtilityDetails.swift
run_check favourites-insertion WBSandbox/Model/FavouritesInsertion.swift
run_check favourites-deck WBSandbox/Model/FavouritesDeckInteraction.swift
run_check favourites-reminder WBSandbox/Model/FavouritesReminderGeometry.swift
run_check transaction-amount WBSandbox/Model/Money.swift
swiftc -module-cache-path "$TASK_CACHE" \
  WBSandbox/Design/SandboxMotion.swift \
  WBSandbox/Model/FavouritesInsertion.swift \
  WBSandbox/Model/FavouritesReminderGeometry.swift \
  WBSandbox/Model/FavouritesDeckInteraction.swift \
  scripts/export-favourites-motion.swift -o "$TASK_CHECK_DIR/export-motion"
"$TASK_CHECK_DIR/export-motion" "$TASK_CHECK_DIR/motion-reference.json"
cmp docs/favourites/motion-reference.json "$TASK_CHECK_DIR/motion-reference.json"
python3 scripts/check-favourites-docs.py
