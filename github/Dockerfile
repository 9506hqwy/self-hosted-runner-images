FROM redhat/ubi9-init:9.5

ARG RUNNER_VERSION=2.323.0
ARG RUNNER_HASH=0dbc9bf5a58620fc52cb6cc0448abcca964a8d74b5f39773b7afcad9ab691e19

RUN --mount=type=bind,target=/src,Z \
    /bin/bash -euo pipefail /src/scripts/imaging.sh

ENV ENABLE_GITHUB_RUNNER=1 \
    GITHUB_ORG_URL= \
    GITHUB_RUNNER_NAME= \
    GITHUB_RUNNER_LABELS=ubi9

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/sbin/init"]
