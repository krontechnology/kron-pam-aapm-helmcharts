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
  mv kron-aapm-agent-*.tgz docs
  mv aapm-service-*.tgz docs
  mv kron-aapm-sidecar-*.tgz docs
```
3. Create index
```shell
helm repo index docs/ --url https://krontechnology.github.io/kron-pam-aapm-helmcharts/
```

### Adding New Chart
1. Create a folder at ./charts directory
2. Follow update steps for new chart
