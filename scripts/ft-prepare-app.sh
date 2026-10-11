#!/usr/bin/env bash
# fast-track kit: turns roboshop-app (our additions only) into a buildable repo in one go.
# Run ON THE WORKSTATION, once, inside ~/work/roboshop-app (needs docker, git, python3).
# Idempotent: safe to re-run. Every change below is one the guide makes by hand on a specific day:
#   Day 3   import instana/robot-shop at a PINNED commit (Apache-2.0, attribution kept)
#   Day 12  cart: CATALOGUE_PORT env var            Day 14  payment: CART_PORT/USER_PORT env vars
#   Day 24  lockfiles (npm ci needs them)            Day 27  payment.ini: drop uid/gid; dispatch: go.mod/go.sum
#   Day 28  web nginx template: no Instana tracer, ratings on :8080
#   Day 54  payment + dispatch read AMQP_USER/AMQP_PASS (RabbitMQ creds from SSM via ESO)
#   Day 24+ pin every base image by digest (resolved now, written into the Dockerfiles)
# Plus one decision the guide leaves to you (Day 24 "watch out"): the 2020 Instana vendor tracer is removed
# from all services, because it breaks on Node 22 / Python 3.12 / current Go. Phase 8 adds OpenTelemetry instead.
set -euo pipefail
UPSTREAM_REPO=https://github.com/instana/robot-shop.git
UPSTREAM_SHA=${UPSTREAM_SHA:-55292e2}          # last upstream commit (2023-03-06); change deliberately
cd "$(git rev-parse --show-toplevel)"
say() { printf '\n\033[36m== %s\033[0m\n' "$*"; }

say "1/7 import upstream robot-shop @ $UPSTREAM_SHA (keeps our Dockerfiles, scripts, CI files)"
if [ ! -f catalogue/server.js ]; then
  tmp=$(mktemp -d); git clone -q "$UPSTREAM_REPO" "$tmp/rs"; git -C "$tmp/rs" checkout -q "$UPSTREAM_SHA"
  # --ignore-existing: OUR files (Dockerfiles, README.md, .github ...) win over upstream ones
  rsync -a --ignore-existing --exclude .git --exclude README.md --exclude 'docker-compose*.yaml' "$tmp/rs/" ./
  cp "$tmp/rs/README.md" UPSTREAM-README.md
  for d in web catalogue user cart shipping payment ratings dispatch mongo mysql; do
    cp "$tmp/rs/$d/Dockerfile" "$d/Dockerfile.upstream"      # kept for the before/after comparison (Day 24)
  done
  rm -rf "$tmp"
else
  echo "upstream source already present - skipping import"
fi

say "2/7 source patches (Days 12, 14, 27, 28, 54 + Instana removal)"
python3 "$(dirname "$0")/ft_patch_sources.py"

say "3/7 lockfiles (Day 24/25) - generated inside throwaway containers, nothing installed on the host"
for s in catalogue user cart; do
  [ -f "$s/package-lock.json" ] && { echo "   ok      $s/package-lock.json"; continue; }
  docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$PWD/$s":/app -w /app node:22-bookworm-slim \
    npm install --package-lock-only --ignore-scripts --no-audit --no-fund
  [ -f "$s/.dockerignore" ] || cp catalogue/.dockerignore "$s/.dockerignore"
done
if [ ! -f dispatch/go.sum ]; then
  docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e GOPATH=/tmp/go -e GOCACHE=/tmp/gocache \
    -v "$PWD/dispatch":/src -w /src golang:1.24 sh -c '[ -f go.mod ] || go mod init dispatch; go mod tidy'
else echo "   ok      dispatch/go.sum"; fi

say "4/7 pin every base image by digest (FROM image:tag -> FROM image:tag@sha256:...)"
for f in */Dockerfile; do
  for ref in $(awk '/^FROM /{print $2}' "$f" | sort -u); do
    case "$ref" in *@sha256:*) continue ;; esac
    docker pull -q "$ref" >/dev/null
    dig=$(docker inspect --format '{{index .RepoDigests 0}}' "$ref" | cut -d@ -f2)
    sed -i -E "s#^FROM ${ref}( |\$)#FROM ${ref}@${dig}\1#" "$f"
    echo "   $f: $ref@${dig:0:19}..."
  done
done

say "5/7 hadolint (warnings are OK for the lab; errors are not)"
if command -v hadolint >/dev/null; then
  hadolint --failure-threshold error */Dockerfile && echo "   hadolint: no errors"
else echo "   hadolint not installed - skipped"; fi

say "6/7 build ignore + attribution"
grep -qx 'build/' .gitignore 2>/dev/null || echo 'build/' >> .gitignore
grep -q 'instana/robot-shop' README.md 2>/dev/null || cat >> README.md <<MD

Based on [instana/robot-shop](https://github.com/instana/robot-shop) (Apache-2.0), imported at commit \`$UPSTREAM_SHA\` by scripts/ft-prepare-app.sh.
MD

say "7/7 commit"
git add -A
if git diff --cached --quiet; then echo "nothing to commit"; else
  git commit -q -m "chore(app): import robot-shop @ $UPSTREAM_SHA, source patches, lockfiles, digest-pinned bases (fast-track kit)"
  echo "committed $(git rev-parse --short HEAD)."
  echo "Next (see 01-golden-setup.md step G3): publish this commit to your repo, then: scripts/build-push.sh all"
fi
