# Images for Codefresh Onpremises installation

- `pre-release/*` folder contains images lists for each dev onprem chart
- `releases/*` folder contains images lists for each prod onprem chart

## Getting images list of an on-prem release

To get a simple image list (without image digests) of a lates on-prem release, use the following command:

```
./get-img-list.sh
```
For a specific on-prem helm repo and release version use:

```
./get-img-list.sh --repo prod --version 1.0.151
```
If you need image list along with their repo digests, you will require a proper GCR service account file to be able to access the private images:

```
./get-img-list.sh --repo prod --version 1.0.151 --show-digests --gcr-sa ./sa.json
```

## Push images from Codefresh Enterprise and public repos to private repo
Use Case: install in non-internet environments for private repo

### Prerequesites:
setup docker and `docker login to both source and destination registries`

to login with obtained Google Service Accounbt for Codefresh Enterprise registery:
```
docker login -u _json_key -p "$(cat sa.json)" https://gcr.io
```

### Push required images from Codefresh and public registry to private
```
push-to-registry.sh <private-registry-addr> <release-name>
```

Example:
```
push-to-registry.sh os-registry.cf-cd.com:5000 v1.0.90
```
