class SocialIdentifier < ActiveRecord::Base
  validates_presence_of :identifier
  validates_uniqueness_of :identifier
  serialize :profile_info, Hash
  belongs_to :user
end