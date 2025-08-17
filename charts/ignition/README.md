# Ignition

## Helm

Helm chart is used as follows:

    helm install ignition juniorfoo/ignition

## Building a new docker image (if you need to)

We use this to preload modules that we have created.

Edit `build/Dockerfile` and update the version (`inductiveautomation/ignition:<new version>`). When done, run the following commands:

    docker login
    cd $(git rev-parse --show-toplevel)/charts/ignition/build
    docker buildx build --platform linux/amd64,linux/arm64 -t <user>/ignition:latest -t <user>/ignition:<new version> --push .
    cd $(git rev-parse --show-toplevel)
