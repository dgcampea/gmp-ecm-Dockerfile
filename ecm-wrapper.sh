#!/bin/env sh

set -u

if echo "$0" | grep -q 'gwnum' ; then
        readonly EXTRA_CONTAINER_FLAGS='--entrypoint /app/bin/gwnum-ecm'
fi

readonly CONTAINER_ID_DIR=$(mktemp -d -t container-ecm-XXXXX)

start_container()
{
        podman run --read-only --rm --cap-drop=all --network=none \
                -i --cidfile "${CONTAINER_ID_DIR}"/gmp-ecm.ctr-id \
                -v "$PWD":/host:noexec,nodev,nosuid,z \
                ${EXTRA_CONTAINER_FLAGS:-} \
                localhost/gmp-ecm:${ECM_TAG:-latest} "$@"
}

stop_container()
{
        echo "Stopping container..."
        trap abort INT
        nohup podman stop --ignore --cidfile "${CONTAINER_ID_DIR}"/gmp-ecm.ctr-id >/dev/null 2>&1 &
        PID=$!
}

cleanup()
{
        [ -n "${PID+x}" ] && wait "${PID}"
        rm -rf "${CONTAINER_ID_DIR}"
}

abort()
{
        echo "Aborted."
        exit 255
}

trap stop_container TERM INT QUIT HUP

start_container "$@"
EXIT_CODE=$?
cleanup
exit "${EXIT_CODE}"
