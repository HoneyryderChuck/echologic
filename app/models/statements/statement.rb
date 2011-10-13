class Statement < ActiveRecord::Base
  acts_as_extaggable :topics
  
  has_many :statement_nodes
  has_many :statement_documents, :dependent => :destroy
  belongs_to :statement_image
  # statement_datas
  has_many :statement_datas # only important for certain selects 
  has_many :external_files
  has_one :external_url, :autosave => true
  has_many :statement_histories, :source => :statement_histories
  
  delegate :image, :image=, :to => :statement_image

  accepts_nested_attributes_for :statement_documents, :limit => 1
  accepts_nested_attributes_for :external_url
  accepts_nested_attributes_for :statement_image
  
  has_enumerated :info_type, :class_name => 'InfoType'
  has_enumerated :editorial_state, :class_name => 'StatementState'

  attr_accessor :pending_image
  
  after_save :update_pending_image

  validates_presence_of :editorial_state_id
  validates_numericality_of :editorial_state_id
  validates_associated :statement_documents
  validates_associated :statement_image
  validates_presence_of :info_type_id, :if => :has_data? 
  validates_associated :external_files
  validates_associated :external_url

  def after_initialize
    self.build_statement_image if self.statement_image.nil?
  end

  def has_data?
    !external_files.empty? or !external_url.nil?
  end
  
  def info_code
    info_type.code if info_type.present?
  end
  
  def info_code=(val)
    self.info_type = InfoType[val]
  end

  def update_pending_image
    return if @pending_image.nil? or !@pending_image.status
    @pending_image.update_attribute(:status, true)
  end

  def authors
    statement_histories.by_creation.by_language(self.original_language_id).map(&:author).uniq
  end

  def has_author? user
    user.nil? ? false : authors.include?(user)
  end

  has_enumerated :original_language, :class_name => 'Language'

  named_scope :find_by_title, lambda {|value|
            { :include => :statement_documents,
              :conditions => ['statement_documents.title LIKE ? and statement_documents.current = 1', "%#{value}%"] } }


  def statement_image_id=(image_id)
    return if image_id.blank?
    @pending_image = PendingAction.find(image_id)
    self.statement_image = StatementImage.find(JSON.parse(@pending_image.action)['image_id'])
  end


  #
  # Returns the current statement document in the given language.
  #
  def document_in_language(language)
    l_id = (language.kind_of?(String) or language.kind_of?(Integer)) ? language : language.id
    self.statement_documents.find(:first,
                                  :conditions => ["language_id = ? and current = 1", l_id])
  end
  
  def documents_by_language(ids=[])
    lang_ids = (ids + [self.original_language_id]).uniq
    documents = self.statement_documents.all(:conditions =>["current = 1 and (language_id IN (?) OR language_id = ?)", lang_ids, self.original_language_id])
    documents.sort! {|a, b|
      a_index = lang_ids.index(a.language_id)
      b_index = lang_ids.index(b.language_id)
       (a_index and b_index) ? a_index <=> b_index : 0
    }
    documents
  end


  ###################
  # PUBLISH ACTIONS #
  ###################

  # static for now
  def published?
    self.editorial_state == StatementState["published"]
  end

  # Publish a statement.
  def publish
    self.editorial_state = StatementState["published"]
  end

  def filtered_topic_tags
    self.topic_tags.select{|tag| !tag.starts_with?('*')}  # Also filters out **tags
  end
  
  ###################
  # STATEMENT DATAS #
  ###################
  
  def external_url
    @external_url ||= statement_datas.first(:conditions => "type = 'ExternalUrl'")
  end
  
  
  class << self
    
    # TODO: TO BE DELETED AS SOON AS I IMPLEMENT THE UNION NAMED SCOPE ON THE STATEMENT NODE!!!!!!
    # returns a string of sql conditions representing the conditions to search on a statement (access conditions)
    # opts attributes:
    # opts (Array) : parameters important to generate the conditions
    # permission_statement (String) : the sql field in which we need to see if a certain statement is private or public
    # permission_user (String) : the sql field in which we need to see if the current user has permission to see the statement (if it's private)
    #
    def conditions(opts={},permission_statement='sp.statement_id', permission_user='sp.user_id')
      # Access permissions
      access_conditions = []
      access_conditions << "#{permission_statement} IS NULL"
      access_conditions << sanitize_sql(["#{permission_user} = ?", opts[:user].id]) if opts[:user]
      "(#{access_conditions.join(' OR ')})"
    end
  end
end
