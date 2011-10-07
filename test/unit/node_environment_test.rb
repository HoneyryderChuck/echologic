require 'test_helper'

class NodeEnvironmentTest < ActiveSupport::TestCase
  
  context "node environment" do
    
    setup { @node_env }
    subject { @node_env }
      
    
    
    should "be able to read from new level" do
      @node_env = NodeEnvironment.new('something', nil, nil, nil)
      
      assert_true @node_env.new_level?
    end
  end
end
