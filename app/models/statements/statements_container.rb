#   class: NodeEnvironment
#
#   This class encapsulates all the behaviour associated with the containers of statements used everywhere, for instance, for the
#   children of a statement node, for the siblings of a statement node, or the ancestors of a statement node. Everything that 
#   corresponds to handling groups of statements in the same way should be encapsulated here
#
#   The key should be always a symbol
#   The value is almost always a collection, when not, it's an Integer representing the size of the collection it's replacing
class StatementsContainer < Hash
  
  attr_accessor :documents, :parents
    
  def initialize(*args)
    @documents = {}
    @parents = {}
    super
  end
  
  # returns an ordered array of statements (default order is key)
  def ordered
    self.to_a.sort do |a, b| 
      block_given? ? yield : a[0] <=> b[0]
    end.map(&:last)
  end
  
  # SESSION HELPERS
  
  def add_parent(key, id)
    @parents[key] = id
  end
  
  def to_session(key)
    key = key.to_sym if key.kind_of? String
    elements = self[key]
    
    # move away if there is nothings
    return nil if elements.nil?
    
    
    # get the class of the siblings
    if key.to_s.match(/(\w+)_\d+/)
      klass = $1
    elsif key.to_s.match(/add_(\w+)/)
      klass = $1
    end
    
    if klass.eql?("question")
      session_elements = elements.map(&:target_statement).map(&:root_id) rescue elements.map(&:target_id)
      session_elements << "/add/question"
    else
      
      # if double, two teaser must be added to the two arrays, which is transposed afterwards
      if (klass = klass.classify.constantize).double?
        session_elements = elements.map{|sub| sub.map(&:target_id) }
        klass.sub_types.each_with_index{|typ, index| session_elements[index] << "/#{@parents[key]}/add/#{typ.to_s.underscore}"}
        min = session_elements.map(&:length).min
        session_elements.map!{|s|s.slice(0,min)}.transpose + session_elements.map{|s|s[min..-1]}
        session_elements.flatten!
      else
        session_elements = elements.map(&:target_id)
        session_elements << "/#{@parents[key]}/add/#{$1}"
      end
    end
    
    session_elements
  end

  
  ## DOCUMENTS WAREHOUSE
  
  def store_documents(documents)
    @documents.merge!(documents)
  end
  
  def get_document(node)
    @documents[node.statement_id]
  end
  
  
  ## VIEW HELPERS
  
  def count(klass)
    elements = self[klass]
    return elements if elements.kind_of? Integer
    klass.to_s.classify.constantize.double? ? elements.map(&:total_entries).sum : elements.total_entries
  end
  
  def is_container?(klass)
    self[klass].kind_of? Array 
  end
  
  ## VIEW PARTIALS
  
  %w(children_list more descendants).each do |meth|
    define_method "#{meth}_template" do |klass|
      klass = klass.classify.to_sym if klass.kind_of? String
      if !klass.eql?(:Alternative) and klass.to_s.constantize.double?
        "statements/double/#{meth}"
      else
        "statements/#{meth}"
      end
    end
  end
  
  
  
  ## FALLBACK 
  
  def method_missing(name, *args)
    if self.keys.include?(sing_name = name.to_s.singularize.classify.to_sym)
      self[sing_name]
    elsif name.to_s.ends_with?("=")
      f_name = name.to_s
      f_name = f_name[0, f_name.length-1].to_sym
      self[f_name] = args[0]
    else
      nil
    end
  end
  
end