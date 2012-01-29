(function( $ ) {
	
	$.widget("echo.breadcrumbs", {
		options: {
			container_animation_params: {
        		height : 'toggle',
        		opacity: 'toggle'
      		},
      		container_animation_speed: 400,
      		breadcrumb_animation_params : {
        		width : 'toggle',
        		opacity: 'toggle'
      		},
      		animation_speed: 600
		},
		_create: function() {
			var that = this,
				breadcrumbs = that.element
			breadcrumbs.find('.breadcrumb').each(function() {
				that._initBreadcrumb($(this));
			});

        	breadcrumbs.jScrollPane({animateScroll: true});
			that.scrollPane = breadcrumbs.data('jsp');
        	that.container = that.scrollPane.getContentPane().find('.elements');
        	that._scrollToEnd();

			if (that.container.children().length == 0 && breadcrumbs.is(':visible')) 
			  	that._toggleContainer();
		},
		// Initializes the links in the different sort of breadcrumb items.
		_initBreadcrumb: function(breadcrumb) {
        	if (!breadcrumb.children(':last').hasClass('statement')) {return;}
			var that = this;
			
        	// Loads ids of the statements appearing in the stack
			var sids = [],
				alternativeLevels = [],
				bGen = breadcrumb.prev();

			// iterate on the previous breadcrumbs to generate the stack list
			while (bGen.length > 0) {
				var breadcrumbId = bGen.attr("id");
				// if it's an origin breadcrumb, stack is done
				if (getOriginKeys([breadcrumbId]).length == 0) 
					getHubKeys([breadcrumbId]).length == 0 ?
					sids.unshift(breadcrumbId.match(/\d+/)[0]) : // get id to the stack list
					alternativeLevels.push(bGen.prev().attr("id").match(/\d+/)[0]); // get id of the previous breadcrumb to the al list
					
				 else break;
				bGen = bGen.prev();
			}
			sids.push(breadcrumb.attr('id').match(/\d+/));
				
			// load al with the levels. logic: since we stored the levels of the previous statements before 
			// the alternative mode statement, we have to add 1 to the levels from the stack we get
			alternativeLevels = $.map(alternativeLevels, function(a){
				return $.inArray(a, sids) + 1;
			});

			breadcrumb.bind("click", function(e) {
				e.preventDefault();
				
				var b = $(this);
	          	// Getting bids from fragment
	          	var bidsStack = b.prevAll().map(function() {
					return that._truncateBreadcrumbKey($(this));
	          	}).get().reverse();
	
	
	          	// Getting links that must be removed from the breadcrumbs
	          	var linksToDelete = b.nextAll().map(function() {
	            	return $(this).attr('id');
	          	}).get();
	          	linksToDelete.unshift(b.attr('id'));
	
	          	var newBids = $.grep(bidsStack, function(a, index) {
	            	return $.inArray(a, linksToDelete) == -1;
	          	});
	
	          	// Getting previous breadcrumb entry, in order to load the proper siblings to session
				var originBids = getOriginKeys(newBids);
	          	var origin = originBids.length > 0 ? originBids[originBids.length -1] : '';
	
				if (sids.join(",") == $.fragment().sids) {
					sids.pop();
			       // Sids won't change, we are inside a new form, and we press the breadcrumb to go back
					var path = $.queryString(b.attr('href'), {"sids" : sids.join(","), "bids" : ''});
					$.getScript(path);
				}
				else {
					$.setFragment({
						"bids": newBids.join(","),
						"sids": sids.join(","),
						"nl": true,
						"origin": origin,
						"al": alternativeLevels.join(",")
					});
				}
	        });
	  	},
	  	// Scrolls the breadcrumbs' scrollable pane to the right end.
      	_scrollToEnd: function() {
      		var that = this,
        		oldWidth =  that.scrollPane.getContentPositionX(),
				newWidth = that._updateContainerWidth();
        	that.scrollPane.reinitialise();
        	that.scrollPane.scrollToX(oldWidth, false);
        	that.scrollPane.scrollToX(newWidth);
      	},
      	// Sets and returns the new width of the breadcrumbs container according to the width of breadcrumb items inside.
		_updateContainerWidth: function() {
			var that = this,
			// Calculate width
        		width = 0;
        	that.container.children().each(function(){
          		width += $(this).outerWidth();
        	});
        	that.container.width(width);
			return width;
		},
		// Shows / hides the breadcrumbs container with all its breadcrumbs (actually, there are no breadcrumbs when it gets hidden).
      	_toggleContainer: function() {
      		var that = this;
        	that.element.animate(that.options.container_animation_params,
            	                that.options.container_animation_speed);
      	},
      	_truncateBreadcrumbKey: function(breadcrumb) {
			var key = breadcrumb.attr('id') == 'sr' ?
                  	  (breadcrumb.attr('id') + breadcrumb.find('.search_link').text().replace(/,/, "\\;")) :
                     breadcrumb.attr('id');
			if (breadcrumb.attr('page_count')) {
				key += "|" + breadcrumb.attr('page_count');
			}
			return key;
		},
		// Deletes Breadcrumbs that are not defined on the bids fragment (and after the last element clicked).
	    _cleanBreadcrumbs: function() {
	    	var that = this,
	    		breadcrumbs = that.element,
        		removeLength = 0,
        		deleteFrom = breadcrumbs.data('element_clicked');

        	if (deleteFrom && deleteFrom.length > 0) { /* if a special link was clicked */
        		if($.inArray(deleteFrom.substring(0,2),['ds','sr']) != -1){deleteFrom = deleteFrom.substring(0,2);}

          		// Get breadcrumbs ordered per id
          		var breadcrumbIds = that.container.find('.breadcrumb').map(function(){ return $(this).attr('id'); });

	          	// There is an origin, so delete breadcrumbs to the right
    	      	var index = $.inArray(deleteFrom, breadcrumbIds),
        	  		toRemove = that.container.find('.breadcrumb:eq(' + (index) + ')'),
          			toRemoveElements = toRemove.nextAll();
          		
          		removeLength = toRemoveElements.length;
          		toRemoveElements.remove();
	
    	    } else { // delete all breadcrumbs that are not in the fragment bids
	
    	      	var bids = $.fragment().bids;
        	  	bids = bids ? bids.split(',') : [];
          		// No origin, that means first breadcrumb pressed, no predecessor, so delete everything
          		that.container.find('.breadcrumb').each(function() {
	          		var breadcrumb = $(this);
    	        	if($.inArray(that._truncateBreadcrumbKey(breadcrumb), bids) == -1) {
        	      		removeLength += breadcrumb.length;
            	  		breadcrumb.remove();
            		}
          		});
        	}

        	breadcrumbs.removeData('element_clicked');

        	if (removeLength > 0) {
	  			that.scrollPane.scrollToX(0);
  				that._updateContainerWidth();
  				that.scrollPane.reinitialise();
        	}

        	return that;
     	},
     	_buildBreadcrumb: function(data, index, breadcrumbsLength) {
        	var breadcrumbKey = data.code.substring(0,2);
        	var breadcrumb = $('<a/>').addClass('breadcrumb').
                             attr('id', data.key).
                             attr('href', data.url).
                             attr('page_count', data.page_count).
                             addClass(breadcrumbKey);
          		
          	// delimiter
        	if (index != 0 || breadcrumbsLength != 0) 
          		breadcrumb.append($("<span/>").addClass('delimiter'));
          		
          		
        	breadcrumb.append($('<span/>').addClass('label').text(data['label'])).
        			   append($('<span/>').addClass('over').text(data['over'])).
        			   append($('<div/>').addClass(data['css']).
                             			  append($('<span/>').addClass('icon')).
                             			  append($('<span/>').addClass('title').text(data['title'])));
        	breadcrumb.hide();
        	return breadcrumb;
      	},
      	getBreadcrumb: function(key) {
			return this.container.find('#'+key);
		},
        deleteBreadcrumbs: function() {
        	var that = this;
			that._cleanBreadcrumbs();
			return that;
		},
		deleteBreadcrumb: function(key) { // Removes the breadcrumb ONLY VISUALLY
			var that = this;
			if (key && key.length > 0) {
				var origin = $.fragment().origin;
				if ($.inArray(origin.substring(0,2),['ds','sr']) != -1) origin = origin.substring(0,2);
				var topBreadcrumb = origin.length > 0 ? breadcrumbs.find('#' + origin) : breadcrumbs.find('.breadcrumb:first');
				var breadcrumb = topBreadcrumb.nextAll('#' + key).remove();
			}
			return that;
		},
		addBreadcrumbs : function(breadcrumbsData) {
			var that = this,
				breadcrumbs = that.element;
				
			if (breadcrumbsData) {
				if(breadcrumbs.is(":hidden")) 
	            	toggleContainer();

				var breadcrumbsLength = that.container.find(".breadcrumb").length;
				// Assemble new breadcrumb entries
				var existentBreadcrumb;
				$.each(breadcrumbsData, function(index, breadcrumbData) { //[id, classes, url, title, label, over]
					existentBreadcrumb = breadcrumbs.find('#' + breadcrumbData.key);
					if (existentBreadcrumb.length == 0) {
					  	var breadcrumb = that._buildBreadcrumb(breadcrumbData, index, breadcrumbsLength);
					  	that.container.append(breadcrumb);
						that._initBreadcrumb(breadcrumb);
					} else 
						existentBreadcrumb.nextAll().remove();
					
				});
			}
			that._scrollToEnd();
          	that.container.find('.breadcrumb:hidden').animate(that.options.breadcrumb_animation_params,
            	                                              that.options.animation_speed);
            	                                              
		
		},
		breadcrumbsToLoad : function (bids) {
			var that = this,
				breadcrumbs = that.element;
			if (bids == null) { return []; }
		    // Current bids in the list
		    var bidList = bids.split(",");

			var deleteFrom = breadcrumbs.data('element_clicked');
			if (deleteFrom) {
		    	var index = $.inArray(deleteFrom, bidList);
				return index == -1 ? bidList : 
					   index >= bidList.length ? [] : 
					   bidList.splice(index+1, bidList.length);
			}
			else {
				// Current breadcrumb entries
	          	var visibleBids = breadcrumbs.find(".breadcrumb").map(function() {
	            	return that._truncateBreadcrumbKey($(this));
	          	}).get();

				// Get bids that are not visible (DRY)
				return $.grep(bidList, function(a, index){
					return $.inArray(a, visibleBids) == -1;
				});
			}
		},
		getBreadcrumbStack : function (newBreadcrumb) {
			var that = this;
			var currentBreadcrumbs = that.container.find(".breadcrumb").map(function() {
				return that._truncateBreadcrumbKey($(this));
			}).get();
			if (newBreadcrumb) 
            	currentBreadcrumbs.push(newBreadcrumb);
		    return currentBreadcrumbs;
		},
		hideContainer: function() {
			var that = this,
				breadcrumbs = that.element;
				
			if (that.container.find('.breadcrumb').length == 0 && breadcrumbs.is(':visible')) 
	            that._toggleContainer();
			return that;
		}
		
	});
}( jQuery ) );

