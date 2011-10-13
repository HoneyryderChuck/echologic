Given /^the minimum number of votes is ([^\"]*)$/ do |min_votes|
  DraftingService.min_votes = min_votes.to_i
end

Given /^the proposal has an ([^\"]*) child$/ do |state|
  @proposal.reload
  instance_variable_set("@#{state}",@proposal.children.first)
  var = instance_variable_get("@#{state}")
  var.drafting_state = state
  var.save
end

Then /^I should not see the ([^\"]*) child within "([^\"]*)"$/ do |state, container|
  var = instance_variable_get("@#{state}")
  title = var.statement_documents.first.title
  Then 'I should not see "' + title + '" within "' + container + '"'
end

Then /^the state of the improvement must be "([^\"]*)"$/ do |state|
  @improvement.reload
  assert @improvement.send("#{state}?")
end

Then /^the proposal has ([^\"]*) children$/ do |state|
  state = state.split(" ")
  @proposal.reload
  if state[0].eql?("no")
    assert @proposal.send("#{state[1]}_children").empty?
  else
    assert !@proposal.send("#{state[0]}_children").empty?
  end
end

Then /^a "([^\"]*)" delayed job should be created$/ do |job|
  assert !Delayed::Job.all.map{|d|d.handler}.select{|h| h =~ /#{job}/ }.empty?
end

