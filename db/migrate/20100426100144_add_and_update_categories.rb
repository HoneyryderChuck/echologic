class AddAndUpdateCategories < ActiveRecord::Migration
  def self.up
    Tag.create!(:value => 'echosocial')
    Tag.create!(:value => 'realprices')
    t = Tag.find_by_value('echonomyJAM')
    t.value.replace('echonomyjamx')
    t.value.replace('echonomyjam')
    t.save
  end

  def self.down
    Tag.find_by_value('echosocial').delete
    Tag.find_by_value('realprices').delete    
    t = Tag.find_by_value('echonomyjam')
     t.value.replace('echonomyJAMx')
    t.value.replace('echonomyJAM')
    t.save
  end
end
