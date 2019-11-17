# Images for Codefresh Onpremises intallations

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