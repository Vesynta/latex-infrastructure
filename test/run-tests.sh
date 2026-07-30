#!/usr/bin/env bash
#
# Smoke test for the latex-infrastructure image. Runs inside the `test` stage
# (see Dockerfile) and fails on the first error so CI surfaces problems clearly.
#
# The repo is mounted read-only at /work (for hadolint to lint the real
# Dockerfile/.hadolint.yaml); the fixtures live at /opt/test. Compiles run in a
# writable temp dir so aux/output files have somewhere to go.
set -euo pipefail

FIXTURES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK_DIR:-/work}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cp "$FIXTURES"/*.tex "$FIXTURES"/*.md "$WORKDIR"/
cd "$WORKDIR"

step() { printf '\n=== %s ===\n' "$1"; }

step "hadolint: lint the Dockerfile"
HADOLINT_CONFIG="$WORK/.hadolint.yaml"
HADOLINT_DOCKERFILE="$WORK/Dockerfile"
if [[ ! -f "$HADOLINT_CONFIG" || ! -f "$HADOLINT_DOCKERFILE" ]]; then
	HADOLINT_CONFIG="/opt/test/.hadolint.yaml"
	HADOLINT_DOCKERFILE="/opt/test/Dockerfile"
fi
hadolint --config "$HADOLINT_CONFIG" "$HADOLINT_DOCKERFILE"

step "tooling versions"
tlmgr --version
pdflatex --version
pandoc --version
node --version
npm --version

step "pdflatex compile (latexmk -pdf)"
latexmk -pdf -interaction=nonstopmode -halt-on-error sample.tex

step "lualatex compile (latexmk -lualatex, exercises fontspec/font cache)"
latexmk -lualatex -interaction=nonstopmode -halt-on-error sample.tex

step "chktex linter"
CHKTEX_CONFIG="$WORK/.chktexrc"
if [[ ! -f "$CHKTEX_CONFIG" ]]; then
	CHKTEX_CONFIG="/opt/test/.chktexrc"
fi
chktex -l "$CHKTEX_CONFIG" sample.tex

step "latexindent (exercises the Perl deps)"
latexindent sample.tex >/dev/null

step "pygmentize + minted compile (-shell-escape)"
pygmentize -V
latexmk -pdf -shell-escape -interaction=nonstopmode -halt-on-error minted.tex

step "pandoc Word (docx) export"
pandoc sample.md -o "$WORKDIR/out.docx"
test -s "$WORKDIR/out.docx"

step "all checks passed"
