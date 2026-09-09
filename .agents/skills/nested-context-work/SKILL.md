______________________________________________________________________

## name: nested-context-work description: Work on gitignored sibling clones under .agents/context/ from a host DevContainer. Use when editing, testing, or committing another Vesynta repo that is cloned into .agents/context/; when leftover-ci or hooks fail because pnpm/make/pre-commit are missing on the host PATH; when the Docker daemon is tight on disk; or when a nested clone leaked .pnpm-store/ onto the workspace root. Load the clone’s own skills; run that repo’s Makefile and git hooks via a one-shot compose run into its DooD image. Never join local-stack plane networks for leftover-ci.

# Nested context work

Related Vesynta repos are cloned into [`.agents/context/`](../../context/) for agentic turns. That directory is **gitignored** in the host. Each clone is its own git repository with its own skills, Makefile, and DevContainer.

This skill is the behaviour for **host vs clone**. Pair with [`engineering-discipline`](../engineering-discipline/SKILL.md) (surgical diffs, ask-don’t-assume). Do not restate [AGENTS.md](../../../AGENTS.md) hard rules.

This is **not** a QMS document. Do not write clinical-validation prose.

## 1. Detect the git root

```bash
git -C <path> rev-parse --show-toplevel
```

If that root is **not** this repository’s git root, the files belong to a nested clone. **Stop** applying this repository’s leftover-ci, domain skills, and host `PATH` to that tree.

Host leftover-ci still applies to **host** files in the same turn.

## 2. Load the clone’s skills

Read, in order:

1. The clone’s `AGENTS.md` (or `CLAUDE.md` / `.github/copilot-instructions.md` if that is all it has).
1. The clone’s [`.agents/skills/README.md`](../README.md) catalog when present.
1. The clone skills that match the task (`engineering-discipline`, `tooling-workflow`, `leftover-ci`, plus **one** domain skill).

Do not copy this repository’s domain skills into the clone. Do not treat the clone’s files as part of this git index (`git add .agents/context/<clone>` from `/app` is always wrong).

## 3. Leftover-ci in the clone’s image

The clone’s hooks expect **that** image (pnpm, uv, Django, LaTeX, …). This host image does not provide them. Baked Docker-outside-of-Docker on the host is how you reach the clone image.

**Derive** compose file, service, `workspaceFolder`, and `remoteUser` from the clone’s `.devcontainer/devcontainer.json`. Do not trust a remembered table.

Leftover-ci, `git commit`, and `git push` are a **one-shot** `compose run --rm --no-deps` (or `docker run --rm` of that `dev` image). Do **not** `compose up -d` a second app replica. Do **not** run the clone’s `initializeCommand` (clinical-frontend’s stops local-stack `frontend`/`render` on `clinical-net`).

### DooD host-path bind

When **this host is itself a DevContainer**, compose bind mounts such as `.:/app` are resolved by the **daemon on the laptop**, not by this container. `./` inside `/app/.agents/context/<clone>` does not exist on the host, so the nested service starts with an empty workdir.

Rewrite those binds to the clone’s **host** path (from `docker inspect` of this container’s workspace mount, plus `.agents/context/<clone>`). Distinct compose project name (`-p nested-ctx-<clone>`) so you do not attach to a laptop checkout of the same repo.

Do not attach an empty named `node_modules` volume over the clone; bind the host clone only.

```bash
host_ws=$(docker inspect "$(hostname)" --format '{{range .Mounts}}{{if eq .Destination "/app"}}{{.Source}}{{end}}{{end}}')
host_clone=$host_ws/.agents/context/<clone>
compose=<clone>/.devcontainer/docker-compose.yaml   # or whatever dockerComposeFile says
service=<service>
user=<remoteUser>
workdir=<workspaceFolder>

docker compose -p nested-ctx-<clone> -f "$compose" run --rm --no-deps \
  --volume "$host_clone:$workdir" \
  --workdir "$workdir" \
  --user "$user" \
  --entrypoint bash \
  "$service" -c '<clone leftover-ci>'
```

If `dockerComposeFile` is a list, pass every file in order (`-f` repeated). Equivalent: `docker run --rm --entrypoint bash -u "$user" -w "$workdir" -v "$host_clone:$workdir" <clone-dev-image> -c '…'`.

Do not `docker exec` an already-running sibling named `*_devcontainer-*` unless you have confirmed its bind mount is **this** context clone. A laptop checkout of the same repo is a different tree.

### Local-stack isolation

Leftover-ci follows local-stack CI isolation:

- Project `nested-ctx-<clone>`, never the local-stack compose project names.
- Do **not** attach `clinical-net` or `community-net`.
- Do **not** publish 40xxx/50xxx.
- Do **not** set `com.vesynta.stack=local`.

Hooks that need a live API are out of scope unless the human’s local-stack is already up; leftover-ci still stays off-net.

### Observer (inspect only)

If the plane network **already exists**, a throwaway client may join it to inspect in-network URLs. Never start a second `frontend`/`backend`. Never set `stack=local`. If the network is missing, **skip** — do not create `clinical-net` / `community-net` for leftover-ci.

<!-- cspell:ignore curlimages -->

```bash
docker network inspect clinical-net >/dev/null 2>&1 || exit 0
docker run --rm --network clinical-net curlimages/curl:8.15.0 \
  curl -sfS http://backend:8000/
# engine origin: http://engine:46846
```

Use `community-net` and `http://frontend:3000` the same way when that plane is up.

### Example coordinates (verify before use)

| Clone                                 | Compose                                                            | Service                   | Workdir              |
| ------------------------------------- | ------------------------------------------------------------------ | ------------------------- | -------------------- |
| community-frontend                    | `.devcontainer/docker-compose.yaml`                                | `app`                     | `/app`               |
| clinical-frontend                     | `.devcontainer/docker-compose.yaml`                                | `frontend`                | `/app`               |
| pharmacometrics-engine                | `.devcontainer/docker-compose.yaml`                                | `engine`                  | `/app`               |
| clinical-backend                      | `docker-compose.yml` + `.devcontainer/docker-compose.override.yml` | `backend`                 | `/code`              |
| website                               | `docker-compose.dev.yaml`                                          | `website`                 | `/repo`              |
| clinical-docs                         | `compose.yaml`                                                     | `docs`                    | `/app`               |
| design-control-matrix                 | `.devcontainer/docker-compose.yaml`                                | `development_environment` | `/repo`              |
| organisation-matrix                   | `.devcontainer/docker-compose.yaml`                                | `development_environment` | `/repo`              |
| latex-infrastructure                  | `.devcontainer/docker-compose.yaml`                                | `devcontainer`            | `/workspaces/<name>` |
| infrastructure (when it is the clone) | `compose.yaml`                                                     | `infrastructure`          | `/app`               |

Ask (`AskQuestion`) before starting a sibling image you are not already using, or if `remoteUser` / service is missing from `devcontainer.json`.

## 4. Package managers and caches

Never run the clone’s `pnpm`, `npm`, `uv`, or `pre-commit` on the **host** PATH. Relative `store-dir=.pnpm-store` then lands at the host workspace root and shows up as tens of thousands of untracked files.

The clone’s leftover-ci is whatever **that** repo documents (`make check`, husky, `pre-commit`, …). Do not invent a `make check` target. If there is no aggregate, ask.

## 5. Safe Docker prune

When the daemon hits disk quota (`disk quota exceeded`, extract/layer write failures), free **unused images and build cache**. Check `docker ps` first. Do not stop running stacks. Do not prune while a leftover-ci **run** still needs its image.

If this clone has `make docker-prune-safe`, use it. Otherwise:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker container prune -f
docker image prune -f
docker image prune -a -f
docker builder prune -f
```

Never `docker volume prune`, `docker system prune --volumes`, or `docker compose down -v`. Named volumes (Postgres, `node_modules`) outlive images on purpose.

## 6. Anti-patterns

- `git commit` / `git push` in a nested clone from this container’s own shell.
- Host leftover-ci as the done gate for product-repo edits.
- `git commit --no-verify` because the host lacks `pnpm`.
- Copying host skills into `.cursor/skills` or duplicating them under the clone’s `.claude/skills` (that path must be a **symlink** to `.agents/skills`).
- Adding `.agents/context/` clones as git submodules.
- Joining `clinical-net` / `community-net` for leftover-ci or publishing plane ports on `nested-ctx-*`.
- `docker volume prune` / `--volumes` to recover disk.

## 7. Ask, don’t assume

Use `AskQuestion` when the human must choose: which clone is source of truth, whether to rebuild its image, commit subject / PR target, or which verification gate exists. A wrong assumption that skips hooks costs more than asking.
