#!/bin/sh -e
#
# Fork-only: build and push the bb_browser image to DockerHub under the
# tt-<UTC>-<sha> tag.
#
# Requires a prior `docker login docker.io`; the push tool reads
# credentials from ~/.docker/config.json.
#
# Prints two lines after the bazel chatter:
#   <docker.io ref>@sha256:<digest>
#   <docker.io ref>:<tag>
#
# Pass --load to load locally into docker instead of pushing
# (e.g. for a smoke test before the real push).

mode=push
case "$1" in
  --load) mode=load ;;
  --push|"") mode=push ;;
  *) echo "usage: $0 [--push|--load]" >&2; exit 2 ;;
esac

if test "$mode" = load; then
  suffix=container_load
  # image_load cannot pick a variant out of a multi-platform index.
  set -- --platforms=@com_github_buildbarn_bb_storage//tools/platforms:linux_amd64
else
  suffix=container_push_dockerhub
  set --
fi

# bazel run output is noisy; tee just the docker.io lines to stdout
# while keeping the full log on stderr for diagnostics.
run() {
  target=$1
  shift
  echo ">>> $target ($mode)" >&2
  bazel run --stamp "$@" "$target" 2>&1 | tee /dev/stderr | grep '^docker.io' || true
}

run "//cmd/bb_browser:bb_browser_${suffix}" "$@"
