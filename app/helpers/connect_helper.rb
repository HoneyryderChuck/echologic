module ConnectHelper

  def open_profile_details(profile)
    link_to url_for(:controller => 'users/profiles',
                    :action => 'details',
                    :id => profile),
            :class => 'ajax show_link avatar_holder' do
      image_tag profile.avatar.url(:small), :alt => ''
    end
  end

  def close_profile_details
    link_to I18n.t('application.general.close'), connect_search_path,
        :id => 'close_details_container',
        :class => 'close_link',
        :onclick => "$('.profile').removeClass('active');
                     $.scrollTo('body', 400, function(){
                       $('#profile_details_container').animate(toggleParams, 500);
                     });
                     return false;"
  end

  def profiles_count_text(count, search_terms, sort_id)
    sort = sort_id.blank? ? nil : TagContext[sort_id.to_i]
    category = sort.nil? ? 'all' : sort.code
    filter = search_terms.blank? ? 'no_filter' : 'with_filter'
    one_or_many = count == 1 ? 'one' : 'more'

    # Assembling the string
    if !filter
      count_text = I18n.t("connect.results_count.#{category}.#{filter}.#{one_or_many}")
    else
      count_text = I18n.t("connect.results_count.#{category}.#{filter}.#{one_or_many}",
                           :filter => search_terms)
    end
    "#{count} #{count_text}"
  end
end
