______________________________________________________________________

## name: ci-triage description: 'Triage failing CI checks in this repository. Use when a workflow fails, when diagnosing pre-commit or Dockerized test failures, and when identifying root cause plus minimal fix.' argument-hint: 'Failure context or workflow name' user-invocable: true

# CI Triage

## When to Use

- A GitHub Actions job fails and root cause is unclear.
- A pre-commit hook fails in CI but passes locally.
- The Dockerized smoke test suite exits non-zero.

## Procedure

1. Identify failing workflow and job from `.github/workflows/`.
1. Map job command to source entrypoint in `Makefile` and `test/run-tests.sh`.
1. Reproduce the failing command locally when tools are available.
1. Isolate the first failing check and confirm exact file and rule.
1. Propose the smallest deterministic fix that preserves strict CI behavior.
1. Re-run relevant checks and report pass/fail with next steps.

## Repository Targets

- Pre-commit workflow: `.github/workflows/pre-commit.yml`
- Test workflow: `.github/workflows/ci-test.yml`
- Build/push workflow: `.github/workflows/build-and-push.yml`
- Smoke test script: `test/run-tests.sh`
- Lint and orchestration targets: `Makefile`

## Output Contract

- Root cause in one sentence.
- Exact failing file and command.
- Minimal fix with rationale.
- Verification command list and current status.
