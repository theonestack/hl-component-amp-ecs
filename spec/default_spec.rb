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


  
end