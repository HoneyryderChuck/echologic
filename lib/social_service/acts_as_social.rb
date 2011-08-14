module ActiveRecord
  module Acts
    module Social

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_social(*args)

          class_eval do
            has_many :social_identifiers, :class_name => 'SocialIdentifier', :dependent => :destroy

            #
            # test if account it using RPX authentication
            #
            def using_rpx?
              !social_identifiers.empty?
            end


            # adds RPX identification to the instance.
            # Abstracts how the RPX identifier is added to allow for multiplicity of underlying implementations
            #
            def add_social_identifier( rpx_id, rpx_provider_name, profile_info )
              self.social_identifiers.build(:identifier => rpx_id,
                                            :provider_name => rpx_provider_name,
                                            :profile_info => profile_info )
            end

            # Checks if given identifier is an identity for this account
            #
            def identified_by?( id )
              self.social_identifiers.find_by_identifier( id )
            end

            def has_provider?(provider_name)
              self.social_identifiers.find_by_provider_name(provider_name.camelize)
            end

            def has_verified_email?(email)
              self.social_identifiers.each do |si|
                return true if email.eql? JSON.parse(si.profile_info)['verifiedEmail']
              end
              false
            end

            def check_social_accounts
              mappings = SocialService.instance.mappings(self.id)
              accounts_to_delete = social_identifiers.select{|s|!mappings.include?(s.identifier)}
              delete_social_accounts(accounts_to_delete, false)
            end

            handle_asynchronously :check_social_accounts

            def delete_social_accounts(accounts=self.social_identifiers, to_unmap=true)
              if !accounts.blank?
                if to_unmap
                  accounts.each do |social|
                    SocialService.instance.unmap(social.identifier, self.id)
                  end
                end
                SocialIdentifier.destroy_all(:id => accounts.map(&:id))
              end
            end

            def update_social_accounts
              outer_mappings = SocialService.instance.mappings(self.id)
              inner_mappings = social_identifiers.map(&:identifier)
              to_remove_mappings = inner_mappings - outer_mappings
              social_identifiers.destroy_all :conditions => ["identifier IN (?)", to_remove_mappings] if !to_remove_mappings.empty?
            end

            class << self
              #
              # Add custom find_by_social_identifier class method
              #
              def find_by_social_identifier(id)
                identifier = SocialIdentifier.find_by_identifier(id)
                if identifier.nil?
                  if self.column_names.include? 'social_identifier'
                    # check for authentication using <=1.0.4, migrate identifier to social_identifiers table
                    user = self.find( :first, :conditions => [ "social_identifier = ?", id ] )
                    unless user.nil?
                      user.add_social_identifier( id, 'Unknown' )
                    end
                    return user
                  else
                    return nil
                  end
                else
                  identifier.send( self.methods.include?(:class_name) ? self.class_name.downcase : self.to_s.classify.downcase )
                end
              end


            end
          end
        end
      end
    end
  end
end