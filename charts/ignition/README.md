# Boinc

## Helm
Helm chart is used as follows:

    helm install ignition juniorfoo/ignition

## Building a new docker image
Update the version in `build/Dockerfile` and update the version 
(`inductiveautomation/ignition:8.1.28`). When done, run the following commands:

    docker login
    cd $(git rev-parse --show-toplevel)/charts/ignition/build
    docker buildx build --platform linux/amd64,linux/arm64 -t <user>/ignition:latest -t <user>/ignition:8.1.28 --push .
    cd $(git rev-parse --show-toplevel)
