#!/bin/sh -e

# Upstream's ghcr.io push (container_push_official ->
# @com_github_buildbarn_bb_storage//tools:stamped_tags) substitutes the
# unprefixed names, and upstream only stamps in CI. Left as-is.
if test "${GITHUB_ACTIONS}" = "true"; then
  echo "BUILD_SCM_REVISION $(git rev-parse --short HEAD)"
  echo "BUILD_SCM_TIMESTAMP $(TZ=UTC date --date "@$(git show -s --format=%ct HEAD)" +%Y%m%dT%H%M%SZ)"
fi

# Fork-only: the stamp variables consumed by the image tag template under
# tools/. Not gated on GITHUB_ACTIONS, so a local --stamp build produces a
# git-derived tag too.
#
# STABLE_ puts these in stable-status.txt: Bazel invalidates action cache
# entries when stable-status changes but not when volatile-status does, so a
# consumer that must react to a new HEAD has to read the prefixed names.
echo "STABLE_BUILD_SCM_REVISION $(git rev-parse --short HEAD)"
echo "STABLE_BUILD_SCM_TIMESTAMP $(TZ=UTC date --date "@$(git show -s --format=%ct HEAD)" +%Y%m%dT%H%M%SZ)"
