class ShortcutUrl < ActiveRecord::Base
  belongs_to :shortcut_command
  set_primary_key 'shortcut'
  
  delegate :command, :to => :shortcut_command, :allow_nil => true
  
  validates_length_of :shortcut, :maximum => 101
  
 
  class << self
    def truncate(title)
      title.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').gsub(/\s/, '-').gsub(/[^a-zA-Z0-9\-]/, '').downcase.to_s[0,101]
    end
    
    def find_or_create(opts={})
      opts[:base_shortcut] = Base64.encode64(opts[:shortcut])
      
      shortcut = truncate(opts[:shortcut])
      
      shortcut_command = opts.delete(:shortcut_command)
      
      element = find_by_base_shortcut(opts[:base_shortcut])
      
      if element # if an url of this title already exists
        return element if shortcut_command[:command].eql? element.command # return this url if the command is the same 

        # if it is another command, then create an iterated title
        iterator = element.iterator.next.to_s
        shortcut << iterator
        shortcut.slice!(shortcut.length - iterator.length*2, iterator.length) if shortcut.length > 101
        element.update_attribute(:iterator, iterator)
      end
      opts[:shortcut] = shortcut
      s = self.new
      
      s.shortcut_command = ShortcutCommand.find_by_command(shortcut_command[:command].to_yaml) || ShortcutCommand.new(shortcut_command)
      opts.each {|k,v| s.send("#{k}=", v)}
      s.save ? s : nil
    end
    
    def discuss_search_shortcut(opts={})
      command = ShortcutCommand.build_command(:operation => "discuss_search",
                                              :params => opts[:params],
                                              :language => opts[:language])
      ShortcutUrl.find_or_create(:shortcut => opts[:title],
                                 :human_readable => true,
                                 :shortcut_command => {:command => command})
    end
    
    def statement_shortcut(opts={})
      command = ShortcutCommand.build_command(:operation => "statement_node",
                                              :params => opts[:params],
                                              :language => opts[:language])
      ShortcutUrl.find_or_create(:shortcut => opts[:title],
                                 :human_readable => true,
                                 :shortcut_command => {:command => command})
    end
  end
end
