class Event < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  serialize :event, Hash


  # FIXME: make only one SQL and join for subscribable ids instead of using parent_id IN (?) !!!!
  def self.find_tracked_events(subscriber)
    select_clause = <<-END
      SELECT * FROM events
        LEFT JOIN event_permissions e_perm ON e_perm.event_id = events.id
      WHERE id IN
        (SELECT distinct e.id FROM events e
          WHERE e.broadcast = 1 AND e.created_at > ? AND e.id > ?
        UNION
        SELECT distinct e.id FROM events e
          LEFT JOIN subscriptions sb ON (e.subscribeable_id = sb.subscribeable_id)
          WHERE sb.subscriber_id = ? AND e.created_at > ? AND e.id > ?)
      AND (e_perm.closed_statement IS NULL or e_perm.granted_user_id = ?)
      ORDER BY id DESC
    END
    query = sanitize_sql([select_clause,
                          1.month.ago.utc,
                          subscriber.last_processed_event_id,
                          subscriber.id,
                          1.month.ago.utc,
                          subscriber.last_processed_event_id,
                          subscriber.id])
    Event.find_by_sql(query)
  end
end
