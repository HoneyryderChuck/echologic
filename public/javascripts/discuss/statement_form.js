(function( $ ) {
	$.widget("echo.statement_form", {
		options: {
			animation_speed: 500,
      		taggableClass : 'taggable',
      		embeddableClass: 'embeddable',
      		longWordLength: 3,
      		minLongWords: 2
		}
		,
		_create: function() {
			var that = this,
				form = that.element;
			that.title = form.find('.statement_title input');
			that.type = $.trim(form.find('input#type').val());
			that.chosenLanguage = form.find('select.language_combo');
			that.publishRadios = form.find('.publish_radios');
			that.isEmbeddable = form.hasClass(that.options.embeddableClass);
			that.isTaggable = form.hasClass(that.options.taggableClass);
			
			
			that._loadRTEEditor();
			
			// New Statement Form Helpers	
			if (form.hasClass('new')) {
				that.languageCombo = form.find('.statement_language select');
				that.statementLinked = form.find('input#statement_node_statement_id');
				
				// Get Id that will be used on the conditions for possible linkable statements
				var parentForLinking = form.prev();
				
				that.statementParentId = parentForLinking.length > 0 ?
										 parentForLinking.data('statement').statementId :
										 form.find('input#statement_node_parent_id').val();	
				
				// placeholder plugin
        		form.placeholder();
        		
        		that._initFormCancelButton();
				that._initLinking();
				that._handleContentChange();
				that._unlinkStatement();
				
				// Taggable Form Helpers (taggable plugin)
			    if (that.isTaggable)
			    	form.taggable();
			    	
			    	
      		}
      		that.refresh();
		},
		refresh: function() {
			var that = this;
				form = that.element;
			that._loadFormEvents();
			
			// embeddable plugin
			if (that.isEmbeddable)
				form.embeddable();
		
		},	
		// Inits the listening to other possible events
      	_loadFormEvents: function(){
      		var form = this.element;
		  	/* listen to upload image events */
			$(document).unbind("upload_started").bind("upload_started", function(){
				form.addClass("disabled");
			});
			$(document).unbind("upload_finished").bind("upload_finished", function(){
				form.removeClass("disabled");
			});
		},
		// Loads the Rich Text Editor for the statement text.
      	_loadRTEEditor: function() {
      		var that = this,
      			form = that.element;
			var textArea = form.find('textarea.rte_doc, textarea.rte_tr_doc');
			if (!isMobileDevice()) {
				var defaultText = textArea.data('default');
				var url = 'http://' + window.location.host + '/stylesheets/';

				textArea.rte({
					css: ['jquery.rte.css'],
					base_url: url,
					frame_class: 'wysiwyg',
					controls_rte: rte_toolbar,
					controls_html: html_toolbar
				});
				form.find('.focus').focus();

				// The default placeholder text
				form.find('iframe').attr('data-default', defaultText);

				that.text = $(form.find('iframe.rte_doc').contents().get(0)).find('body');
			} else
          		that.text = textArea;
      	},
      	// Handles Cancel Button click on new statement forms.
      	_initFormCancelButton: function() {
      		var that = this,
      			form = that.element,
        		cancelButton = form.find('.buttons a.cancel');
        	if ($.fragment().sids) {
	          	var sids = $.fragment().sids.split(","),
	          		lastStatementId = sids.pop();

				var bids = $.fragment().bids;
				bids = bids ? bids.split(',') : [];
				var current_bids = $('#breadcrumbs').data('breadcrumbApi').getBreadcrumbStack(null);

				var i = -1;
				for(j = 0; j < bids.length ; j++) {
					if($.inArray(bids[j], current_bids) == -1) {
              			i = j;
              			break;
            		}
				}

				var bidsToLoad = i > -1 ? bids.splice(i, bids.length) : [];

				var href = $.queryString(cancelButton.attr('href').replace(/statement\/.*/, "statement/" + lastStatementId), {
					"sids": sids.join(","),
					"bids": bidsToLoad.join(','),
					"origin": $.fragment().origin,
					"al": $.fragment().al,
					"cs": $.fragment().sids
          		});

          		cancelButton.addClass("ajax").attr('href', href);
        	}
      	},
      	// Initializes the whole auto completion and linking behaviour.
      	_initLinking: function() {
			var that = this,
				form = that.element;
        	// gets the auto complete button
			that.linkButton = form.find('.header .link_button');

			// loads the labels
			that.linkingMessages = {
				'on' : that.linkButton.data('linking-on'),
				'off': that.linkButton.data('linking-off')
			};

			// initialize the autocompletion plugin
			that.title.autocompletes('../../statements/auto_complete_for_statement_title', {
          		minChars: 100,
          		selectFirst: false,
          		multipleSeparator: "",
          		extraParams: {
            		code: function(){ return that.chosenLanguage.val(); },
            		parent_id: function() {return that.statementParentId; },
            		type: that.type
          		}
        	});

			// handle the selection of an auto completion results entry
			that.title.result(function(evt, data, formatted) {
				if (data) that._linkStatement(data[1]);
				  
			});

        	// what happens when i click the auto completion button
        	that.linkButton.bind('click', function(e){
        		e.preventDefault();
        		
        		var button = $(this);
          		if (button.hasClass('on'))
            		unlinkStatement();
          		else {
            		if (button.hasClass('off')) {
              			var titleValue = that.title.val();
              			if (isEchoStatementUrl(titleValue)) {
                			var statementNodeId = titleValue.match(/statement\/(\d+)/)[1];
                			that._linkStatementNode(statementNodeId);
              			} else {
                			var longWords = 0;
                			$.each(titleValue.split(" "), function(index, word){
                  				if (word.length > that.options.longWordLength) 
	                    			longWords++;
                			});
                			if (longWords >= that.options.minLongWords) {
                  				that.title.addClass('ac_loading');
                  				that.title.search();
                			}
              			}
            		}
          		}

        	});

		},
		// Given a statement node Id, gets the statement remotely and fills the form with the given data.
		_linkStatementNode: function(nodeId) {
			var that = this,
				form = that.element,
				path = '../../statement/' + nodeId + '/link_statement_node/' + type;
    		path = $.queryString(path, {
      			"code" : chosenLanguage.val(),
				"parent_id": statementParentId
    		});
   			$.getJSON(path, function(data) {
				data['error'] ? error(data['error']) : that._linkStatementData(data);
    		});
		},

		// Given a statement Id, gets the statement remotely and fills the form with the given data.
		_linkStatement: function(statementId) {
			var that = this,
				form = that.element,
				path = '../../statement/' + statementId + '/link_statement';
			path = $.queryString(path, {
				"code" : that.chosenLanguage.val()
			});
			$.getJSON(path, function(data) {
				that._linkStatementData(data);

	      		// Embedded Data
				if (that.isEmbeddable) 
					form.data('embeddableApi').linkEmbeddedContent(data);
			});
		},
		
		_linkStatementData: function(data) {
			var that = this,
				form = that.element;
			
			// get data
			var statementId = data['id'];
			that.linkedTitle = data['title']; // used for the key pressed event
        	that.linkedText = data['text'];
        	
	        var statementTags = data['tags'];
	        var statementState = data['editorial_state'];

	        // write title
	        if (that.title.val() != that.linkedTitle)
	          that.title.val(that.linkedTitle);

	        // disable language combo
	        that.languageCombo.attr('disabled', true);

	        // fill in summary text
	        if(that.text && that.text.is('textarea')) 
	          that.text.val(that.linkedText);
	        else
	          that.text.empty().html(that.linkedText).click().blur();

	        // fill in tags
	        if (form.isTaggable) {
	          that.linkedTags = statementTags;
	          form.data('taggable').removeAllTags().addTags(statementTags);
	        }

	        // check right editorial state and disable the radio buttons
	        that.publishRadios.find('input:radio[value=' + statementState + ']').attr('checked', true);
	        that.publishRadios.find('input:radio').attr('disabled', true);

	        // activate link button
	        that._activateLinkButton();

        	form.addClass('linked');

	        //TODO: Not working when text is inside the iframe!!!
	        if (!isMobileDevice()) 
	          that.text.addClass('linked');

	        // link statement Id
	        that.statementLinked.val(statementId);
		},
		// Unlinks the previously linked statement (delete statement Id field and deactivate auto completion button.
		_unlinkStatement: function() {
			var that = this,
				form = that.element;
			
			
			that.linkedTitle = null;
			that.linkedText = null;
			that.statementLinked.val('');
        	that._deactivateLinkButton();
				
			form.removeClass('linked');

			// Disable language combo
        	that.languageCombo.removeAttr('disabled');

			//TODO: Not working when text is inside the iframe!!!
			if (!isMobileDevice()) 
	          that.text.removeClass('linked');

			// Enable editorial state buttons
			that.publishRadios.find('input:radio').removeAttr('disabled');
		},
		// Handles the event of writing new content in one of the fields (in the case, has to unlink a previously unlinked statement).
		_handleContentChange: function() {
			var that = this,
				form = that.element;
			// Title
			that.title.bind('keypress', function(){
				if (that.statementLinked.val() && that.title.val() != that.linkedTitle)
					that._unlinkStatement();
			});

			// Text
			if (that.text && that.text.is('textarea'))
	      		that.text.bind('keypress', function(){
					if (that.statementLinked.val() && that.text.val() != that.linkedText)
						that._unlinkStatement();
				});
			else
				that.text.bind('DOMSubtreeModified', function() {
					if (that.statementLinked.val() && that.text && that.text.html().length > 0) 
						that._unlinkStatement();
				});

			// Tags
			form.bind('tagremoved', function(event, tag) {
				if (that.statementLinked.val() && $.inArray(tag, that.linkedTags) != -1)
					that.unlinkStatement();
			});

	        // Unlink event to be fired by the embeddable part and cathed again here
	        if (form.isEmbeddable) {
				form.data('embeddableApi').handleContentChange('unlink');
			}
			form.bind('unlink', function() {
				if (that.statementLinked.val()) 
					that._unlinkStatement();
			});
		},
		// Turns the link button green and with the label 'linked'.
		_activateLinkButton: function() {
			this._toggleLinkButton('on','off');
		},
		// Turns the auto complete button grey and with the label 'link'
		_deactivateLinkButton: function() {
			this._toggleLinkButton('off','on');
		},
		// Updates the link button with css classes and a new label.
      	_toggleLinkButton: function(to_add, to_remove) {
      		var that = this;
			that.linkButton.addClass(to_add).removeClass(to_remove).text(that.linkingMessages[to_add]);
		}

		

      	


	});
}( jQuery ) );




