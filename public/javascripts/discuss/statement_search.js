/**
 * @author Tiagoo
 */

(function( $ ) {
	$.widget("echo.statement_search", {
		options: {
			animation_speed: 300,
			per_page : 7
		},
		_create: function() {
			var that = this,
				searchContainer = that.element;
			that.elementsList = searchContainer.find('ul');
			that.pagination = searchContainer.find('.more_pagination');
			that.actionBar = $('#action_bar');
			
			that._initEchoIndicators(searchContainer);
			that._initMoreButton();
			that._initEmbedButton();
			//that._initScrollPane();
			
		},
		_initEchoIndicators: function(container) {
        	container.find('.echo_indicator').each(function() {
          		var indicator = $(this);
          		if (indicator.hasClass("ein_initialized")) return true;
          		
            	indicator.progressbar({ value: parseInt(indicator.attr('alt')) });
          		indicator.addClass("ei_initialized");
        	});
      	},
      	// Handles the click on the more Button event (replaces it with an element of class 'more_loading')
      	_initMoreButton: function() {
      		var that = this,
      			searchContainer = that.element,
				elementsCount = searchContainer.find('li.question').length;
				
        	searchContainer.find(".more_pagination a:Event(!click)").addClass('ajax').bind("click", function(e) {
        		e.preventDefault();
        		e.stopPropagation();
          		var moreButton = $(this),
					loadingMoreButton = $('<span class="more_loading"/>').text(moreButton.text()),
					pageCount = elementsCount / that.options.per_page + 1;
          		moreButton.replaceWith(loadingMoreButton);
				$.bbq.pushState({"page_count" : pageCount, "page" : ""});

				// load elements that have to be updated on the page count parameter
				var elementsToUpdate = searchContainer.find('a.statement_link, a.avatar_holder, a.add_new_button');
				$.ajax({
					url: moreButton.attr('href'),
            		type: 'get',
            		dataType: 'script',
            		success: function(){
						elementsToUpdate.each(function(){
							that._updateUrlCount($(this), pageCount);
						});
			      	},
					error: function(){
						loadingButton.replaceWith(moreButton);
			      	}
				});
        	});
       	},
       	_updateUrlCount: function(element, pageCount) {
			element.attr('href',encodeURI(decodeURI(element.attr('href')).replace(/\|\d+/g, "|" + pageCount)));
		},
		// Initialises the Embed echo button and panel.
      	_initEmbedButton: function() {
      		var that = this,
        		embedCode = that.actionBar.find('.embed_code');
        	
        	that.actionBar.find('#embed_link').bind("click", function(e) {
        		e.preventDefault();
          		$(this).next().animate({'opacity' : 'toggle'}, that.options.animation_speed);
          		embedCode.selText();
        	});
        	that.actionBar.find('.embed_panel').bind("mouseleave", function() {
          		$(this).fadeOut();
        	});
      	},
      	insertContent: function(content, page) {
      		var that = this,
				childrenList = that.element.find(".content");
			if (page == 1) 
				childrenList.children().remove();
				
			childrenList.append(content);

          	// Scrolling to the first new list element
          	if (page > 1) {
            	var firstNewId = "#" + $(content).first().attr("id");
            	$.scrollTo(firstNewId, 700);
          	}
			that._initEchoIndicators(childrenList);
		},
		updateMoreButton: function(content, toInsert) {
			var that = this;
        	if (toInsert) {
				if (that.pagination && that.pagination.length > 0) {
					that.pagination.replaceWith(content);
				}
				else {
					content.insertAfter(elements_list);
				}
				pagination = content;
				that.initMoreButton();
			} else {
				if (that.pagination) {
					that.pagination.remove();
					that.pagination = null;
				}
			}
		},
		updateEmbedButton: function() {
			var that = this;
			
			that.actionBar = $('#action_bar');
			that._initEmbedButton();
			return that;
		}
      
		
	});
}( jQuery ) );

