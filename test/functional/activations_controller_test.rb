require 'test_helper'

class ActivationsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def setup
    @controller = Users::ActivationsController.new
  end

  test "should get basic_profile form" do
    get :basic_profile
    assert_response :redirect
  end

  test "should activate coming from the activation form" do
    u = flexmock(User.new)
    u.signup!({:email => "mymummysdead@john.com"})
    post :activate, :activation_code => u.perishable_token,
         :user => {:full_name => "Mad Max",
                   :password => "pass",
                   :password_confirmation => "pass",
                   :agreement => 1}
    u.reload
    assert u.active?
    assert u.has_password?("pass")
  end

  test "should not activate because data policy was not checked" do
    u = flexmock(User.new)
    u.signup!({:email => "mymummysdead@john.com"})
    post :activate, :activation_code => u.perishable_token,
         :user => {:full_name => "Mad Max",
                   :password => "pass",
                   :password_confirmation => "pass"}
    u.reload
    assert !u.active?
    assert assigns(:error).eql?(I18n.t("users.activation.messages.no_agreement"))
  end

  test "should activate coming from the change email form" do
    u = users(:user)
    p = PendingAction.new(:pending => u,
                          :action => {:email => "maingirl@g5.com",
                                      :email_confirmation => "maingirl@g5.com"}.to_json)
    p.save
    p.reload
    post :activate_email, :token => p.uuid
    assert_not_nil User.find_by_email("maingirl@g5.com")
  end

  test "should not activate coming from the setup basic profile form with an unverified email" do
    u = flexmock(User.create(:profile => Profile.new, :social_identifiers => [
                 SocialIdentifier.new(:identifier => "mi", :provider_name => "o2",
                :profile_info => {'email' => "main@main.com", 'preferredUsername' => "echo beach"}.to_json)]))
    assert_difference('ActionMailer::Base.deliveries.count', 1) do # activate email
      post :activate, :activation_code => u.perishable_token,
           :user => {:full_name => "Mad Max",
                     :email => "main@main.com",
                     :agreement => 1}
      u.reload
      assert !u.active?
      assert u.email.eql?("main@main.com")
    end
  end

  test "should not activate coming from the setup basic profile form with a used email" do
    u = flexmock(User.create(:profile => Profile.new, :social_identifiers => [
                 SocialIdentifier.new(:identifier => "mi", :provider_name => "o2",
                :profile_info => {'email' => "main@main.com", 'preferredUsername' => "echo beach"}.to_json)]))
    assert_difference('ActionMailer::Base.deliveries.count', 0) do # activate email
      post :activate, :activation_code => u.perishable_token,
           :user => {:full_name => "Mad Max",
                     :email => "user@echologic.org",
                     :agreement => 1}
      u.reload
      assert !u.active?
      assert assigns(:error).eql?(I18n.t("activerecord.errors.models.user.attributes.email.taken"))
    end
  end



  test "should activate coming from the setup basic profile form with a verified email" do
    u = flexmock(User.new(:profile => Profile.new, :social_identifiers => [
                 SocialIdentifier.new(:identifier => "mi", :provider_name => "o2",
                :profile_info => {'verifiedEmail' => "main@main.com", 'preferredUsername'=> "echo beach"}.to_json)]))
    u.save
    assert_difference('ActionMailer::Base.deliveries.count', 1) do #activation confirmation email
      post :activate, :activation_code => u.perishable_token,
           :user => {:full_name => "Mad Max",
                     :email => "main@main.com",
                     :agreement => 1}
      u.reload
      assert u.active?
    end
  end
end
