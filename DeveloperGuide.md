# kron-aapm-charts


### Updating Current Charts
1. Package charts
```shell
  helm package charts/aapm-agent
  helm package charts/aapm-service
  helm package charts/aapm-sidecar
```
2. Move packages to /docs folder
```shell
  mv kron-aapm-agent-1.1.1.tgz docs
  mv kron-aapm-service-0.1.0.tgz docs
  mv kron-aapm-sidecar-1.1.0.tgz docs 
```
3. Create index
```shell
cd docs
helm repo index . --url https://krontechnology.github.io/kron-aapm-charts/
```

### Adding New Chart
1. Create a folder at ./charts directory
2. Follow update steps for new chart
