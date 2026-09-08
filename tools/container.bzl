"""Local container push helpers.

Parallel to the upstream `container_push_official` rule in
@com_github_buildbarn_bb_storage//tools:container.bzl, which pushes to
ghcr.io/buildbarn/<component>. This file adds an analogous helper that
pushes to docker.io/igeolise/<component> using a stamped "tt-..." tag.

Use `bazel run --stamp //cmd/bb_browser:bb_browser_container_push_dockerhub`
after a single `docker login docker.io`. The push tool reads credentials
from ~/.docker/config.json.
"""

load("@rules_img//img:load.bzl", "image_load")
load("@rules_img//img:push.bzl", "image_push")

# DockerHub namespace to push images into. Hardcoded here on purpose;
# change in one place if your account ever moves.
_DOCKERHUB_NAMESPACE = "igeolise"

def container_push_dockerhub(name, image, component):
    """Push a multiarch image to docker.io/<namespace>/<component>.

    Args:
        name: target name; convention is "<binary>_container_push_dockerhub".
        image: label of the image (multiarch_go_image output).
        component: image name under the DockerHub namespace, e.g. "buildbarn-browser".
    """
    image_push(
        name = name,
        image = image,
        registry = "docker.io",
        repository = _DOCKERHUB_NAMESPACE + "/" + component,
        tag_file = "//tools:tt_tags",
        # Match the upstream convention: do not build by default;
        # require an explicit `bazel run`.
        tags = ["manual"],
    )

def container_load_local(name, image, component):
    """Load an image into the local container daemon (Docker / Podman / containerd).

    Tags the loaded image as `docker.io/<namespace>/<component>:<stamped>`
    so a subsequent `docker push` ships to the same DockerHub repo and tag
    that `container_push_dockerhub` would have produced. Useful when the
    DockerHub repo does not yet exist and `image_push` fails its
    HEAD-on-manifest probe with 401 — the docker CLI handles
    create-on-first-push more leniently.

    For multi-platform images, pass `--platforms=@com_github_buildbarn_bb_storage//tools/platforms:linux_amd64`
    (or whichever variant) to `bazel run` to pick one platform; otherwise
    `image_load` will try to load every advertised platform.

    Args:
        name: target name; convention is "<binary>_container_load".
        image: label of the image (multiarch_go_image output).
        component: image name under the DockerHub namespace, must match
            the value used for the corresponding push target.
    """
    image_load(
        name = name,
        image = image,
        # STABLE_BUILD_SCM_* (stable-status) so a rebase invalidates the
        # cached tag; see the matching note in tools/BUILD.bazel.
        tag = "docker.io/" + _DOCKERHUB_NAMESPACE + "/" + component + ":tt-{{.STABLE_BUILD_SCM_TIMESTAMP}}-{{.STABLE_BUILD_SCM_REVISION}}",
        tags = ["manual"],
    )
