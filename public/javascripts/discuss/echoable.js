(function( $ ) {
	
	$.widget("echo.echoable", {
		options: {
			
		},
		_create: function() {
			var that = this,
				echoable = that.element;
			
			that._initEchoIndicators(echoable);
        	that.echoButton = echoable.find('.action_bar .echo_button');
        	if (that.echoButton.length == 0) return;
        	
        	that.echoLabel = that.echoButton.find('.label');

			that.socialContainer = that.echoButton.siblings('.social_echo_container');
        	that.socialEchoButton = that.socialContainer.find('.social_echo_button');

			echoable.hasClass('new') ? 
			that._initNewStatementEchoButton() :
			that._initEchoButton();
				
			that._initAlternativePanel();
		},
		_initEchoIndicators: function(container) {
			var that = this;
        	
        	container.find('.echo_indicator:not(.ei_initialized)').each(function() {
          		var indicator = $(this),
	            	echoValue = parseInt(indicator.attr('alt'));
	        	indicator.progressbar({ value: echoValue });
	        	
          		indicator.addClass("ei_initialized");
        	});
      	},
      	_initNewStatementEchoButton: function() {
      		var that = this;
      		
      		that.echoLabel.text(that.echoLabel.data(that.echoButton.hasClass('supported') ? 'supported' : 'not_supported'));
			
			that.echoButton.bind('click', function(e){
				e.preventDefault();
				e.stopPropagation();
				var button = $(this);
          		if (button.hasClass('not_supported')) {
            		that._supportEchoButton();
					that.echoLabel.text(that.echoLabel.data('supported'));
          		} else if (button.hasClass('supported')) {
            		that._unsupportEchoButton();
					that.echoLabel.text(that.echoLabel.data('not_supported'));
          		}
        	});
		},	
      	// Triggers all the visual events associated with a support from an echo statement
      	_supportEchoButton: function () {
      		var that = this,
      			echoable = that.element;
      			
			that._updateEchoButton('supported', 'not_supported');
			info(that.echoButton.data('supported'));
        	echoable.find('#statement_node_author_support').val(1);
        	that._updateSupportersNumber(1);
        	that._updateSupportersBar('echo_indicator', 'no_echo_indicator', '10');
      	},
      	// Triggers all the visual events associated with an unsupport from an echo statement
      	_unsupportEchoButton: function() {
      		var that = this,
      			echoable = that.element;
			that._updateEchoButton('not_supported', 'supported');
			info(that.echoButton.data('not-supported'));
        	echoable.find('#statement_node_author_support').val('');
        	that._updateSupportersNumber(0);
        	that._updateSupportersBar('no_echo_indicator', 'echo_indicator', '0');
      	},
      	_updateSupportersNumber: function(value) {
      		var supportersLabel = this.element.find('.supporters_label'),
        		supportersText = supportersLabel.text();
        	
        	supportersLabel.text(supportersText.replace(/\d+/, value));
      	},
      	_updateSupportersBar: function(classToAdd, classToRemove, ratio) {
      		var that = this,
				echoable = that.element,      	
				header = echoable.find('.header'),
        		oldSupporterBar = header.find('.supporters_bar'),
        		// why am i not updating the old element? otherwise the paint plugin will not work properly
        		newSupporterBar = $('<span/>');
        	
        	newSupporterBar.attr('class', oldSupporterBar.attr('class')).
            	            addClass(classToAdd).removeClass(classToRemove).attr('alt', ratio);
            console.log(oldSupporterBar)	                    
           	console.log(newSupporterBar)
        	newSupporterBar.attr('title', echoable.find('.supporters_label').text());
        	oldSupporterBar.replaceWith(newSupporterBar);
        	that.loadRatioBars(header);
      	},
      	_initEchoButton: function() {
      		var that = this,
      			echoable = that.element;
      			
      		that.echoLabel.text(that.echoLabel.data( that.echoButton.hasClass('supported') ? 'supported' : 'not-supported'));
      			
			that.echoButton.bind('click', function(e) {
				var button = $(this);
				e.preventDefault();

      			// Abandon or proceed
				if (button.hasClass('pending') || button.hasClass('clicked')) 
					return; 
				else
					button.addClass('clicked').addClass('pending');

      			// Icon
      			var toRemove = button.hasClass('supported') ? 'supported' : 'not-supported',
      				toAdd = button.hasClass('supported') ? 'not-supported' : 'supported';

      			// pre-request
				that._updateEchoButton(toAdd, toRemove);
				that.echoLabel.text(that.echoLabel.data(toAdd));
				that._toggleSocialEchoButton();

				var href = button.attr('href');

				$.ajax({
		      		url:      button.attr('href'),
		      		type:     'post',
		      		dataType: 'script',
		      		data:     { '_method': 'put' },
					success: function(data, textStatus, XMLHttpRequest) {
          				button.removeClass('pending');

          				// Request returns with successful with an info, but the echo itself failed
						if (href == button.attr('href')) {
					  		rollback(toRemove, toAdd);
					  	} else if(that.socialEchoButton.hasClass('clicked')) {
							// IMPORTANT: social echo button must be expandable!
							that._toggleSocialPanel();
          				}
						if (that.hasAlternatives) echoable.data('alternative').normal_mode();
						that.socialEchoButton.removeClass('clicked');
					},

					error: function() {
						button.removeClass('pending');
						rollback(toRemove, toAdd);
					}
		    	});
			});
			
			// Removing the clicked class
        	that.echoButton.bind('mouseleave', function() {
				$(this).removeClass('clicked');
			});
			
			function rollback(toRemove, toAdd) {
	            that._updateEchoButton(toRemove, toAdd);
				that.echoLabel.text(that.echoLabel.data(toRemove));
				that._toggleSocialEchoButton();
	            var error_lamp = that.echoButton.find('.error_lamp');
	            error_lamp.css('opacity','0.70').show().fadeTo(1000, 0, function() {
	              error_lamp.hide();
	            });
        	}
		},
		_updateEchoButton: function(classToAdd, classToRemove) {
	        this.echoButton.removeClass(classToRemove).addClass(classToAdd);
	   	},
	   	_toggleSocialEchoButton: function() {
	   		var that = this,
				echoable = that.element;	   		
       		if (that.socialEchoButton.length > 0) {
				var expandableApi = that.socialEchoButton.data('expandable');
				if (that.socialEchoButton.is(":visible") && expandableApi.isLoaded()) {
            		expandableApi.toggle();
          		}
          		that.socialEchoButton.animate(toggleParams, 350);
       		}
      	},
      	_initSocialPanel: function() {
      		var that = this;
	 		that.socialPanel = that.socialContainer.find('.social_echo_panel');
			that.socialAccountList = that.socialPanel.find('.social_account_list');
        	that.socialSubmitButton = that.socialPanel.find("input[type='submit']");
			that._initSocialAccountButtons();
			that._initTextCounter();
        	that._initActionButtons();
			that._initSocialSubmitButton();
		},
		_initSocialAccountButtons: function() {
			var that = this;
			// 1st step: load enable/disable tags
			that.socialAccountList.find('.button').each(function() {
				var buttonContainer = $(this),
					tag = buttonContainer.hasClass('enabled') ? 'enabled' : 
						  buttonContainer.hasClass('disabled') ? 'disabled' : null,
					toggleTag = tag == 'enabled' ? 'disabled' : 
						  		tag == 'disabled' ? 'enabled' : null;

				if (tag) {
					buttonContainer.text(that.socialAccountList.data(tag));
					buttonContainer.bind('click', function(e){
						e.preventDefault();
						if (buttonContainer.hasClass(tag)) {
							buttonContainer.text(that.socialAccountList.data(toggleTag)).removeClass(tag).addClass(toggleTag);
							buttonContainer.next().val(toggleTag);
						} else {
							buttonContainer.text(that.socialAccountList.data(tag)).removeClass(toggleTag).addClass(tag);
							buttonContainer.next().val(tag);
						}
						that._updateSocialSubmitButtonState();
					});
				}
			});
		},
		// Initializes character counter for the message so that it cannot be longer than the tweetable 140 chars.
		_initTextCounter: function() {
			var that = this,
				text = that.socialPanel.find('.text'),
				preview = that.socialPanel.find('.preview'),
				url = preview.data('url'),
				maxChar = 140 - url.length-1; //-1 = white space
				
			text.simplyCountable({
		    	counter: text.next(),
		    	countable: 'characters',
		    	maxCount: maxChar,
				strictMax: true,
		    	countDirection: 'down',
		    	safeClass: 'safe',
		    	overClass: 'over',
				onMaxCount: function() {
					text.val(text.val().substring(0, maxChar));
				}
			});
			
			text.bind('keyup', function(){
				preview.text($.trim(text.val()) + ' ' + url);
			});
			preview.removeData('url');
		},
		// Initializes the Cancel button.
      	_initActionButtons: function() {
      		var that = this,
        		cancelButton = that.socialPanel.find('.cancel_text_button');
        	cancelButton.click(function(e) {
        		e.PreventDefault();
          		that._toggleSocialPanel();
        	});
      	},
      	_initSocialSubmitButton: function() {
      		var that = this;
			that.socialSubmitButton.bind('click', function(e) {
				e.preventDefault();
				if(that.socialSubmitButton.hasClass('disabled')) 
					return;
				else
            		toggleSocialPanel();
			});
        	that._updateSocialSubmitButtonState();
		},
		_updateSocialSubmitButtonState: function() {
			var that = this,
				enabled = that.socialAccountList.find("input[value='enabled']");
			enabled.length == 0 ? 
			that.socialSubmitButton.addClass('disabled') :
			that.socialSubmitButton.removeClass('disabled');
		},
		_toggleSocialPanel: function() {
        	this.socialEchoButton.data('expandable').toggle();
      	},
      	_initAlternativePanel: function() {
      		var that = this,
      			echoable = that.element;
			
			echoable.alternative();
			that.hasAlternatives = (echoable.find('.alternatives a.statement_link').length > 0);
			if (that.hasAlternatives) {
				var api = echoable.data('alternative');
				that.echoButton.bind('mouseover', function(){
					var button = $(this);
					if (button.hasClass('not_supported') && !button.hasClass('clicked')) 
						api.highlight();
				});
				that.echoButton.bind('mouseleave', function(){
					if (!$(this).hasClass('clicked')) {
						api.normal_mode();
					}
				});
			}
		},
		updateState: function(href, supporters) {
			var that = this,
				echoable = that.element;
          	that.echoButton.attr('href', href);
			var header = echoable.find('.header'); 
          	header.find('.supporters_bar').remove();
          	header.find('.supporters_label').remove();
			header.find('.header_link').append(supporters);
			that._initEchoIndicators(header);
          	return that;
        },
		loadSocialEchoPanel: function() {
			var that = this;
			that._initSocialPanel();
          	that.socialEchoButton.data("expandable").activated();
			return that;
		},
        loadRatioBars: function(container) {
        	var that = this;
        	that._initEchoIndicators(that.element);
          	return that;
		}
		
	});
}( jQuery ) );



