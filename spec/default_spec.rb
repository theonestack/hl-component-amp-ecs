require 'yaml'

describe 'should be valid' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest --no-validate --tests tests/default.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/amp-ecs.compiled.yaml") }

  context 'Resource AMP Workspace' do

    let(:properties) { template["Resources"]["APSWorkspace"]["Properties"] }

    it 'has property' do
      expect(properties).to eq({
        "Alias" => {"Fn::Sub"=>"${EnvironmentName}-amp-ecs"},
        "Tags" => [
          {"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-amp-ecs"}},
          {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}},
          {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}
        ]
      })
    end

  end

  context 'Default AotConfig SSM Param' do

    let(:properties) { template["Resources"]["AotConfig"]["Properties"] }

    it 'has Name property' do
      expect(properties['Name']).to eq({"Fn::Sub" => "/${EnvironmentName}/amq-ecs/AOT_CONFIG_CONTENT"})
    end

    it 'has String Type property' do
      expect(properties['Type']).to eq("String")
    end

    it 'has Value property' do
      expect(properties['Value']).to eq({
        "Fn::Sub" => "---\nextensions:\n  ecs_observer:\n    refresh_interval: 60s\n    cluster_name: \"${EnvironmentName}-services\"\n    cluster_region: \"${AWS::Region}\"\n    result_file: \"/etc/ecs_sd_targets.yaml\"\n    docker_labels:\n    - port_label: ECS_PROMETHEUS_EXPORTER_PORT\n    - port_label: ECS_PROMETHEUS_EXPORTER_PORT_V2\n      metrics_path_label: ECS_PROMETHEUS_EXPORTER_METRICS_PATH\nreceivers:\n  prometheus:\n    config:\n      scrape_configs:\n      - job_name: ecssd\n        file_sd_configs:\n        - files:\n          - \"/etc/ecs_sd_targets.yaml\"\n        relabel_configs:\n        - source_labels:\n          - __meta_ecs_cluster_name\n          action: replace\n          target_label: ClusterName\n        - source_labels:\n          - __meta_ecs_service_name\n          action: replace\n          target_label: ServiceName\n        - source_labels:\n          - __meta_ecs_task_definition_family\n          action: replace\n          target_label: TaskDefinitionFamily\n        - source_labels:\n          - __meta_ecs_container_name\n          action: replace\n          target_label: container_name\n        - action: labelmap\n          regex: \"^__meta_ecs_container_labels_(.+)$\"\n          replacement: \"$$1\"\nprocessors:\n  batch: {}\nexporters:\n  awsprometheusremotewrite:\n    endpoint: \"${APSWorkspace.PrometheusEndpoint}api/v1/remote_write\"\n    aws_auth:\n      region: \"${AWS::Region}\"\n      service: aps\n  logging:\n    loglevel: debug\nservice:\n  extensions:\n  - ecs_observer\n  pipelines:\n    metrics:\n      receivers:\n      - prometheus\n      processors:\n      - batch\n      exporters:\n      - logging\n      - awsprometheusremotewrite\n",
      })
    end

  end

  context 'Resource Condition Grafana Role' do

    let(:condition) { template["Conditions"] }
    let(:resource) { template["Resources"]["GrafanaDataSourceRole"] }
    let(:properties) { template["Resources"]["GrafanaDataSourceRole"]["Properties"] }

    it 'has condition' do
      expect(condition['CreateGrafanaDataSourceRole']).to eq({
        "Fn::Not" => [{"Fn::Equals"=>[{"Ref"=>"GrafanaAccountId"}, ""]}]
      })
      expect(resource['Condition']).to eq('CreateGrafanaDataSourceRole')
    end

    it 'has AssumeRolePolicyDocument' do
      expect(properties['AssumeRolePolicyDocument']).to eq({
        "Version" => "2012-10-17",
        "Statement" => [{"Action"=>"sts:AssumeRole", "Effect"=>"Allow", "Principal"=>{"AWS"=>{"Fn::Sub"=>"arn:aws:iam::${GrafanaAccountId}:root"}}}],
      })
    end

    it 'has Policies' do
      expect(properties['Policies']).to eq(
        [{"PolicyDocument"=>
           {"Statement"=>
             [{"Action"=>["aps:ListWorkspaces"],
              "Effect"=>"Allow",
               "Resource"=>["*"],
               "Sid"=>"amplist"}]},
          "PolicyName"=>"amplist"},
         {"PolicyDocument"=>
           {"Statement"=>
             [{"Action"=>
                ["aps:DescribeWorkspace",
                 "aps:QueryMetrics",
                 "aps:GetLabels",
                 "aps:GetSeries",
                 "aps:GetMetricMetaata"],
               "Effect"=>"Allow",
               "Resource"=>[{"Ref"=>"APSWorkspace"}],
               "Sid"=>"ampread"}]},
          "PolicyName"=>"ampread"}]
      )
    end

  end




  
end