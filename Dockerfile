# syntax=docker/dockerfile:1

# Tag of the upstream texlive/texlive image to pull the TeX Live tree from.
# Overridable at build time (e.g. --build-arg TEX_IMAGE_TAG=latest-medium).
ARG TEX_IMAGE_TAG=latest-full

# Stage 1: a throwaway stage that only exists so we can copy the prebuilt
# TeX Live installation out of the official image.
FROM texlive/texlive:${TEX_IMAGE_TAG} AS texlive-source

# ---------------------------------------------------------------------------
# base: shared TeX Live tree + system deps + pandoc + a quality font set.
# ---------------------------------------------------------------------------
FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base

# The symlink RUN below pipes `ls` into `head`; pipefail makes the build fail
# fast on a broken pipe and keeps hadolint's DL4006 happy.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The Ubuntu base ships /etc/apt/apt.conf.d/docker-clean, which deletes cached
# .debs after install and would defeat the BuildKit cache mounts below. Drop it
# and tell apt to keep downloaded packages so the cache mounts can reuse them.
# Set once here in base; inherited by every downstream stage.
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Bring the full TeX Live tree across from the upstream image, chowning it to
# the vscode user as part of the copy. Doing it here (rather than a separate
# chown -R) avoids rewriting the entire multi-GB tree into a second layer.
COPY --from=texlive-source --chown=vscode:vscode /usr/local/texlive /usr/local/texlive

# TeX Live installs under /usr/local/texlive/<year>/bin/<arch>, both of which
# vary by image tag and platform. ENV cannot run shell substitution, so we
# resolve the real directories once at build time and expose them through
# stable symlinks that the ENV statements below can reference.
RUN set -eux; \
  tldirs=(/usr/local/texlive/20*/); \
  tldir="${tldirs[0]%/}"; \
  [ -d "$tldir" ]; \
  ln -s "$tldir" /usr/local/texlive/current; \
  archbins=(/usr/local/texlive/current/bin/*/); \
  archbin="${archbins[0]%/}"; \
  [ -d "$archbin" ]; \
  ln -s "$archbin" /usr/local/texlive/current-bin

# Make pdflatex, latexmk, tlmgr, man pages, and info docs available.
ENV PATH="/usr/local/texlive/current-bin:${PATH}"
# Trailing colon means "also search the system defaults", and avoids
# referencing the (undefined-in-base) MANPATH/INFOPATH, which BuildKit's
# UndefinedVar linter flags even with the ${VAR:-} default form.
ENV MANPATH="/usr/local/texlive/current/texmf-dist/doc/man:"
ENV INFOPATH="/usr/local/texlive/current/texmf-dist/doc/info:"

# System dependencies:
#   - make/perl/python3: build tooling used by latexmk and friends
#   - python3-pygments: required by the minted package
#   - chktex: LaTeX linter
#   - ghostscript: PDF/PS processing
#   - fontconfig: provides fc-cache (used to register the fonts below)
#   - git-lfs: large-file support for project assets
#   - cpanminus + lib*-perl: runtime deps for latexindent
#   - pandoc: native Word (docx) and other-format export
#   - nodejs/npm: Node-based devcontainer features (e.g. Claude Code)
#   - gh: GitHub CLI for PR review workflows in consumer repos
#   - librsvg2-bin: rsvg-convert for SVG → PDF figure conversion
# Font packages (registered by fc-cache in the prod stage) give pandoc and
# the LaTeX engines broad, high-quality coverage:
#   - fonts-liberation: Arial/Times/Courier metric-compatible (Word classics)
#   - fonts-crosextra-carlito/-caladea: Calibri/Cambria metric-compatible
#   - fonts-dejavu: broad Latin + symbol coverage
#   - fonts-noto-core/-color-emoji: wide Unicode and emoji coverage
#   - lmodern/fonts-texgyre/fonts-freefont-ttf: quality TeX/OpenType families
# Cache mounts let repeat builds reuse the downloaded .debs and apt lists. They
# are excluded from the committed layer, so the image stays lean without an
# explicit apt clean (which is why the old clean/rm tail is gone).
RUN --mount=type=cache,target=/var/cache/apt,sharing=shared,uid=0,gid=0 \
  --mount=type=cache,target=/var/lib/apt,sharing=shared,uid=0,gid=0 \
  export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  make \
  perl \
  python3 \
  python3-pygments \
  chktex \
  ghostscript \
  fontconfig \
  git-lfs \
  cpanminus \
  libyaml-tiny-perl \
  libfile-homedir-perl \
  libunicode-linebreak-perl \
  pandoc \
  nodejs \
  npm \
  gh \
  librsvg2-bin \
  fonts-liberation \
  fonts-crosextra-carlito \
  fonts-crosextra-caladea \
  fonts-dejavu \
  fonts-noto-core \
  fonts-noto-color-emoji \
  lmodern \
  fonts-texgyre \
  fonts-freefont-ttf

# Pre-create the gh config directory owned by vscode so that consumer
# devcontainers mounting a named volume at ~/.config/gh inherit writable
# ownership (Docker initialises empty volumes from the image path's uid/gid).
RUN mkdir -p /home/vscode/.config/gh \
  && chown vscode:vscode /home/vscode/.config/gh

# ---------------------------------------------------------------------------
# prod: the published GHCR image. Just base plus pre-built font caches so the
# first real compilation isn't penalised by cache generation.
# ---------------------------------------------------------------------------
FROM base AS prod
USER vscode
RUN luaotfload-tool -u -v && fc-cache -fv

# ---------------------------------------------------------------------------
# test: prod + the hadolint binary and the test fixtures, run via CMD in CI.
# ---------------------------------------------------------------------------
FROM prod AS test
USER root
COPY --from=hadolint/hadolint:latest /bin/hadolint /usr/local/bin/hadolint
COPY .hadolint.yaml /opt/test/.hadolint.yaml
COPY .chktexrc /opt/test/.chktexrc
COPY Dockerfile /opt/test/Dockerfile
COPY test/ /opt/test/
RUN chmod +x /opt/test/run-tests.sh
USER vscode
CMD ["/opt/test/run-tests.sh"]

# ---------------------------------------------------------------------------
# dev: test + maintainer doc tooling (mdformat, pre-commit). Inherits the
# hadolint binary from the test stage, so the editor extension finds it on
# PATH. CMD is reset so the inherited test command doesn't run.
# ---------------------------------------------------------------------------
FROM test AS dev
USER root
# apt + pip cache mounts; the keep-cache config from base is inherited. pip's
# --no-cache-dir is dropped so the cache mount is actually used.
RUN --mount=type=cache,target=/var/cache/apt,sharing=shared,uid=0,gid=0 \
  --mount=type=cache,target=/var/lib/apt,sharing=shared,uid=0,gid=0 \
  --mount=type=cache,target=/root/.cache/pip,sharing=shared,uid=0,gid=0 \
  export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends python3-venv \
  && python3 -m venv /opt/docs-tools \
  && /opt/docs-tools/bin/pip install \
  mdformat \
  mdformat-gfm \
  mdformat-tables \
  pre-commit \
  && ln -s /opt/docs-tools/bin/mdformat /usr/local/bin/mdformat \
  && ln -s /opt/docs-tools/bin/pre-commit /usr/local/bin/pre-commit
USER vscode
CMD ["sleep", "infinity"]
