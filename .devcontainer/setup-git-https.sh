#!/usr/bin/env bash
# Wire git HTTPS to the persisted gh login. Strip Windows Git Credential
# Manager helpers that Cursor/VS Code copy from a Windows host gitconfig.
# Do not touch --system gitconfig (safe.directory lives there).
# Do not PATH-wrap git. Do not print tokens.
set -euo pipefail

export GIT_TERMINAL_PROMPT="${GIT_TERMINAL_PROMPT:-0}"

if ! command -v git >/dev/null 2>&1; then
	echo "setup-git-https: git is not on PATH" >&2
	exit 1
fi

# One identity: drop every global credential.helper, then re-add gh.
# Leaving helper=manager listed first makes gh-stack treat GCM stderr as fatal
# even when a later gh helper would succeed.
git config --global --unset-all credential.helper 2>/dev/null || true
git config --global --unset-all credential.https://github.com.helper 2>/dev/null || true
git config --global --remove-section credential.helperselector 2>/dev/null || true

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
	gh auth setup-git
fi
