class ChangeStringToTextAttributesOnModelsThatSerialize < ActiveRecord::Migration
  def self.up
    # Shortcut Command
    rename_column :shortcut_commands, :command, :old_command
    add_column :shortcut_commands, :command, :text
     
    ShortcutCommand.find_each do |sh|
      command = JSON.parse(sh.old_command)
      command.symbolize_keys!
      sh.command = command
      sh.save
      print '.'
    end
    remove_column :shortcut_commands, :old_command
    
    # Shortcut Command
    rename_column :pending_actions, :action, :old_action
    add_column :pending_actions, :action, :text
    
    PendingAction.find_each do |pa|
      action = JSON.parse(pa.old_action)
      action.symbolize_keys!
      pa.action = action
      pa.save
      print '.'
    end
    remove_column :pending_actions, :old_action
    
    # Event
    rename_column :events, :event, :old_event
    add_column :events, :event, :text
    
    Event.find_each do |e|
      event = JSON.parse(e.old_event)
      event.symbolize_keys!
      e.event = event
      e.save
      print '.'
    end
    remove_column :events, :old_event
    
    # Social Identifier
    rename_column :social_identifiers, :profile_info, :old_profile_info
    add_column :social_identifiers, :profile_info, :text
    
    SocialIdentifier.find_each do |si|
      profile_info = JSON.parse(si.old_profile_info)
      profile_info.symbolize_keys!
      si.profile_info = profile_info
      si.save
      print '.'
    end
    remove_column :social_identifiers, :old_profile_info
  end

  def self.down
    # Shortcut Command
    rename_column :shortcut_commands, :command, :old_command
    add_column :shortcut_commands, :command, :text
    
    ShortcutCommand.find_each do |sh|
      command = sh.old_command
      sh.command = command.to_json
      sh.save
      print '.'
    end
    remove_column :shortcut_commands, :old_command
    
    # Shortcut Command
    rename_column :pending_actions, :action, :old_action
    add_column :pending_actions, :action, :text
    
    PendingAction.find_each do |pa|
      action = pa.old_action
      pa.action = action.to_json
      pa.save
      print '.'
    end
    remove_column :pending_actions, :old_action
    
    # Event
    rename_column :events, :event, :old_event
    add_column :events, :event, :text
    
    Event.find_each do |e|
      event = e.old_event
      e.event = event.to_json
      e.save
      print '.'
    end
    remove_column :events, :old_event
    
    # Social Identifier
    rename_column :social_identifiers, :profile_info, :old_profile_info
    add_column :social_identifiers, :profile_info, :text
    
    SocialIdentifier.find_each do |si|
      profile_info = si.old_profile_info
      si.profile_info = profile_info.to_json
      si.save
      print '.'
    end
    remove_column :social_identifiers, :old_profile_info
  end
end
