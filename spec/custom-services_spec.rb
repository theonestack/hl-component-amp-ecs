require 'yaml'

describe 'should be valid' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest --no-validate --tests tests/custom-services.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/custom-services/amp-ecs.compiled.yaml") }


  context 'Custom AotConfig SSM Param' do

    let(:properties) { template["Resources"]["AotConfig"]["Properties"] }

    it 'has Name property' do
      expect(properties['Name']).to eq({"Fn::Sub" => "/${EnvironmentName}/amp-ecs/AOT_CONFIG_CONTENT"})
    end

    it 'has String Type property' do
      expect(properties['Type']).to eq("String")
    end

  end



  
end