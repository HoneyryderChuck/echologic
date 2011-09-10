namespace :statement_images do
  task :clean => :environment do
    PendingAction.find_each :conditions => "created_at < #{2.days.ago}" do |pending_action|
      if !pending_action.action.blank?
        action = JSON.parse(pending_action.action)
        if action.keys.include? 'image_id' and !pending_action.status
          StatementImage.find(action['image_id']).destroy
          # TODO: destroy the pending action as well??
        end
      end
    end
  end
end