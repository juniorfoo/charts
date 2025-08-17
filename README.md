# Helm chart repository

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```sh
helm repo add juniorfoo https://juniorfoo.github.io/charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo juniorfoo` to see the charts.

To install the `ignition` chart:

```sh
helm install ignition juniorfoo/ignition
```

To uninstall the chart:

```sh
helm delete ignition
```

## TODO

- [AWS Ignition Quickstart](https://aws-quickstart.github.io/quickstart-inductive-automation-ignition/)
- [HA Items](https://github.com/aws-quickstart/quickstart-inductive-automation-ignition/blob/c5c0a641271d51156e33158d2719098e1d2fa189/scripts/creation_v2.sh#L245)
- [DB Items](https://github.com/aws-quickstart/quickstart-inductive-automation-ignition/blob/c5c0a641271d51156e33158d2719098e1d2fa189/scripts/creation_v2.sh#L223)
