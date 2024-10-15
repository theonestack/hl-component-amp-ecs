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
      expect(properties['Name']).to eq({"Fn::Sub" => "/${EnvironmentName}/amp-ecs/AOT_CONFIG_CONTENT"})
    end

    it 'has String Type property' do
      expect(properties['Type']).to eq("String")
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
                 "aps:GetMetricMetadata"],
               "Effect"=>"Allow",
               "Resource"=>[{"Ref"=>"APSWorkspace"}],
               "Sid"=>"ampread"}]},
          "PolicyName"=>"ampread"}]
      )
    end

  end




  
end