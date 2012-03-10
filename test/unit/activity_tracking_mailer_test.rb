require 'test_helper'

class ActivityTrackingMailerTest < ActionMailer::TestCase

  context "a user" do
    
    setup {
      events = [events(:event_test_question), events(:event_second_proposal), events(:event_first_impro_proposal), events(:event_closed_impro_proposal)]
#      flexmock(Event).should_receive(:find_tracked_events).with(User).and_return(events)
      @user = users(:user) 
    }
    subject { 
    @user 
    }
    
    context "being sent an activity tracking email with question info" do
      setup do
        @question_event = events(:event_test_question).event
        question_events = [@question_event]

        tags = {'#echonomyjam' => 1,'user' => 2}
        events = {}
        @email = ActivityTrackingMailer.deliver_activity_tracking_mail!(@user,question_events,tags,events)
      end
      
      should "be able to access its data on the email" do
        # Test the body of the sent email contains what we expect it to
        assert_equal [@user.email], @email.to
        assert_equal "echo - New discussion content", @email.subject
        assert_match /New discussion content/, @email.encoded
        assert_match /1 new question/, @email.encoded
        assert_match /#{@question_event[:documents][Language['en'].id]}/, @email.encoded
        assert_match /#{@question_event[:id]}/, @email.encoded
        assert_match /They are related to the following topics:/, @email.encoded
        assert_match /user/, @email.encoded
        assert_match /(2)/, @email.encoded
      end
    end
    
    context "being sent an activity tracking email with proposal info" do
      setup do
        question_events = []
        tags = {}
        @proposal_event = events(:event_second_proposal).event
        events = {@proposal_event[:level] => {
                  @proposal_event[:parent_id] => {
                  @proposal_event[:type] => {
                  @proposal_event[:operation] => [@proposal_event]}}} }
        # Send the email, then test that it got queued
        @email = ActivityTrackingMailer.deliver_activity_tracking_mail!(@user,question_events,tags,events)
        
      end
      should "be able to access its data on the email" do
        assert !ActionMailer::Base.deliveries.empty?
        # Test the body of the sent email contains what we expect it to
        assert_equal [@user.email], @email.to
        assert_equal "echo - New discussion content", @email.subject
        assert_match /New discussion content/, @email.encoded
        assert_match /#{@proposal_event[:parent_documents][Language['en'].id]}/, @email.encoded
        assert_match /#{@proposal_event[:id]}/, @email.encoded
        assert_match /#{@proposal_event[:documents][Language['en'].id]}/, @email.encoded
      end
    end
    
    context "being sent an activity tracking email with improvement info" do
      setup do
        question_events = []
        tags = {}
        @impro_proposal_event = events(:event_first_impro_proposal).event
        events = {@impro_proposal_event[:level] => {
                  @impro_proposal_event[:parent_id] => {
                  @impro_proposal_event[:type] => {
                  @impro_proposal_event[:operation] => [@impro_proposal_event]}}} }
        # Send the email, then test that it got queued
        @email = ActivityTrackingMailer.deliver_activity_tracking_mail!(@user,question_events,tags,events)
        
      end
      should "be able to access its data on the email" do
        assert !ActionMailer::Base.deliveries.empty?
        # Test the body of the sent email contains what we expect it to
        assert_equal [@user.email], @email.to
        assert_equal "echo - New discussion content", @email.subject
        assert_match /New discussion content/, @email.encoded
        assert_match /#{@impro_proposal_event[:parent_documents][Language['en'].id]}/, @email.encoded
        assert_match /#{@impro_proposal_event[:id]}/, @email.encoded
        assert_match /#{@impro_proposal_event[:documents][Language['en'].id]}/, @email.encoded
      end
    end
    
    context "being generated and sent an activity tracking email" do
      setup do
        ActivityTrackingService.instance.generate_activity_mail(@user.id)
      end
      should "not be able to access data from the private improvement" do
        @impro = events(:event_closed_impro_proposal).event
        assert !ActionMailer::Base.deliveries.empty?
        @email = ActionMailer::Base.deliveries.last
        # Test the body of the sent email contains what we expect it to
        assert_equal [@user.email], @email.to
        assert_equal "echo - New discussion content", @email.subject
        assert_match /New discussion content/, @email.encoded
        assert_no_match /#{@impro[:parent_documents][Language['en'].id]}/, @email.encoded
        assert_no_match /#{@impro[:id]}/, @email.encoded
        assert_no_match /#{@impro[:documents][Language['en'].id]}/, @email.encoded
      end
    end
  end
end