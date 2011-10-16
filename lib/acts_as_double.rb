module ActsAsDouble

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def double?
      false
    end

    def acts_as_double(*args)
      class_eval do
        class << self

          def double?
            true
          end

          # Setting the sub_types.
          def sub_types
            @@sub_types[self.name] || @@sub_types[self.superclass.name]
          end

          # Setting the sub_types.
          def has_sub_types(klasses)
            @@sub_types ||= { }
            @@sub_types[self.name] ||= []
            @@sub_types[self.name] |= klasses
          end

          def name_for_siblings
            self.superclass.name.underscore
          end

          #
          # Overrides normal behaviour. Delegates to sub_types and merges the results.
          #
          def statements_for_parent(opts)
            sub_types.each_with_object([]) do |type, arr|
              sub_opts = opts.merge(:type => type)
              sub_statements = children_statements(sub_opts).by_alternatives(sub_opts[:alternative_ids]).by_statement_state(sub_opts[:user]).by_alternatives(sub_opts[:alternative_ids])
              sub_statements = sub_statements.by_drafting_state(nil) if opts[:filter_drafting_state]
              arr << sub_statements.by_languages(sub_opts).all(:include => opts[:include], :limit => opts[:limit]) 
            end
          end

          #
          # Overrides default behaviour.
          #
          def paginate_statements(statements, page, per_page = nil)
            per_page = statements.map(&:length).max if per_page.nil? or per_page < 0
            per_page = 1 if per_page.to_i == 0
            statements.map{|c|c.paginate(default_scope.merge(:page => page, :per_page => per_page))}
          end

        end




      end # --- class_eval

      has_sub_types args

    end
  end
end

