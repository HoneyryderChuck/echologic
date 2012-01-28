(function( $ ) {
	
	$.widget("echo.taggable", {
		options: {
			animation_speed: 500,
			hidden_selector: '.question_tags',
			input_selector: '#tag_topic_id',
			add_button_selector: '.addTag'
		},
		_create: function() {
			var that = this,
				taggable = that.element;
			
			that.loadedTags = taggable.find(that.options.hidden_selector);
			that.tagInput = taggable.find(that.options.input_selector);
			that.container = taggable.find('.tag_container');
			that.addButton = taggable.find(that.options.add_button_selector);
			
			that._loadTags(that.loadedTags.val());
			that._loadTagEvents();
			that._loadStatementAutoComplete();			
		},
		// load this current statement's already existing tags into the tags input box
		_loadTags: function(tags) {
			var that = this,
				tagsToLoad = $.trim(tags).split(','),
				i;
			for (i = 0; i < tagsToLoad.length; i++) {
          		var tag = $.trim(tagsToLoad[i]);
          		if (tag.localeCompare(' ') > 0) 
            		container.append(createTagButton(tag));
        	}
		},
		// adds event handling to all the possible interactions with the tags box
      	_loadTagEvents: function() {
      		var that = this,
      			taggable = that.element;
        	/* Pressing 'enter' button */
        	that.tagInput.bind('keypress', (function(e) {
	          	if (e && e.keyCode == $.ui.keyCode.ENTER) { /* check if enter was pressed */
		            if (that.tagInput.val().length != 0)
	    	          that.addButton.click();
	            	return false;
	          	}
        	}));

        	/* Clicking 'add tag' button */
        	that.addButton.bind('click', (function(e) {
        		e.preventDefault();
          		var enteredTags = $.trim(that.tagInput.val());
          		
	          	if (enteredTags.length != 0) {
	          		enteredTags = enteredTags.split(",");
	            	/* Trimming all tags */
	            	enteredTags = $.map(enteredTags, function(tag) { return $.trim(tag); });
	            
            		var existingTags = that.loadedTags.val();
            		existingTags = existingTags.length == 0 ? [] : existingTags.split(',');
            		
            		existingTags = $.map(existingTags, function(q) {return $.trim(q); });

            		var newTags = new Array(0), i;
            		for (i = 0; i < enteredTags.length; i++) {
            			var tag = $.trim(enteredTags[i]);
              			if ($.inArray(tag,existingTags) == -1 && $.inArray(tag,newTags) == -1) {
                			if (tag.localeCompare(' ') > 0) {
	                  			var element = that._createTagButton(tag);
	                  			that.container.append(element);
	                  			newTags.push(tag);
                			}
              			}
            		}
            		
					if (newTags.length > 0) {
						$.merge(existingTags, newTags)
						that.loadedTags.val(existingTags);
					}
						

					that.tagInput.val('');
            		that.tagInput.focus();
          		}
        	}));
      	},
      	// Aux: Creates the statement tag HTML Element 
      	_createTagButton: function(text) {
      		var that = this,
      			taggable = that.element, 
      			element = $('<span class="tag"/>').text(text),
        		deleteButton = $('<span class="delete_tag_button"/>');
        		
        	deleteButton.bind('click', function(e){
        		e.preventDefault();
        		var button = $(this),
        			parent = button.parent(),
        			tagToDelete = parent.text();
					formTags = that.loadedTags.val().split(',');   
					     				
	          	parent.remove();
	          	
	          	formTags = $.map(formTags, function(q) {return $.trim(q)});
	          	
	          	var indexToDelete = $.inArray(tagToDelete,formTags);
	          	if (indexToDelete >= 0) 
		            formTags.splice(indexToDelete, 1);
		            
	          	that.loadedTags.val(formTags.join(','));
				taggable.trigger('tagremoved', [tagToDelete]);
        	});
        	element.append(deleteButton);
        	return element;
      },
      // Initializes auto_complete property for the tags text input
      _loadStatementAutoComplete: function() {
      		var taggable = this.element;
        	taggable.find('.tag_value_autocomplete').autocompletes('../../discuss/auto_complete_for_tag_value',
                                                              		{minChars: 3, selectFirst: false, multiple: true});
      },
      addTags: function(tags) {
      	var loadedTags = $.trim(that.loadedTags.val());
		loadedTags = !loadedTags ? [] : loadedTags.split(',');
		$.merge(loadedTags,tags);
		
		//update internally on the hidden field
		that.loadedTags.val(loadedTags.join(','));
		
		//create the visual buttons
		that._loadTags(tags.join(','));
		return this;
	},
	removeAllTags: function() 
	{
	  	that.loadedTags.val('');
	  	that.container.children().remove();
	  	return this;
	}


	});
}( jQuery ) ); 
	
	

