FROM redhat/ubi9-init

ARG RUNNER_VERSION=v12.1.0

RUN --mount=type=bind,target=/src,Z \
    /bin/bash -euo pipefail /src/scripts/imaging.sh

ENV ENABLE_FORGEJO_RUNNER=1 \
    FORGEJO_URL= \
    FORGEJO_RUNNER_NAME= \
    FORGEJO_RUNNER_LABELS=ubi9:host

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/sbin/init"]
