(function( $ ) {
	
	$.widget("echo.main_search", {
		options: {
			
		},
		_create: function() {
			var that = this,
			searchForm = that.element;

			that.form = $("#search_form");
			that.submitButton = that.form.find('.submit_button'); 
			that.termsInput = $('#search_terms');
			that.sortTypeInput = searchForm.find(':input[id=sort]');
			
			
			that.searchPath = document.location.href.split('?')[0];
			
			that.form.placeholder();
			
			that._initSubmitButton();
			that._initHashChange();	
			that._loadSearchAutoComplete();
			
			that._refresh();
			
			$("#questions_container").statement_search();
		},
		_refresh: function() {
			var that = this,
			searchForm = that.element;
			
			that.sortTypeButtons = searchForm.parent().find("a.ajax_sort, a.ajax_no_sort");
			that.paginationButtons = searchForm.parent().find('.pagination a');
			
			that._initHistoryEvents();
			that._paginationButtons();
		},
		_initSubmitButton: function() {
			var that = this;
			
			that.submitButton.bind("click", function(e){
				e.preventDefault();
				e.stopPropagation();
			    that._setSearchHistory();
			});
		},
		_initHistoryEvents: function() {
			var that = this;
			
			that.termsInput.bind("keypress", function(e) {
			    if (e && e.keyCode == $.ui.keyCode.ENTER) { /* check if enter was pressed */
			    	that.submitButton.click();
			      	return false;
			    }
		  	});

  			that.sortTypeButtons.bind("click", function(e) {
  				e.preventDefault();
  				e.stopPropagation();
  				var sortButton = $(this),
    				sort = sortButton.hasClass('ajax_no_sort') ? '' : sortButton.attr('value');

				that.sortTypeInput.val(sort);
				that.submitButton.click();
  			});

		},
		_paginationButtons: function() {
			var that = this;
			that.paginationButtons.bind("click", function(e) {
				e.preventDefault();
				e.stopPropagation();
			    pushState({ "page" : $.deparam.querystring(this.href).page })
			});
		},
		_initHashChange: function() {
			var that = this;
			if (window.searchHashHandling) return;
			
			$(window).bind("hashchange", function() {
				// page_count is for the lazy more pagination
	  			if (getState("page") && getState("page_count")) that._triggerSearchQuery();
			});
				
			if (getState("page_count")) 
			    pushState({"page": "1"});
				
			if (hashHistoryState()) {
				echoApp.stateChangeStrategy = history.replaceState;
				$(window).bind("popstate", function() {
					echoApp.hash_state = $.deparam.querystring(location.href);
					$(window).trigger( 'hashchange' );					
			    });
			}
			
			window.searchHashHandling = true;
		},
		_setSearchHistory: function() {
			var that = this;
			that.form.data('placeholder').cleanDefaultValues();
			
  			var searchTerms = $.trim(that.termsInput.val());
  			
  			var data = { "search_terms": searchTerms, 
    					 "page": 1, 
    					 "page_count" : ""
    		};
  			
  			if (that.sortTypeInput.length > 0) 
    			data["sort"] = that.sortTypeInput.val();
    		
	  		pushState(data);
		},
		// Initialises auto_complete property for the tags text input
		_loadSearchAutoComplete: function() {
			var that = this,
				path = $('.function_container:first').is('#echo_discuss_search') ? 
					   '../../discuss/auto_complete_for_tag_value' : 
					   '../users/users/auto_complete_for_tag_value';

  			that.form.find('.tag_value_autocomplete').autocompletes(path, {minChars: 3,
                                                                 		   selectFirst: false,
                                                                 		   multiple: true});
		},
		_triggerSearchQuery: function() {
			var that = this;
			var state = getState();
  			$.getScript($.param.querystring(that.searchPath, state), function() {
  				that._refresh();
  			});
		}
	});
}( jQuery ) );
	