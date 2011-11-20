module ActiveRecord
  module Acts
    module Echoable
      def self.included(base)
        base.extend(ClassMethods)
        base.instance_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        def echoable?
          false
        end
      end

      module ClassMethods
        def echoable?
          false
        end

        def acts_as_echoable

          class_eval do
            belongs_to :echo
            has_many :user_echos, :foreign_key => 'echo_id', :primary_key => 'echo_id'
            delegate :supporter_count, :visitor_count, :to => :echo

            named_scope :by_ratio, :include => :echo, :order => '(echos.supporter_count/echos.visitor_count) DESC'
            named_scope :by_supporters, :include => :echo, :order => 'echos.supporter_count DESC'

            attr_accessor :author_support
            
            after_create :author_support
            

            def initialize(*attrs)
              @author_support = false
              super
            end

          end


          class_eval do
            # All echoable objects return true by default.
            def echoable?
              true
            end

            def self.echoable?
              true
            end

            ####################################
            # echo methods for visit & support #
            ####################################

            # Records that the given user has visited the echoable.
            #
            # TODO: Please rename to 'visited!'
            def visited!(user)
              EchoService.instance.visited!(self, user)
            end

            # Returns true if the given user has visited the echoable.
            #
            # Please rename to 'visited?'
            def visited?(user)
              EchoService.instance.visited?(self, user)
            end

            # Records that the given user has supported the echoable.
            #
            # TODO: Please rename to 'supported!'
            def supported!(user)
              EchoService.instance.supported!(self, user)
            end

            # Returns true if the given user supports the echoable.
            #
            # TODO: Please rename to 'supported?'
            def supported?(user)
              EchoService.instance.supported?(self, user)
            end

            #TODO: Please implement the opposite method unsupported!(user) here
            def unsupported!(user)
              EchoService.instance.unsupported!(self, user)
            end

            # Returns true if the given user doesn't support the echoable.
            #
            # TODO: Please implement the opposite method unsupported?(user) here
            def unsupported?(user)
              EchoService.instance.unsupported?(self, user)
            end

            #######################
            # Statistical methods #
            #######################

            # Returns the count of users who has visited the echoable.
            def visitor_count
              find_or_create_echo if echo.nil?
              echo.visitor_count
            end

            # Returns the count of users who currently support the echoable.
            def supporter_count
              find_or_create_echo if echo.nil?
              echo.supporter_count
            end

            # Ratio of supporters vs. visitors
            # currently unused (see ratio)
            def supporters_visitors_ratio

              # FIXME: if we want to avoid devision by zero, the check should be made against visitor_count
              if supporter_count == 0
                return 0
              end
              ((supporter_count.to_f / visitor_count.to_f) * 100).to_i
            end


            # Returns the echo belonging to the echoable and creates it if it doesn't exist yet.
            def find_or_create_echo
              if !self.echo_id.nil?
                echo
              else
                echo = create_echo
                save
                echo
              end
            end


            # FIXME: ALL methods below are statement_node specific and should therefore NOT
            #        belong to the general echoable module/plugin.
            #        Please move it to statement_node_echos (being an extension of statement_node).

            public

            # Delegates to 'support_relative_to_siblings'
            def ratio(parent_statement = parent, type = self.class.name)
              support_relative_to_sibblings(parent_statement, type)
            end
            
            # endpoint of the author support attribute that comes from the form
            def author_support=(val)
              @author_support = true if [true, 1, '1', 'true'].include? val
            end

            # Records the creator's support for the statement.
            def author_support
              return if @author_support.eql? false
              if (!self.incorporable? or self.parent_node.supported?(self.creator)) # and self.echoable? SHOULD I????
                self.supported!(self.creator)
              end
            end

            protected

            # Ratio of this statement's supporters relative to the most supported sibbling statement's supporters.
            def support_relative_to_sibblings(parent_node, type)
              max_support_count = parent_node ? parent_node.max_child_support(type) : max_root_support
              max_support_count == 0 ? 0 : ((supporter_count.to_f / max_support_count.to_f) *
                                           [10*max_support_count, 100].min).to_i
            end

            # Returns the supporter count of the most supported child of the given type.
            def max_child_support(type)
              descendants.scoped(:select => "MAX(echos.supporter_count) AS max_sc",
                                 :joins => :echo,
                                 :conditions => "statement_nodes.type = '#{type}'").first.max_sc.to_i
            end

            # Returns the supporter count of the most supported root (Question for now).
            def max_root_support
              self.class.base_class.scoped(:select => "MAX(echos.supporter_count) AS max_sc",
                           :joins => :echo,
                           :conditions => {:parent_id => nil}).first.max_sc.to_i
            end

            public
            def supporters
              User.find(self.user_echos.supported.all.map(&:user_id))
            end

          end # --- class_eval

        end
      end
    end
  end
end