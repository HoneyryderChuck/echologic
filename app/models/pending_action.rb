class PendingAction < ActiveRecord::Base
  include UUIDHelper
  belongs_to :pending, :polymorphic => true
  serialize :action, Hash
  set_primary_key 'uuid'
  
  
end
