class Concernment < ActiveRecord::Base

  # Join table implementation, connect users and tags
  belongs_to :user
  belongs_to :tag

  # Validate uniqueness
  validates_uniqueness_of :tag_id, :scope => [:user_id, :sort]
  validates_presence_of :tag_id, :user_id
  
  # Map the different sorts of concernments to their database representation
  # value..
  @@sorts = {
    0 => I18n.t('users.concernments.sorts.affected'),
    1 => I18n.t('users.concernments.sorts.engaged'),
    2 => I18n.t('users.concernments.sorts.scientist'),
    3 => I18n.t('users.concernments.sorts.representative')
  }
  
  # ..and make it available as class method.
  def self.sorts 
    @@sorts 
  end 
  
  # Validate correctness of sort
  validates_inclusion_of :sort, :in => Concernment.sorts
  

  
end
