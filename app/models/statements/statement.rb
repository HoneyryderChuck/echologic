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

  def after_initialize
    self.statement_image = StatementImage.new if self.statement_image.nil?
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
    
    #
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
    
    
    #
    # gets a set of statements given an hash of arguments
    #
    # opts attributes:
    #
    # search_term (string : optional) : value we ought to search for on title, text and statement tags
    # param (string : optional) : specifies the attribute which we should search
    # type (string : optional) : defines the type of statement to look for ("Question" in most of the cases)
    # show_unpublished (boolean : optional) : if false or nil, only get the published statements (see user as well)
    # user (User : optional) : only used if show_unpublished is false or nil; gets the statements belonging to the user regardless of state (published or new)
    # language_ids (Array[Integer] : optional) : filters out documents which language is not included on the array (gets all of them if nil)
    #
    # Called with no attributes filled: returns all published statements
    #
    def search_statements(opts={})
      
      document_conditions = []
      
      # Languages
      if opts[:user] and !opts[:user].spoken_languages.empty? and opts[:language_ids]
        document_conditions << sanitize_sql(["d.language_id IN (?)", opts[:language_ids]])
      end
      
      statement_conditions = []
      statement_conditions << conditions(opts)
      
      # Published state
      unless opts[:show_unpublished]
        publish_condition = []
        publish_condition << sanitize_sql(["#{table_name}.editorial_state_id = ?",StatementState['published'].id])
        statement_conditions << "(#{publish_condition.join(' OR ')})"
      end
      
      # Limit
      limit = "LIMIT #{opts[:limit]}" if opts[:limit]
      
      search_term = opts.delete(:search_term)
      if !search_term.blank?
        term_query = "SELECT DISTINCT statement_id AS id FROM search_statement_text d "
        term_query << "WHERE "
        
        term_queries = []
        if search_term.include? ','
          terms = search_term.split(',')
        else
          terms = search_term.split(/[\s]+/)
        end
        terms.map(&:strip).each do |term|
          or_conditions = StatementDocument.term_conditions(term)
          term_queries << (term_query + (document_conditions + ["(#{or_conditions})"]).join(" AND "))
        end
        
        term_queries = term_queries.join(" UNION ALL ")
        query = "SELECT #{table_name}.#{opts[:param] || '*'} " +
                "FROM (#{term_queries}) statement_ids " +
                "LEFT JOIN #{table_name} ON #{table_name}.id = statement_ids.id " +
                "LEFT OUTER JOIN statement_permissions sp ON #{table_name}.id = sp.statement_id " +
                "WHERE #{statement_conditions.join(" AND ")} " +
                "GROUP BY #{table_name}.id " +
                "ORDER BY COUNT(#{table_name}.id) DESC, " +
                "#{table_name}.id #{limit};"
      else
        document_conditions << "d.current = 1"
        
        query = "SELECT #{table_name}.#{opts[:param] || '*'} " +
                "FROM #{table_name} " +
                "LEFT JOIN statement_documents d ON d.statement_id = #{table_name}.id " +
                "LEFT OUTER JOIN statement_permissions sp ON #{table_name}.id = sp.statement_id " +
                extaggable_joins_clause +
                "WHERE #{(statement_conditions + document_conditions).join(" AND ")} " +
                "ORDER BY #{table_name}.id #{limit};"
      end
      find_by_sql query
    end
    
    
  end
end
