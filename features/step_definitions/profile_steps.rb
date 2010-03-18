Given /^I have a blank profile$/ do
  @user.profile = Profile.new
end

Given /^the profiles show_profile flag is set to false$/ do
  @user.profile.show_profile = nil
end

Then /^the profile should be complete enough$/ do
  @user.reload
  @user.profile.completeness.should >= 0.5
end

Then /^the profile should have the show_profile flag set to true$/ do
  @user.profile.show_profile.should == 1
end


