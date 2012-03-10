class ShortcutCommand < ActiveRecord::Base
  has_many :shortcut_urls, :dependent => :destroy
  serialize :command, Hash
  
  validates_uniqueness_of :command
  
  class << self
    
    def build_command(opts)
      {:operation => opts[:operation],
       :params => opts[:params],
       :language => opts[:language]}
    end
    
  end
end
