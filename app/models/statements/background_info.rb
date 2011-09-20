class BackgroundInfo < StatementNode
  has_children_of_types
  has_linkable_types :BackgroundInfo

  delegate :statement_datas, :info_type, :external_url, :to => :statement

  #Overwriting of nested set function (hub's make it impossible to level them right)
  def level; parent_node.level + 1; end

  class << self

    # Returns whether the node has some embeddable external data to show
    def has_embeddable_data?
      true
    end

    def more_data_partial
      'statements/background_data'
    end
  end
end
