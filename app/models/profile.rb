require 'rest-open-uri'

class Profile < ActiveRecord::Base

  # Constants
  COMPLETENESS_THRESHOLD = 0.42
  MAX_TERM_TO_SEARCH = 3

  # Every profile has to belong to a user.
  belongs_to :user
  has_many :web_addresses, :through => :user
  has_many :memberships,  :through => :user
  has_many :spoken_languages, :through => :user

  delegate :email, :email=, :affection_tags, :expertise_tags, :engagement_tags, :decision_making_tags,
           :first_membership, :to => :user


  validates_presence_of :user_id
  validates_length_of :about_me, :maximum => 1024, :allow_nil => true
  validates_length_of :motivation, :maximum => 1024, :allow_nil => true

  # To calculate profile completeness
  include ProfileExtension::Completeness

  # There are two kind of people in the world..
  @@gender = {
    false => I18n.t('users.profile.gender.male'),
    true  => I18n.t('users.profile.gender.female')
  }

  # Access for the class variable
  def self.gender
    @@gender
  end

  # Returns the localized gender
  def localized_gender
    @@gender[female] || '' # I18n.t('application.general.undefined')
  end

  # Handle attached user picture through paperclip plugin
  attr_accessor :avatar_url
  has_attached_file :avatar, :styles => { :big => "128x>", :small => "x45>" },
                    :default_url => "/images/default_:style_avatar.png"
  validates_attachment_size :avatar, :less_than => 5.megabytes
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/png', 'image/pjpeg', 'image/x-png']
  before_validation :get_remote_avatar, :if => :avatar_url?


  # paperclip callback, used to recalculate completeness when uploading an avatar
  after_avatar_post_process :calculate_completeness

  # Return the formatted location of the user
  # TODO conditions in compact form?
  #  - something like this?: [city, country].select{|s|s.try(:any?)}.join(', ')
  def location
    [city, country].select { |s| s.try(:any?) }.collect(&:capitalize).join(', ')
  end


  named_scope :active, lambda { {:include => :user, :conditions => "#{User.table_name}.active = 1"} } 
  named_scope :by_competence, lambda {|competence|
    {
    :select => "DISTINCT #{table_name}.*",
    :include => [{:user => :tao_tags}],
    :conditions => ["#{TaoTag.table_name}.context_id = ?", competence] 
    }
  }
  named_scope :by_completeness, :order => "CASE WHEN #{table_name}.completeness >= #{COMPLETENESS_THRESHOLD} THEN 0 ELSE 1 END, CASE WHEN #{table_name}.full_name='' THEN 1 ELSE 0 END, #{table_name}.full_name, #{User.table_name}.id ASC"

  named_scope :with_membership, :include => [:user => :memberships]

  named_scope :with_terms, lambda{ |terms, competence|
    term_queries = []

    query = "SELECT DISTINCT profiles.id FROM profiles "
    query << "LEFT JOIN users  ON users.id = profiles.user_id "
    query << "LEFT JOIN tao_tags ON (tao_tags.tao_id = users.id and tao_tags.tao_type = 'User') " +
             "LEFT JOIN tags     ON tao_tags.tag_id = tags.id "
    query << "LEFT JOIN memberships ON memberships.user_id = users.id " if competence.blank?

    searched_fields = if competence.blank?
      %w(profiles.full_name profiles.city profiles.country profiles.about_me 
         profiles.motivation users.email memberships.position memberships.organisation)
    else
      %w(profiles.full_name profiles.city profiles.country)
    end
    
    terms = terms.include?(',') ? terms.split(',') : terms.split(/[\s]+/)
    conditions = ["users.active = 1"]
    conditions << sanitize_sql(["tao_tags.context_id = ?", competence]) if !competence.blank?
    terms.map(&:strip).each do |term|
      or_conditions = [(term.length > MAX_TERM_TO_SEARCH ? sanitize_sql(["#{Tag.table_name}.value LIKE ?","%#{term}%"]) : sanitize_sql(["#{Tag.table_name}.value = ?",term]))]
      or_conditions += searched_fields.map{|field|sanitize_sql(["#{field} LIKE ?", "%#{term}%"])}
      term_queries << (query + " WHERE " + ( conditions + ["(#{or_conditions.join(" OR ")})"]).join(" AND "))
    end
    term_queries = term_queries.join(" UNION ALL ")
    {  
      :select => "DISTINCT #{table_name}.*",
      :from => "(#{term_queries}) profile_ids",
      :joins => "LEFT JOIN #{table_name} ON #{table_name}.id = profile_ids.id LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{table_name}.user_id",
      :group => "profile_ids.id",
      :order => "COUNT(profile_ids.id) DESC, CASE WHEN #{table_name}.completeness >= #{COMPLETENESS_THRESHOLD} THEN 0 ELSE 1 END, CASE WHEN #{table_name}.full_name='' THEN 1 ELSE 0 END, #{table_name}.full_name, #{User.table_name}.id ASC"
      
    }
  }

  # Self written SQL for querying profiles in echo Connect
  def self.search_profiles(competence, search_terms, opts={})
    if !search_terms.blank?
      profiles = with_terms(search_terms, competence)
    else
      profiles = active
      profiles = profiles.by_competence(competence) if !competence.blank?
      profiles.by_completeness
    end
    
  end
  
  


  private
  def avatar_url?
    !self.avatar_url.blank?
  end

  #
  #block of aux functions to support the download of an external profile image
  def get_remote_avatar
    self.avatar = open(avatar_url)
  end
end
