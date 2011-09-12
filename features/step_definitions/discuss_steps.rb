Given /^there are no questions$/ do
  Question.destroy_all
end

Then /^there should be no questions$/ do
  Question.count.should == 0
end

Then /^there should be one question$/ do
  Question.count.should == 1
end

When /^I choose the first ([^\"]*)$/ do |type|
  type = type.split(" ").join("_").downcase
  response.should have_selector("li.#{type} a") do |selector|
    instance_variable_set("@#{type}",type.classify.constantize.find(URI.parse(selector.first['href']).path.match(/\d+/)[0].to_i))
    visit selector.first['href']
  end
end

When /^I choose the second Question$/ do
  response.should have_selector("li.question a") do |selector|
    if question_id = URI.parse(selector[1]['href']).path.match(/\d+/)[0].to_i
      @second_question = Question.find(question_id)
      visit selector.first['href']
    else
      raise 'there is no second question dude... this test does not work'
    end
  end
end

When /^I choose the "([^\"]*)" ([^\"]*)$/ do |name, type|
  type_class = type.split(' ').join('').constantize
  type = type_class.name.underscore
  response.should have_selector("li.#{type}") do |selector|
    selector.each do |statement|
      link = statement.at_css("a.#{type}_link")
      elem = statement.at_css("a.#{type}_link span.title")
      if elem and name.eql?(elem.inner_text.strip)
        instance_variable_set("@#{type}", type_class.find(URI.parse(link['href']).path.match(/\d+/)[0]))
        visit link['href']
      end
    end
  end
end

When /^I see a group of ([^\"]*)$/ do |type|
  type = type.singularize
  elements = []
  response.should have_selector("li.#{type}") do |selector|
    selector.each do |statement|
      elem = statement.at_css("a.#{type}_link")
      elements << elem.inner_text.strip if elem
    end
  end
  instance_variable_set("@#{type}_titles", elements + [I18n.t("discuss.statements.create_#{type}_link")])
end

Then /^I should see the group of ([^\"]*) titles while pressing the ([^\"]*) button$/ do |type, button|
  elements = instance_variable_get("@#{type}_titles")
  elements = [elements[0]] + elements[1..-1].reverse if button.eql? 'prev'
  elements.each do |title|
    Then 'I should see "' + title + '"'
    When 'I follow "' + button + '" within "div.' + type + ' .header_buttons' + '"'
  end
end

When /^there are hidden ([^\"]*) for this ([^\"]*)$/ do |hidden_type, parent_type|
  parent_children = instance_variable_get("@#{parent_type}").child_statements :language_ids => [Language[:en].id], :type => hidden_type.singularize.classify
  parent_children_titles = parent_children.map{|p|p.document_in_preferred_language([Language[:en].id]).title}

  visible_titles = []
  response.should have_selector("li.#{hidden_type.singularize}") do |selector|
    selector.each do |statement|
      visible_titles << statement.at_css('a.statement_link').inner_text.strip
    end
  end
  instance_variable_set("@hidden_#{hidden_type}", parent_children_titles - visible_titles)
end

Then /^I should see the hidden ([^\"]*)$/ do |type|
  titles = instance_variable_get("@hidden_#{type}")
  res = false
  response.should have_selector("li.#{type.singularize}") do |selector|
    selector.each do |statement|
      res = true if titles.include?(statement.at_css('a.statement_link span.title').inner_text.strip)
    end
  end
  assert res
end

Then /^I should see an error message$/i do
  Then 'I should see "error"'
end

Given /^there is the first question$/i do
  @question = Question.last
end

Given /^there is the second question$/i do
  @question = Question.first
end

Given /^there is a question$/ do
  @question = Question.first
end

Given /^there is a question "([^\"]*)"$/ do |id| # not in use right now
  @question = Question.find(id)
end

Given /^there is a question i have created$/ do # not in use right now
   @question = Question.find_by_creator_id(@user.id)
end

Given /^the question was not published yet$/ do
  @question.statement.editorial_state = StatementState["new"]
  @question.statement.save
end

Given /^the question has proposals$/ do
  @question.reload
  @question.children.proposals.count.should >= 1
end

Given /^the question has "([^\"]*)" for tags$/i do |tags|
  @question.statement.topic_tags = tags
  @question.statement.save
end

Given /^the question has no proposals$/ do
  @question.children.proposals.destroy_all
end

When /^I follow the create proposal link$/ do
  # Todo: Yet we still don't know how the create proposal link will once look
  When 'I follow the "Create proposal" link within the "children" list'
end

Then /^the question should have one proposal$/ do
  @question.reload
  @question.children.proposals.count.should >= 1
end

Then /^the ([^\"]*) should have 1 alternative$/ do |type|
  Then "the #{type} should have 1 alternatives"
end

Then /^the ([^\"]*) should have ([^\"]*) alternatives$/ do |type, number|
  var = instance_variable_get("@#{type.split(' ').join('_')}")
  var.reload
  n = number.to_i
  assert_equal n, var.alternatives.count
end

Then /^the question "([^\"]*)" should have "([^\"]*)" as tags$/ do |title, tags|
  tags = tags.split(',').map{|t| t.strip}
  @question = StatementNode.search_statement_nodes(:type => "Question",
                                                   :search_term => title,
                                                   :language_ids => [Language["en"]],
                                                   :show_unpublished => true).first
  res = @question.topic_tags - tags
  res.should == []
end

Then /^the second question must be more recent than the first question$/ do
  @question.created_at < @second_question.created_at
end

# Is it okay to give a condition in a 'Given' step?
Given /^the question has at least one proposal$/ do
  @question.reload
  @question.children.proposals.count.should >= 1
  @proposal = @question.children.proposals.first
end

Then /^the proposal should have one improvement$/ do
  @proposal.reload
  @proposal.children.improvements.count.should >= 1
end

Then /^I should not see the create proposal link$/ do
#  Then 'I should not see the "Create proposal" link within the "children" container'
  Then 'I should not see the "Create proposal" link'
end

Given /^a "([^\"]*)" question in "([^\"]*)"$/ do |state, category|
  state = StatementState[state.downcase]
  @question = Question.new(:creator => @user)
  @question.statement = Statement.new(:editorial_state => state, :original_language_id => @user.sorted_spoken_languages.first)
  @question.statement.statement_documents.build(
       :title => "Am I a new statement?",
       :text => "I wonder what i really am! Maybe a statement? Or even a question?",
       :statement_history => StatementHistory.new(:author => @user,:action_id => StatementAction["created"].id),
       :current => 1,
       :language_id => @user.sorted_spoken_languages.first
       )
  @question.statement.topic_tags << category
  @question.save!
end

Then /^the ([^\"]*) should be ([^\"]*)$/ do |type, state|
  type = type.split(' ').join('_')
  variable = instance_variable_get("@#{type}").reload
  assert_equal state, variable.editorial_state.code
end

Then /^I should see the questions title$/ do
  Then 'I should see "'+@question.document_in_preferred_language([Language["en"].id, Language["de"].id]).title+'"'
end

Given /^there is a proposal I have created$/ do
  @proposal = Proposal.find_by_creator_id(@user.id)
end

Given /^there is a proposal$/ do
  @proposal = Question.all(:joins => :statement, :conditions => "statements.editorial_state_id = #{StatementState['published'].id}").last.children.proposals.first
end

Given /^the proposal was not published yet$/ do
  @proposal.statement.editorial_state = StatementState["new"]
  @proposal.statement.save
end

Given /^I have "([^\"]*)" as decision making tags$/ do |tags|
  @user.decision_making_tags << tags
  @user.save
end

Then /^the questions title should be "([^\"]*)"$/ do |title|
  @question.document.title.should == title
end


Then /^I should see the ([^\"]*) data$/ do |type|
  type = type.split(" ").join("_")
  doc = instance_variable_get("@#{type}").document_in_preferred_language([Language["en"].id,Language["de"].id])
  Then 'I should see "'+doc.title+'"'
  Then 'I should see "'+doc.text+'"'
end

Then /^I should see no proposals$/ do
  assert_have_no_selector("li.question")
end

Then /^I should be a subscriber from the ([^\"]*)$/ do |st_type|
  st_type = st_type.split(' ').join('_')
  statement = instance_variable_get("@#{st_type}")
  @user.reload
  assert(@user.follows?(statement))
end

Then /^I should have 1 subscription$/ do
  Then "I should have 1 subscriptions"
end

Then /^I should have ([^\"]*) subscriptions$/ do |number|
  @user.reload
  assert_equal number.to_i, @user.subscriptions.length
end

Then /^the ([^\"]*) should not have a "([^\"]*)" event$/ do |st_type, op_type|
  st_type = st_type.split(' ').join('_')
  statement = instance_variable_get("@#{st_type}")
  event = Event.all.select{|e|event = JSON.parse(e.event) ; event['id'].eql? statement.id and event['type'].eql? st_type}.first
  puts event.inspect
  assert event.nil?
end

Then /^the ([^\"]*) should have a "([^\"]*)" event$/ do |st_type, op_type|
  st_type = st_type.split(' ').join('_')
  statement = instance_variable_get("@#{st_type}")
  event = Event.all.select{|e|event = JSON.parse(e.event) ; event['id'].eql? statement.id and event['type'].eql? st_type}.first
  assert !event.nil?
  assert_equal op_type, event.operation
end

Then /^the ([^\"]*) should have no events$/ do |type|
  type = type.split(' ').join('_')
  variable = instance_variable_get("@#{type}")
  variable.reload
  event = Event.all.select{|e|
    ev = JSON.parse(e.event)
    ev['id'].eql? variable.target_id and ev['type'].eql? variable.class.name.underscore
  }.first
  assert event.nil?
end

Then /^the ([^\"]*) should have ([^\"]*) siblings in session$/ do |statement_type, siblings_number|
  type = statement_type.split(" ").map(&:downcase).join("_").classify.constantize.name_for_siblings
  response.should have_selector("#statements div.#{type}") do |selector|
    statement = selector.first
    siblings = eval(statement.get_attribute("data-siblings"))
    assert_equal siblings_number.to_i, siblings.select{|s|s.is_a?(Numeric)}.length - 1
  end
end

Then /^there should be a "([^\"]*)" breadcrumb$/ do |title|
  response.should have_selector("#breadcrumbs .statement") do |selector|
    result = false
    selector.each do |breadcrumb|
      if title.eql?(breadcrumb.inner_text.strip)
        result = true
        break
      end
    end
    assert result
  end
end


Given /^([^\"]*) are not immediately loaded on ([^\"]*)$/ do |child_type, parent_type|
  flexmock(parent_type.singularize.classify.constantize).should_receive(:children_types).with({:visibility => true}).and_return([[child_type.singularize.classify.to_sym, false]])
  flexmock(parent_type.singularize.classify.constantize).should_receive(:children_types).and_return([child_type.singularize.classify.to_sym])
end