class PendingAction < ActiveRecord::Base
  include UUIDHelper
  belongs_to :pending, :polymorphic => true
  set_primary_key 'uuid'
  
  
end
