class TurnPendingActionUserIntoAPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :pending_actions, :pending_type, :string
    execute "UPDATE pending_actions SET pending_type='User'"
    rename_column :pending_actions, :user_id, :pending_id
  end

  def self.down
    remove_column :pending_actions, :pending_type
    rename_column :pending_actions, :pending_id, :user_id
  end
end
