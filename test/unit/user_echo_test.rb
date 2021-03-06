require 'test_helper'

class UserEchoTest < ActiveSupport::TestCase
  
  context "UserEcho" do
    setup {@user_echo = UserEcho.new}
    subject {@user_echo}
    should_belong_to :echo, :user, :statement
    should_have_db_columns :visited, :supported
    
    context "being told to be created or updated" do
      context "when it does not exist already for the given echo" do
        setup {@user_echo = UserEcho.create_or_update!(:user_id => User.first.id, :echo => Echo.first, :visited => true)}
        should_change "UserEcho.count", :by => 1
        context "and being updated again" do
          setup {@user_echo = UserEcho.create_or_update!(:user_id => User.first.id, :echo => Echo.first, :supported => true)}
        should_not_change "UserEcho.count"
        end
      end
    
    end
    
  end

  
end
