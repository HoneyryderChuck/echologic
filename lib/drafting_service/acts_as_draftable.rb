module ActiveRecord
  module Acts
    module Draftable

      def self.included(base)
        base.extend(ClassMethods)
        base.instance_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        def draftable?
          false
        end
      end

      module ClassMethods
        def acts_as_draftable(*args)
          state_types = args.to_a.flatten.compact.map(&:to_sym)

          write_inheritable_attribute(:state_types, (state_types).uniq)
          class_inheritable_reader(:state_types)

          class_eval do
            after_save :check_incorporated
          end

          state_types.map(&:to_s).each do |state_type|
            state = state_type.to_s

            class_eval %(
              def #{state}_children
                descendants.select{|s|s.drafting_state == '#{state}'}
              end
            )
          end

          class_eval do

            def draftable?
              true
            end

            #
            # The drafting language is currently the original language of the draftable.
            #
            def drafting_language
              original_language
            end

            #
            # Returns the current document in the drafting language.
            #
            def document_in_drafting_language
              document_in_language(drafting_language)
            end

            def check_incorporated
              last_document = self.statement_documents.last
              if last_document and last_document.action.code.eql?('incorporated')
                EchoService.instance.incorporated(last_document.incorporated_node, last_document.author)
              end
            end

            ##################################
            ###### RANKINGS N RELATED ########
            ##################################

            # Gets children ordered by supporters number (cacheable)
            def supported_ranking
              instance_variable_get("@supported_ranking") ||
                instance_variable_set("@supported_ranking", fetch_supported_ranking)
            end

            # Updates cache of children by supporters
            def update_supported_ranking
              instance_variable_set("@supported_ranking", fetch_supported_ranking)
            end

            # Generates SQL query to get children by supporters
            def fetch_supported_ranking
              self.children.by_supporters
            end

          end # --- class_eval
        end
      end
    end
  end
end