#
# Handles the echologic start page and all those one-static-pages like
# imprint and about.
# CHANGES:
#   28.08.2009 - Joe:
#     - created and refactored from StaticContentController
#     - index action now handles '/echologic'
#
class Static::EchologicController < ApplicationController
  helper :static_content

  skip_before_filter :require_user

  # Default page redirected to echoLogic - The Mission
  def show
    respond_to do |format|
      if current_user || params[:mode] == 'embed'
        format.html { redirect_to_app_home }
      else
        format.html { render :partial => 'show', :layout => 'static' }
        format.js { render :template => 'layouts/headContainer' }
      end
    end
  end

  # About
  def about
    @about_items = AboutItem.by_index
    render_static_outer_menu :partial => 'about',
                             :locals => {:title => I18n.t('static.echologic.about.title'),
                                         :dialog_width => 950}
  end

  # Imprint
  def imprint
    render_static_outer_menu :partial => 'imprint',
                             :locals => {:title => I18n.t('static.echologic.imprint.title')}
  end

  # Data privacy
  def data_privacy
    render_static_outer_menu :partial => 'data_privacy',
                             :locals => {:title => I18n.t('static.echologic.data_privacy.title')}
  end
end
