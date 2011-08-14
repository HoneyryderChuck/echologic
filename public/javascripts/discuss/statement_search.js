/**
 * @author Tiago
 */

(function($) {

  $.fn.statement_search = function(current_settings) {

    $.fn.statement_search.defaults = {
      'animation_speed': 300,
			'per_page' : 7
    };

    // Merging settings with defaults
    var settings = $.extend({}, $.fn.statement_search.defaults, current_settings);

    return this.each(function() {
      // Creating and binding the statement API
      var elem = $(this), statementSearchApi = elem.data('searchApi');
      if (statementSearchApi) {
        statementSearchApi.reinitialise(current_settings);
      } else {
        statementSearchApi = new StatementSearch(elem);
        elem.data('searchApi', statementSearchApi);
      }
    });


    /*************************/
    /* The statement handler */
    /*************************/

    function StatementSearch(search_container) {
			var elements_list = search_container.find('ul');
			var pagination = search_container.find('.more_pagination');
			var action_bar = $('#action_bar');
      // Initialize the statement
      initialise();


      // Initializes the statement.
      function initialise() {
        initEchoIndicators(search_container);
				initMoreButton();
				initEmbedButton();
				//initScrollPane();
      }

			function initEchoIndicators(container) {
        container.find('.echo_indicator').each(function() {
          var indicator = $(this);
          if (!indicator.hasClass("ei_initialized")) {
            var echo_value = parseInt(indicator.attr('alt'));
            indicator.progressbar({ value: echo_value });
          }
          indicator.addClass("ei_initialized");
        });
      }

			/*
       * Handles the click on the more Button event (replaces it with an element of class 'more_loading')
       */
      function initMoreButton() {
				var elements_count = search_container.find('li.question').length;
        search_container.find(".more_pagination a:Event(!click)").addClass('ajax').bind("click", function() {
          var moreButton = $(this);
					var loadingMoreButton = $('<span/>').text(moreButton.text()).addClass('more_loading');
					var page_count = elements_count / settings['per_page'] + 1;
          moreButton.replaceWith(loadingMoreButton);
					$.setFragment({"page_count" : page_count, "page" : ""});

					// load elements that have to be updated on the page count parameter
					var elements_to_update = search_container.find('a.statement_link, a.avatar_holder, a.add_new_button');
					$.ajax({
						url: moreButton.attr('href'),
            type: 'get',
            dataType: 'script',
            success: function(){
							elements_to_update.each(function(){
								updateUrlCount($(this), page_count);
							});
			      },
						error: function(){
							loadingButton.replaceWith(moreButton);
			      }
					});
					return false;
        });
      }

			function updateUrlCount(element, page_count) {
				element.attr('href',encodeURI(decodeURI(element.attr('href')).replace(/\|\d+/g, "|" + page_count)));
			}


      /*
       * Initializes the Embed echo button and panel.
       */
      function initEmbedButton() {
        var embed_code = action_bar.find('.embed_code');
        action_bar.find('#embed_link').bind("click", function() {
          $(this).next().animate({'opacity' : 'toggle'}, settings['animation_speed']);
          embed_code.selText();
          return false;
        });
        action_bar.find('.embed_panel').bind("mouseleave", function() {
          $(this).fadeOut();
          return false;
        });
      }


      // Public API of statement
      $.extend(this,
      {
        reinitialise: function(resettings)
        {
          settings = $.extend({}, resettings);
          initialise();
        },
				insertContent: function(content, page)
				{
					var children_list = $("#questions_container .content");
					if (page == 1) {
				  	children_list.children().remove();
				  }
					children_list.append(content);

          // Scrolling to the first new list element
          if (page > 1) {
            var first_new_id = "#" + $(content).first().attr("id");
            $.scrollTo(first_new_id, 700);
          }
					initEchoIndicators(children_list);
				},
				updateMoreButton: function(content, to_insert)
				{
          if (to_insert) {
				  	if (pagination && pagination.length > 0) {
				  		pagination.replaceWith(content);
				  	}
				  	else {
				  		content.insertAfter(elements_list);
				  	}
						pagination = content;
				  	initMoreButton();
				  } else {
					  if (pagination) {
							pagination.remove();
							pagination = null;
						}
					}
				},
				updateEmbedButton: function()
				{
					action_bar = $('.action_bar');
					initEmbedButton();
					return this;
				}
      });
    }

  };

})(jQuery);


