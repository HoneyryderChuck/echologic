require 'test_helper'

class UserTest < ActiveSupport::TestCase


  context "a user" do
    setup { @user = User.new }
    subject { @user }

    should have_many :web_addresses
    should have_many :memberships
    should have_many :spoken_languages
    should have_many :reports
    should have_many :tao_tags
    should have_many :tags
    should have_one :profile
    
    #acts_as_social
    should_have_many :social_identifiers

    should "have the following associations" do
      %w(web_addresses tao_tags tags memberships social_identifiers).each do |attr|
        assert @user.send(attr).kind_of?(Array)
      end
    end
    
    should "have roles associated" do
      user = users(:joe)
      assert_respond_to user, :has_role?
      assert user.has_role!(:admin)
    end
    
    should "not save unactive user without email, unless there's a social identifier" do 
      assert !User.new.save
      u = User.new(:social_identifiers => [SocialIdentifier.new(:identifier => "mi", :provider_name => "o2", :profile_info => {:name => "bling"})])
      assert u.save, u.errors.inspect
    end
    
    should "save unactive user without password" do
      u = User.new(:email => "mainman@mainman.com")
      assert u.save, u.errors.inspect
    end
    
    should "save active user if password defined or if there's a social identifier" do
      assert User.new(:email => "mainman@mainman.com", :password => "balls", :active => true).save
      u = User.new(:social_identifiers => [SocialIdentifier.new(:identifier => "mi", :provider_name => "o2", :profile_info => {:name => "bling"})])
      u.save
      u.email = "singledout@mainman.com" 
      u.active = true
      assert u.save, u.errors.inspect
    end
    

    context "being saved" do
      setup do
        @user = User.new(:email => "mainman@mainman.com", :password => "balls")
      end

      context "with spoken languages" do
        setup do
          @user.spoken_languages << SpokenLanguage.new(:language => Language[:en], :level => LanguageLevel[:mother_tongue])
          @user.spoken_languages << SpokenLanguage.new(:language => Language[:de], :level => LanguageLevel[:advanced])
          @user.spoken_languages << SpokenLanguage.new(:language => Language[:es], :level => LanguageLevel[:intermediate])
          @user.spoken_languages << SpokenLanguage.new(:language => Language[:pt], :level => LanguageLevel[:basic])
          @user.spoken_languages << SpokenLanguage.new(:language => Language[:fr], :level => LanguageLevel[:mother_tongue])
        end

        should "return spoken languages as an array of keys" do
          # TODO - this will only work when fixtures do not change. see todos above
          assert !@user.sorted_spoken_languages.any?{|s|!s.kind_of? Integer}
        end

      end

    end
  end
end
