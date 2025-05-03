#!/bin/bash

if [[ -z $GITHUB_ORG_URL ]]; then
    exit 1
fi

if [[ -z $GITHUB_RUNNER_NAME ]]; then
    exit 1
fi

if [[ -z $GITHUB_RUNNER_LABELS ]]; then
    exit 1
fi

GITHUB_SECRET_PATH=/run/secrets/github_token
GITHUB_ORG_TOKEN=$(cat "${GITHUB_SECRET_PATH}")
echo unknown > "${GITHUB_SECRET_PATH}"
if [[ -z $GITHUB_ORG_TOKEN ]]; then
    exit 1
fi

set -eu

if [[ $ENABLE_GITHUB_RUNNER -ne 0 ]]; then
    pushd /opt/actions-runner

    if sudo -u runner ./config.sh \
        --unattended \
        --url "${GITHUB_ORG_URL}" \
        --pat "${GITHUB_ORG_TOKEN}" \
        --name "${GITHUB_RUNNER_NAME}" \
        --labels "${GITHUB_RUNNER_LABELS}" \
        --replace \
        --ephemeral; then
        (
            sleep 1; # run after exec.
            sudo -u runner ./run.sh;
            kill -37 1;
        ) &
    fi

    popd
fi

unset GITHUB_ORG_URL
unset GITHUB_ORG_TOKEN
unset GITHUB_RUNNER_NAME
unset GITHUB_RUNNER_LABELS

exec "$@"
