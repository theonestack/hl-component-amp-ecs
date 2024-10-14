require 'yaml'

CloudFormation do

    export = external_parameters.fetch(:export_name, external_parameters[:component_name])
  
    tags = instance_userdata = external_parameters.fetch(:tags, [])
    tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{external_parameters[:component_name]}") }
    tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
    tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }
  
    APS_Workspace(:APSWorkspace) do
      Alias FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")
      Tags tags
    end

    ecs_aot_config = external_parameters.fetch(:aot_config_content, external_parameters[:default_aot_config_content])
    aot_ecs_observer = external_parameters[:aot_ecs_observer]
    ecs_aot_config['extensions']['ecs_observer'].merge!(aot_ecs_observer)

    SSM_Parameter(:AotConfig) do
      Name FnSub('/${ParameterPrefix}${EnvironmentName}/amp-ecs/AOT_CONFIG_CONTENT')
      Type 'String'
      Value FnSub("#{YAML.dump(ecs_aot_config)}")
      Description 'AWS OpenTelemetry ECS Exporter Config'
    end
  
    Condition(:CreateGrafanaDataSourceRole, FnNot(FnEquals(Ref(:GrafanaAccountId), "")))
    policy_document = {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow', 
        Principal: { 
          AWS: FnSub("arn:aws:iam::${GrafanaAccountId}:root")
        }, 
        Action: 'sts:AssumeRole' 
      }]
    }
    IAM_Role(:GrafanaDataSourceRole) do
      Condition(:CreateGrafanaDataSourceRole)
      RoleName FnSub('${EnvironmentName}-GrafanaDataSourceRole')
      AssumeRolePolicyDocument policy_document
      Path '/'
      Policies(iam_role_policies(external_parameters[:grafana_iam_policies]))
    end
  
    Output(:APSWorkspaceArn) {
      Value(Ref(:APSWorkspace))
      Export FnSub("${EnvironmentName}-#{export}-APSWorkspace")
    }
  
    Output(:WorkspaceId) {
      Value(FnGetAtt(:APSWorkspace, 'WorkspaceId'))
      Export FnSub("${EnvironmentName}-#{export}-WorkspaceId")
    }
  
    Output(:PrometheusEndpoint) {
      Value(FnGetAtt(:APSWorkspace, 'PrometheusEndpoint'))
      Export FnSub("${EnvironmentName}-#{export}-PrometheusEndpoint")
    }
  
  end
  