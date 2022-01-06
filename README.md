[![cftest](https://github.com/theonestack/hl-component-amp-ecs/actions/workflows/rspec.yaml/badge.svg)](https://github.com/theonestack/hl-component-amp-ecs/actions/workflows/rspec.yaml)

# hl-component-amp-ecs
Provisions a Amazon Managed Service for Prometheus Workspace and AWS OpenTelemetry Collector with the ECS Observer configured


```bash
kurgan add amp-ecs
```

## Requirements

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| VPCId | Security Groups | None | false | AWS::EC2::VPC::Id
| SubnetIds | list of subnets | None | false | CommaDelimitedList
| EcsCluster | ecs cluster to deploy to | None | false | string
| GrafanaAccountId | AWS Account Id for Cross Account Access for Grafana | '' | false | string
| Cpu | Prometheus Export Task CPU | 512 | false | string
| Memory | Prometheus Export Task Memory | 1024 | false | string

## ECS Exporter Configuration

The default configuration uses docker labels for ECS task discovery. Tasks with the following labels with be automatically discovered and have the metrics exported to AMP

`ECS_PROMETHEUS_EXPORTER_PORT` will use the default metrics path of `/metrics`

or

`ECS_PROMETHEUS_EXPORTER_PORT_V2` and `ECS_PROMETHEUS_EXPORTER_METRICS_PATH` which allows setting a custom metrics path

The `aot_ecs_observer` config property can be used to add custom ECS task discovery to the exporter for example

```yaml
aot_ecs_observer:
  services:
  - name_pattern: '^myservice-.*$'
    metrics_path: /mymetrics
    metrics_ports:
    - 8080
```

This will discover any services with myservice in the name and will scrape metrics from the `/mymetrics` path on port `8080`

See [Amazon Elastic Container Service Observer](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/observer/ecsobserver) for full config details

## Usage

Here is an example of using this component to deploy it as a standalone service within an existing VPC and ECS Cluster

```ruby
CfhighlanderTemplate do

  Component template: 'amp-ecs@0.1.0', name: 'ampecs', render: Inline do
    parameter name: 'VPCId', value: FnImportValue(FnSub("${EnvironmentName}-vpc-VPCId"))
    parameter name: 'SubnetIds', value: FnSplit(',', FnImportValue(FnSub("${EnvironmentName}-vpc-ComputeSubnets")))
    parameter name: 'EcsCluster', value: FnImportValue(FnSub("${EnvironmentName}-ecs-EcsCluster"))
  end

end

```