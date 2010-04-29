module EchoEnumerable
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module InstanceMethods
    
  end
  
  module ClassMethods
    
    def language_enum
      enum 'languages'
    end
    def language_level_enum
      enum 'language_levels'
    end
    
    def enum(name, options = {})
      config = {:key => name.to_s.singularize << '_id'}
      config.update(options)    
      belongs_to name.to_s.singularize.to_sym, :class_name => "EnumKey", :conditions => {:name => name}, :foreign_key => config[:key]

      class_eval <<-EOV

        include EchoEnumerable::InstanceMethods

        def self.#{name}(code='')
            code.blank? ? EnumKey.find_all_by_name('#{name}') : EnumKey.find_all_by_name_and_code('#{name}',code)  
        end
        
      EOV

    end
  end
end