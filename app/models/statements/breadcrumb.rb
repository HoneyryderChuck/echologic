class Breadcrumb < Struct.new(:code, :key, :css, :url, :title, :page_count, :label, :over)
  
  include ActionController::UrlWriter
  
  def initialize(key, value, opts={})
    #default
    self.code = key
    self.key = key
    self.css = "search_link statement_link"
    self.label = I18n.t("discuss.statements.breadcrumbs.labels.#{key}")
    self.over = I18n.t("discuss.statements.breadcrumbs.labels.over.#{key}")
      
    case key
      when "ds" then
        self.page_count = value.blank? ? 1 : value[1..-1] # ds|:page_count
        self.url = discuss_search_path(:page_count => self.page_count)
        self.title = I18n.t("discuss.statements.breadcrumbs.discuss_search")
      when "sr" then
        value = value.split('|')
        self.page_count = value.length > 1 ? value[1] : 1 # sr:search_term|:page_count
        search_terms = self.class.decode_terms(value[0])
        self.url = discuss_search_path(:page_count => self.page_count, :search_terms => search_terms)
        self.title = value[0]
      when "mi" then
        self.css = "my_discussions_link statement_link"
        self.url = my_questions_path
        self.title = I18n.t("discuss.statements.breadcrumbs.my_questions")
      when "pr", "im", "ar", "bi", "fq", "jp", "al", "dq" then
        node = value.kind_of?(StatementNode) ? value : StatementNode.find(value)
        statement_document = node.statement.documents_by_language(opts[:language_ids]).first
        self.key = opts[:final_key] || "#{key}#{node.target_id}"
        self.css = "statement statement_link #{node.u_class_name}_link"
        self.css << " #{node.info_type.code}_link" if node.class.has_embeddable_data?
        self.url = statement_node_path(node,
                                      :bids => opts[:bids].to_s,
                                      :origin => opts[:origin].to_s)
        self.title = statement_document.title 
    end    
    self.title = self.class.decode_terms(self.title)
  end
  
  def container_attributes
    {:id => self.key,
     :class => "breadcrumb #{self.code}",
     :page_count => self.page_count}
  end
  
  def to_hash
    Hash[self.members.map{|m|[m.to_sym, send(m)]}]
  end
  
  
  class << self
    def decode_terms(terms)
      terms ? terms.gsub(/\\;/, ',').gsub(/\\:;/, '|') : nil
    end
    
    def encode_terms(terms)
      terms ? terms.gsub(/,/,'\\;').gsub(/\|/, '\\:;') : nil
    end
  
    def origin_keys
      ["sr","ds","mi","fq","jp","dq"]
    end
    
    def generate_key(name)
      case name
        when "proposal" then 'pr'
        when "improvement" then 'im'
        when "pro_argument","contra_argument" then 'ar'
        when "background_info" then 'bi'
        when "follow_up_question" then 'fq'
        when 'discuss_alternatives_question' then 'dq'
      end
    end
    
    def generate_name(key)
      case key
        when 'fq' then 'follow_up_question'
      end
    end
    
    def all_keys
      %w(ds sr mi pr im ar bi fq jp al dq)
    end
  end
end