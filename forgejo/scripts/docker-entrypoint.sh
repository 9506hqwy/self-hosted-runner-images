#!/bin/bash

if [[ -z $FORGEJO_URL ]]; then
    exit 1
fi

if [[ -z $FORGEJO_RUNNER_NAME ]]; then
    exit 1
fi

if [[ -z $FORGEJO_RUNNER_LABELS ]]; then
    exit 1
fi

FORGEJO_SECRET_PATH=/run/secrets/forgejo_token
FORGEJO_TOKEN=$(cat "${FORGEJO_SECRET_PATH}")
echo unknown > "${FORGEJO_SECRET_PATH}"
if [[ -z $FORGEJO_TOKEN ]]; then
    exit 1
fi

if [[ $ENABLE_FORGEJO_RUNNER -ne 0 ]]; then
    pushd /home/runner || exit 1

    if [[ -f /forgejo_runner/"${FORGEJO_RUNNER_NAME}" ]]; then
        cp /forgejo_runner/"${FORGEJO_RUNNER_NAME}" .runner
        chown runner .runner
    else
        sudo -u runner /usr/local/bin/forgejo-runner register \
            --instance "${FORGEJO_URL}" \
            --labels "${FORGEJO_RUNNER_LABELS}" \
            --name "${FORGEJO_RUNNER_NAME}" \
            --no-interactive \
            --token "${FORGEJO_TOKEN}" || exit 1
        cp .runner /forgejo_runner/"${FORGEJO_RUNNER_NAME}"
    fi

    (
        sleep 1; # run after exec.
        while ! sudo -u runner /usr/local/bin/forgejo-runner one-job 2> /dev/null
        do
            sleep 3
        done

        kill -37 1;
    ) &

    popd || exit 1
fi

unset FORGEJO_URL
unset FORGEJO_TOKEN
unset FORGEJO_RUNNER_NAME
unset FORGEJO_RUNNER_LABELS

exec "$@"
