---
name: tooling-workflow
description: The verification toolchain for latex-infrastructure and the gotchas around it. Use when running the quality gates, adding a hook or formatter plugin, editing the Makefile, Dockerfile stages or compose files, working in the maintainer DevContainer, or drafting a commit message. Documents the Makefile as the single entrypoint, the hadolint/mdformat/pre-commit gates, the Dockerized smoke suite, and which tool owns which file type.
---

# Tooling workflow

`make help` lists every target with its one-line purpose; the [Makefile](../../../Makefile) is the single entrypoint for humans, agents and CI. Leftover-ci is `make lint`, `make check-docs`, `make pre-commit` ([`leftover-ci`](../leftover-ci/SKILL.md)).

## 1. Gates

| Gate               | Command                                | Runs                                                                                                                                                                        | Needs                                          |
| ------------------ | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Dockerfile lint    | `make lint`                            | `hadolint --config .hadolint.yaml Dockerfile` (falls back to the `hadolint/hadolint` image)                                                                                 | hadolint or Docker                             |
| Markdown format    | `make check-docs` / `make format-docs` | `mdformat` over tracked `*.md`                                                                                                                                              | the `/opt/docs-tools` venv in the DevContainer |
| Hook set           | `make pre-commit`                      | Every hook in [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml) across the tree                                                                                 | `pre-commit`                                   |
| Smoke suite        | `make ci-test`                         | Builds the `test` stage and runs [`test/run-tests.sh`](../../../test/run-tests.sh): hadolint, tool versions, pdflatex/lualatex/minted compiles, chktex, latexindent, pandoc | Docker daemon                                  |
| DevContainer build | `make build-dev`                       | Builds the `dev` stage via compose                                                                                                                                          | Docker daemon                                  |
| TeX lint           | `make lint-tex`                        | `chktex` on the fixtures                                                                                                                                                    | TeX Live                                       |

CI mirrors these: [`pre-commit.yml`](../../../.github/workflows/pre-commit.yml) runs the hook set; [`ci-test.yml`](../../../.github/workflows/ci-test.yml) builds `prod`, `test` and `dev` and runs the smoke suite; [`build-and-push.yml`](../../../.github/workflows/build-and-push.yml) publishes `prod` from `main`, `dev` and `v*.*.*` tags only. Pull requests never publish. Public workflows stay on `ubuntu-latest`.

## 2. Formatter ownership

| File type                   | Owner                                                                     | Notes                                                                                                                                                                                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `*.md`                      | `mdformat` with `mdformat-gfm`, `mdformat-tables`, `mdformat-frontmatter` | Plugins are pinned in `.pre-commit-config.yaml` and installed into `/opt/docs-tools` by the Dockerfile — change both together. Without `mdformat-frontmatter`, `---` frontmatter becomes a thematic break and every skill stops being discoverable. `trailing-whitespace` skips Markdown on purpose. |
| `Dockerfile`                | hadolint (lint only)                                                      | Suppress a rule inline with `# hadolint ignore=DLxxxx` and a reason; `.hadolint.yaml` holds only repo-wide decisions.                                                                                                                                                                                |
| `*.sh`                      | shellcheck                                                                | The zsh profile under `.devcontainer/zsh/` is excluded.                                                                                                                                                                                                                                              |
| `*.yaml`, `*.json`          | `check-yaml` / `check-json`                                               | `.vscode/` and `devcontainer.json` are JSONC and excluded from `check-json`.                                                                                                                                                                                                                         |
| Line endings, final newline | `.editorconfig` + `end-of-file-fixer` / `mixed-line-ending`               | LF everywhere.                                                                                                                                                                                                                                                                                       |

## 3. DevContainer

The maintainer container is the `dev` stage, built by compose from [`.devcontainer/docker-compose.yaml`](../../../.devcontainer/docker-compose.yaml) with the host Docker socket mounted, so `make ci-test` and `make build-dev` work from inside it. `postCreateCommand` runs `make setup` (installs the pre-commit hook) and pre-warms hook environments. Commit from inside the container: the generated hook references the container's `pre-commit`. Consumers never use this stage — they pull `prod` from GHCR ([README](../../../README.md#using-the-image-in-another-repository)).

## 4. Pins

Every `FROM` / `COPY --from` is `image:tag@sha256:…`; Dependabot groups the bumps ([README](../../../README.md#image-pins-and-the-texlive_image-build-argument)). Tool versions live in the Dockerfile, `.pre-commit-config.yaml` and the workflows — link those files rather than quoting a number in prose (`docs-code-alignment`).

## 5. Commits

Conventional commits, one concern per commit, heredoc body explaining why. No commit-msg hook enforces this here; the pre-commit hook enforces the file gates. Never `--no-verify` ([`engineering-discipline`](../engineering-discipline/SKILL.md) §10).

## 6. First thing to try when…

| Symptom                                                             | Try                                                                                                                                      |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| A skill or agent file's `---` turned into `______` and `## name: …` | `mdformat` ran without `mdformat-frontmatter`; restore the frontmatter by hand, then `make format-docs` with the pinned plugins.         |
| `make check-docs` fails in CI but the file looks formatted          | Local `mdformat` lacks a plugin CI has (or vice versa); compare `.pre-commit-config.yaml` with `/opt/docs-tools/bin/pip list`.           |
| hadolint flags a line you must keep                                 | Inline `# hadolint ignore=DLxxxx` on the line before, with the reason in the comment.                                                    |
| `make ci-test` fails at `apt-get update`                            | Mirror outage or blocked egress; the build fails closed on purpose — retry, do not weaken `--error-on=any`.                              |
| A new `prod` tool is missing at runtime                             | Add it to `base`, not `dev`; add a version check to `test/run-tests.sh`.                                                                 |
| The DevContainer cannot reach Docker                                | Compose mounts `/var/run/docker.sock` to `docker-host.sock` and `docker-init.sh` bridges it; check the compose file, not the Dockerfile. |
