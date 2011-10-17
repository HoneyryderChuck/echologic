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



  # Self written SQL for querying profiles in echo Connect
  def self.search_profiles(competence, search_terms, opts={})

    conditions = []

    # get active users
    conditions << "#{User.table_name}.active = 1"

    # sort by competence (or not)
    if competence.blank?
      joins = "LEFT JOIN #{Membership.table_name} ON #{Membership.table_name}.user_id = #{User.table_name}.id "
      # General search
      searched_fields = ["#{table_name}.full_name", "#{table_name}.city",
                         "#{table_name}.country", "#{table_name}.about_me",
                         "#{table_name}.motivation", "#{User.table_name}.email",
                         "#{Membership.table_name}.position", "#{Membership.table_name}.organisation"]
    else
      joins = ""
      # Search for a certain competence area
      searched_fields = ["#{table_name}.full_name", "#{table_name}.city", "#{table_name}.country"]
      conditions << sanitize_sql(["#{TaoTag.table_name}.context_id = ?", competence])
    end

    order_conditions = "CASE WHEN #{table_name}.completeness >= #{COMPLETENESS_THRESHOLD} THEN 0 ELSE 1 END, " +
                       "CASE WHEN #{table_name}.full_name='' THEN 1 ELSE 0 END, " +
                       "#{table_name}.full_name, #{User.table_name}.id asc;"

    if !search_terms.blank?
      term_query =  "SELECT DISTINCT #{table_name}.id FROM #{table_name} "
      term_query << "LEFT JOIN #{User.table_name}  ON #{User.table_name}.id = #{table_name}.user_id "
      term_query << "LEFT JOIN #{TaoTag.table_name} ON (#{TaoTag.table_name}.tao_id = #{User.table_name}.id and #{TaoTag.table_name}.tao_type = '#{User.name}') " +
                    "LEFT JOIN #{Tag.table_name}    ON #{TaoTag.table_name}.tag_id = #{Tag.table_name}.id "
      term_query << joins
      term_query << "WHERE "

      term_queries = []

      if search_terms.include? ','
        terms = search_terms.split(',')
      else
        terms = search_terms.split(/[\s]+/)
      end
      terms.map(&:strip).each do |term|
        or_conditions = [(term.length > MAX_TERM_TO_SEARCH ? sanitize_sql(["#{Tag.table_name}.value LIKE ?","%#{term}%"]) : sanitize_sql(["#{Tag.table_name}.value = ?",term]))]
        or_conditions += searched_fields.map{|field|sanitize_sql(["#{field} LIKE ?", "%#{term}%"])}
        term_queries << (term_query + (conditions + ["(#{or_conditions.join(" OR ")})"]).join(" AND "))
      end
      term_queries = term_queries.join(" UNION ALL ")

      profiles_query = "SELECT #{table_name}.*, users.email " +
                           "FROM (#{term_queries}) profile_ids " +
                           "LEFT JOIN #{table_name} ON #{table_name}.id = profile_ids.id " +
                           "LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{table_name}.user_id " +
                           "GROUP BY profile_ids.id " +
                           "ORDER BY COUNT(profile_ids.id) DESC, " + order_conditions
    else
      profiles_query = "SELECT DISTINCT #{table_name}.*, #{User.table_name}.email from profiles " +
                       "LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{table_name}.user_id " +
                       "LEFT JOIN #{TaoTag.table_name} ON (#{TaoTag.table_name}.tao_id = #{User.table_name}.id and #{TaoTag.table_name}.tao_type = '#{User.name}') " +
                       "LEFT JOIN #{Tag.table_name} ON #{TaoTag.table_name}.tag_id = #{Tag.table_name}.id " +
                       joins +
                       "WHERE " + conditions.join(' AND ') +
                       " ORDER BY " + order_conditions
    end
    find_by_sql profiles_query
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
