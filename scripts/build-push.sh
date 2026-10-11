#!/usr/bin/env bash
# Build RoboShop images with an immutable git-SHA tag and push them to ECR; print the digests.
# Usage: scripts/build-push.sh all | <image> [<image>...]   (image names: web catalogue user cart shipping payment ratings dispatch mongodb mysql)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ALL="web catalogue user cart shipping payment ratings dispatch mongodb mysql"
declare -A DIR=([mongodb]=mongo)                  # image name → folder, when they differ
REGION=${AWS_REGION:-us-east-1}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REG="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Uncommitted changes. Commit first — the tag must point at a real commit." >&2; exit 1
fi
SHA=$(git rev-parse --short=7 HEAD)
VERSION=$(git describe --tags --always)

[ "${1:-}" = "all" ] && set -- $ALL
[ $# -gt 0 ] || { echo "usage: $0 all | <image>..." >&2; exit 1; }

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REG" >/dev/null
mkdir -p build && : > build/digests.txt

for svc in "$@"; do
  dir=${DIR[$svc]:-$svc}
  img="$REG/roboshop/$svc:$SHA"
  if aws ecr describe-images --repository-name "roboshop/$svc" --image-ids imageTag="$SHA" >/dev/null 2>&1; then
    echo "⏭  roboshop/$svc:$SHA already in ECR (immutable) — skipping build"
  else
    echo "🔨 building $svc from ./$dir"
    docker build --pull --build-arg GIT_SHA="$SHA" --build-arg VERSION="$VERSION" \
      -t "$img" -t "roboshop/$svc:dev" "./$dir"
    docker push "$img" >/dev/null
  fi
  digest=$(aws ecr describe-images --repository-name "roboshop/$svc" --image-ids imageTag="$SHA" \
           --query 'imageDetails[0].imageDigest' --output text)
  echo "$svc $SHA $REG/roboshop/$svc@$digest" | tee -a build/digests.txt
done
echo "✅ digests written to build/digests.txt"
