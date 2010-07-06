class AddLastLoginLanguageToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_login_language_id, :integer
  end

  def self.down
    remove_column :users, :last_login_language_id
  end
end
