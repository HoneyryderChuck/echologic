# TODO unused atm
Given /^I have web addresses (.+)$/ do |profiles|
  profiles.split(', ').each do |profile|
    WebAddress.create!(:address => profile, :type_id => profile, :user_id => current_user_session.user)
  end
end

Given /^I have the following web addresses:$/ do |table|
  table.hashes.each do |hash|
    hash[:type_id] = EnumKey.find_by_code(hash[:type_id]).id
    hash[:user_id] = @user.id
    WebAddress.create!(hash)
  end
end

# TODO unused atm
When /^I create the web address: (.*)$/ do |params|
  type_id, address = params.split(', ')
  fill_in('web_address_address', :with => address)
  click_button('new_web_address_submit')
end

# Check count of web addresses.
Then /^I should have ([0-9]+) web addresses$/ do |count|
  @user.web_addresses.count.should == count.to_i
end

# Remove all web addresses.
Given /^I have no web addresses$/ do
  @user.web_addresses.destroy_all
end
