CfhighlanderTemplate do

    DependsOn 'lib-iam@0.1.0'
  
    Parameters do
      ComponentParam 'EnvironmentName', 'dev', isGlobal: true
      ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
      ComponentParam 'VPCId'
      ComponentParam 'SubnetIds'
      ComponentParam 'EcsCluster'
      ComponentParam 'Cpu', '512'
      ComponentParam 'Memory', '1024'
      ComponentParam 'GrafanaAccountId', ''
    end
  
    Component template: 'fargate-v2@0.8.6', name: 'exporter', render: Inline do
      parameter name: 'VPCId', value: Ref(:VPCId)
      parameter name: 'SubnetIds', value: FnSplit(',', Ref(:SubnetIds))
      parameter name: 'EcsCluster', value: Ref(:EcsCluster)
      parameter name: 'DesiredCount', value: 1
      parameter name: 'MinimumHealthyPercent', value: 0
      parameter name: 'MaximumPercent', value: 100
      parameter name: 'Cpu', value: Ref('Cpu')
      parameter name: 'Memory', value: Ref('Memory')
    end
  
  end