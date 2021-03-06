require 'test_helper'

class TagTest < ActiveSupport::TestCase
  # Tag may not be saved empty.
  def test_no_empty_saving
    t = Tag.new
    assert !t.save, 'Do not save empty tag'
  end
  
  # Tag have to have a user.
  def test_value_uniqueness
    t = tags(:earth)
    c = Tag.new(:value => t.value, :language_id => Tag.languages("en").first)
    assert !c.save, 'value should be unique'    
  end
  
  def test_scopes
    t = tags(:earth)
    named = Tag.named(Tag.languages("en").first,"Earth")
    assert named.include?(t), "should find tag with this value (using named)"
    named_any = Tag.named_any(Tag.languages("en").first,"Earth","Wind","Fire")
    assert named_any.include?(t), "should find tag with this value (using named_any)"
    named_like = Tag.named_like(Tag.languages("en").first,"Ea")
    assert named.include?(t), "should find tag with this value (using named_like)"
    named_like_any = Tag.named_like_any(Tag.languages("en").first,"E","W","F")
    assert named_any.include?(t), "should find tag with this value (using named_like_any)"
  end
  
  def test_insertion
    assert_difference('Tag.count', 1, "should insert 1 value") do
      Tag.find_or_create_with_like_by_value("captainplanet")
    end
    assert_difference('Tag.count', 1, "should insert 1 value in german") do
      Tag.find_or_create_with_like_by_value("kaptainerdbeben",Tag.languages("de").first)
    end
    assert_difference('Tag.count', 0, "should not insert repeated value") do
      Tag.find_or_create_with_like_by_value("captainplanet")
    end    
    assert_difference('Tag.count', 4, "should insert 4 values") do
      Tag.find_or_create_all_with_like_by_value("john","paul","george","ringo")
    end
    assert_difference('Tag.count', 4, "should insert 4 values in german") do
      Tag.find_or_create_all_with_like_by_value("johan","helmut","franz","klaus",Tag.languages("de").first.id)
    end
    
  end
  
  def test_equals
    c = tags(:earth)
    t = Tag.new
    t.value = c.value
    t.language_id = c.language_id
    assert c==t, "should recognize first tag as equal to second tag"
  end
  
end