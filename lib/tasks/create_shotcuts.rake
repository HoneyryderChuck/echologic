namespace :create_shortcuts do
  desc "Turns on newsletter notifications for all users"
  task :vision_summit_2011 => :environment do
    %w(vs11 vision-summit visionsummit).each do |shortcut|
      ShortcutUrl.discuss_search_shortcut :title => shortcut,
                                          :params => {:search_terms => "vision-summit-2011"},
                                          :language => "de"
    end
    %w(vf11 vision-fair visionfair).each do |shortcut|
      ShortcutUrl.discuss_search_shortcut :title => shortcut,
                                          :params => {:search_terms => "vision-fair-2011"},
                                          :language => "de"
    end
    %w(szocialis-konzultacio szocikon).each do |shortcut|
      ShortcutUrl.discuss_search_shortcut :title => shortcut,
                                          :params => {:search_terms => "Szoci�lis-Konzult�ci�"},
                                          :language => "hu"
    end
    %w(allam-polgari-dialogus apold).each do |shortcut|
      ShortcutUrl.discuss_search_shortcut :title => shortcut,
                                          :params => {:search_terms => "�llam-POLg�ri-Dial�gus"},
                                          :language => "hu"
    end
  end
end