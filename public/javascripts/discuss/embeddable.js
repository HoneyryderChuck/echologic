(function( $ ) {
	
	$.widget("echo.embeddable", {
		options: {
			embed_speed: 500,
      		scroll_speed: 300,
      		embed_delay: 2000
		},
		_create: function() {
			var that = this,
				embeddable = that.element;
			
			that.embedData = embeddable.find('.embed_data');
			that.entryTypes = that.embedData.find('.entry_types');
			that.embedUrl = that.embedData.find('input.embed_url');
			that.infoTypeInput = that.embedData.find('.info_type_input');

      		that.embedPreview = embeddable.find('.embed_preview');
      		that.embedCommand = that.embedPreview.find('.embed_command');
      		
      		
      		that._initEntryTypes();
        	that._initEmbedURL();
		},
		_initEntryTypes: function() {
			var that = this,
				entries = that.entryTypes.find("li.info_type");
			
        	// Preselection
			if (that.infoTypeInput.val().length > 0) {
				that.selectedType = entries.siblings('.' + that.infoTypeInput.val());
				that.selectedType.addClass("selected");
			}

       		// Click handling
        	var previousType = that.selectedType;
			entries.bind('click', function(){
				that._deselectType();
				that._selectType($(this));
          		if (previousType != that.selectedType) 
            		that._triggerChangeEvent();
			});
		},
		_selectType: function(typeItem) {
			var that = this;
			
        	typeItem.addClass('selected');
        	that.selectedType = typeItem;
			that.infoTypeInput.val(typeItem.data('value'));
			that.embedUrl.removeAttr('disabled');
      	},
		_deselectType: function() {
			var that = this;
        	if (that.selectedType) 
          		that.selectedType.removeClass('selected');
      	},
      	// Triggers the unlink event on type change.
      	_triggerChangeEvent: function() {
      		var that = this,
      			embeddable = that.element;
      			
			if(that.changeEvent) 
          		embeddable.trigger(that.changeEvent);
		},
		// Initiates the event of filling the info url (triggers the loading of that url on an iframe)
      	_initEmbedURL: function() {
			var that = this,
				embeddable = that.element;
			
        	// URL Input
			if (!that.selectedType) 
				that.embedUrl.attr('disabled', 'disabled');
				
			var invalidMessage = that.embedUrl.attr('invalid-message');
			that.embedUrl.data('invalid-message', invalidMessage);
			that.embedUrl.removeAttr('invalid-message');
			that.embedUrl.bind('keypress', function (event) {
				if (event && event.keyCode == $.ui.keyCode.ENTER) { /* check if enter was pressed */
					that._showEmbedPreview();
					return false;
				}
     			that._triggerChangeEvent();
    		});

    		// Preview button
			that.embedData.find('.preview_button').bind('click', function(e){
				e.preventDefault();
				that._showEmbedPreview();
			});

    		// Submit button
			embeddable.bind('submit', function(){
				var url = that.embedUrl.val();
				if (!url.match(/http(s)?:\/\/.*/)) {that.embedUrl.val("http://" + url);}
			});
      	},
      	_showEmbedPreview: function() {
      		var that = this,
				url = that.embedUrl.val();
				
			if (!url.match(/http(s)?:\/\/.*/)) url = "http://" + url;
				
			if (that._isValidUrl(url)) {
          		if (!that.embedPreview.is(':visible')) {
					that.embedPreview.animate(toggleParams, that.options.embed_speed);
            		that._scrollOnPreview();
          		}
          		that._loadEmbeddedContent(url);
			} else {
				error(that.embedUrl.data('invalid-message'));
			}
		},
		// Loads embedded content with the given URL.
      	_loadEmbeddedContent: function(url) {
			var that = this,
        	// Reseting the preview area
        		embeddedContent =that.embedPreview.find('.embedded_content');
        	if (embeddedContent.is(':visible')) {
          		that.embedPreview.find('.embedded_content').animate(toggleParams, that.options.embed_speed, function() {
            		embeddedContent.remove();
            		that._scrollOnPreview();
          		});
        	}
        	that.embedCommand.attr('href', url);

        	// Embed URL
        	that.embedPreview.find('.loading').show();
			that.embedCommand.embedly({
          		maxWidth: 990,
          		maxHeight: 1000,
          		className: 'embedded_content',
          		success: that.embedlyEmbed,
				error: that.manualEmbed
		  	});
      	},
      	_embedlyEmbed: function(oembed, dict) {
      		var that = this,
        		elem = $(dict.node);
        		
        	if (! (oembed) ) return null; 
        	if (oembed.type != 'link') {
          		elem.after(oembed.code);
          		that._showEmbeddedContent();
        	} else {
          		that._manualEmbed(elem, null);
        	}
      	},
	    _manualEmbed: function(node, dict) {
	    	var that = this;
        	node.after($("<div/>").addClass('embedded_content').addClass('manual')
            	        .append($("<iframe/>").attr('frameborder', 0).attr('src', node.attr('href'))));
        	that._showEmbeddedContent();
      	},
      	_showEmbeddedContent: function() {
      		var that = this;
      		 
        	setTimeout(function() {
          		that.embedPreview.find('.loading').hide();
          		that.embedPreview.find('.embedded_content').fadeIn(that.options.embed_speed, that.scrollOnPreview);
        	}, that.options.embed_delay);
      	},
      	_scrollOnPreview: function() {
        	$.scrollTo('form.embeddable .entry_type', this.options.scroll_speed);
      	},
		_isValidUrl: function(url) {
			return url.match(echoApp.urlRegex);
		},
		linkEmbeddedContent: function(data) {
			var that = this,
				contentType = data['content_type'],
          		externalUrl = data['external_url'];

			that._deselectType();
          	that._selectType(that.entryTypes.find('.' + contentType));
          	that.embedUrl.val(externalUrl);
		},
		unlinkEmbeddedContent: function() {
			
		},
		handleContentChange: function(eventName) {
			this.changeEvent = eventName;
		}
		
		
	});
}( jQuery ) );

