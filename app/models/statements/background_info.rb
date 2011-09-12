class BackgroundInfo < StatementNode
  has_children_of_types
  has_linkable_types :BackgroundInfo

  delegate :statement_datas, :info_type, :external_url, :to => :statement

  #Overwriting of nested set function (hub's make it impossible to level them right)
  def level; parent_node.level + 1; end

  class << self

    # Aux function: rewrites the attributes hash for it to be valid on the act of creating a new background info
    def filter_attributes(attributes={})
      attributes = filter_editorial_state(attributes)
      # info_type comes as a label ; we must get the info type through this label
      attributes[:info_type_id] = attributes[:info_type] ? InfoType[attributes.delete(:info_type)].id : nil
      attributes[:external_files] = [] # for now; later on, it will record the file attributes into here
      attributes[:external_url] = attributes.delete(:external_url) if attributes[:external_url]
      # TODO: Add here the external files that might be uploaded
      attributes
    end

    # Returns whether the node has some embeddable external data to show
    def has_embeddable_data?
      true
    end

    def more_data_partial
      'statements/background_data'
    end
  end
end
