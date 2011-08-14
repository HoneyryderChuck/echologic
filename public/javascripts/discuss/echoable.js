(function($){

  $.fn.echoable = function() {

    return this.each(function() {
	    /* Creating echoable and binding its API */
	    var elem = $(this), echoableApi = elem.data('echoableApi');
	    if (echoableApi) {
	      echoableApi.reinitialize();
	    } else {
	      echoableApi = new Echoable(elem);
	      elem.data('echoableApi', echoableApi);
	    }
    });


    /****************/
    /* The echoable */
    /****************/

	  function Echoable(echoable) {
      var echo_button, echo_label;
			/* alternatives auxiliary function */
			var has_alternatives = false;
			/* Social Panel Variables */
			var social_echo_button, social_container, social_panel, social_account_list, social_submit_button;
      initialize();

			/*
       * Initializes an echoable statement in a form or in normal mode.
       */
			function initialize() {
				initEchoIndicators(echoable);
        echo_button = echoable.find('.action_bar .echo_button');
        if (echo_button.length == 0) {
          return;
        }
        echo_label = echo_button.find('.label');

				social_container = echo_button.siblings('.social_echo_container');
        social_echo_button = social_container.find('.social_echo_button');

				if (echoable.hasClass('new')) {
					initNewStatementEchoButton();
				} else {
					initEchoButton();
				}
				if(echoable.find('.alternatives').length > 0) {
					initAlternativePanel();
				}
		  }

      function initLabelMessages() {
        var messages = {
          'supported'     : echo_label.data('supported'),
          'not_supported' : echo_label.data('not-supported')
        };
        echo_label.data('messages', messages);
        echo_label.removeAttr('data-supported').removeAttr('data-not-supported');
        var state = echo_button.hasClass('supported') ? 'supported' : 'not_supported';
        echo_label.text(echo_label.data('messages')[state]);
			}


      /****************************/
      /* Forms for new statements */
      /****************************/

			// Auxiliary Functions
      function initNewStatementEchoButton() {
        initLabelMessages();
				echo_button.bind('click', function(){
					var button = $(this).find('.echo_button_icon');
					var label = $(this).find('.label');
          if ($(this).hasClass('not_supported')) {
            supportEchoButton();
						label.text(label.data('messages')['supported']);
          } else if ($(this).hasClass('supported')) {
            unsupportEchoButton();
						label.text(label.data('messages')['not_supported']);
          }
        });
			}

      /*
       * Triggers all the visual events associated with a support from an echo statement
       */
      function supportEchoButton() {
				var form = echo_button.parents('form.statement');
				updateEchoButton('supported', 'not_supported');
				info(echo_button.data('messages')['supported']);
        echoable.find('#echo').val(true);
        updateSupportersNumber(form,'1');
        updateSupportersBar(form, 'echo_indicator', 'no_echo_indicator', '10');
      }

			/*
       * Triggers all the visual events associated with an unsupport from an echo statement
       */
      function unsupportEchoButton() {
				var form = echo_button.parents('form.statement');
				updateEchoButton('not_supported', 'supported');
				info(echo_button.data('messages')['not_supported']);
        echoable.find('#echo').val(false);
        updateSupportersNumber(form,'0');
        updateSupportersBar(form, 'no_echo_indicator', 'echo_indicator', '0');
      }

      function updateSupportersNumber(form, value) {
        var supporters_label = form.find('.supporters_label');
        var supporters_text = supporters_label.text();
        supporters_label.text(supporters_text.replace(/[0-9]/, value));
      }

      function updateSupportersBar(form, classToAdd, classToRemove, ratio) {
				var header = form.find('.header');
        var old_supporter_bar = header.find('.supporters_bar');
        var new_supporter_bar = $('<span></span>').attr('class', old_supporter_bar.attr('class')).
                                addClass(classToAdd).removeClass(classToRemove).attr('alt', ratio);
        new_supporter_bar.attr('title', form.find('.supporters_label').text());
        old_supporter_bar.replaceWith(new_supporter_bar);
				echoable.data('api').loadRatioBars(header);
      }


      /************************************/
      /* For normal statements (not form) */
      /************************************/

      function initEchoButton() {
        initLabelMessages();
				echo_button.bind('click', function() {

          // Abandon or proceed
					if(echo_button.hasClass('pending') || echo_button.hasClass('clicked')) {
						return false;
					} else {
						echo_button.addClass('clicked').addClass('pending');
					}

          // Icon
          var to_remove, to_add;
					if (echo_button.hasClass('supported')) {
					  to_remove = 'supported';
            to_add = 'not_supported';
					} else {
            to_remove = 'not_supported';
            to_add = 'supported';
					}

          // pre-request
					updateEchoButton(to_add, to_remove);
					echo_label.text(echo_label.data('messages')[to_add]);
					toggleSocialEchoButton();

					var href = echo_button.attr('href');

					$.ajax({
			      url:      echo_button.attr('href'),
			      type:     'post',
			      dataType: 'script',
			      data:   { '_method': 'put' },
						success: function(data, textStatus, XMLHttpRequest) {
              echo_button.removeClass('pending');

              // Request returns with successful with an info, but the echo itself failed
							if (href == echo_button.attr('href')) {
						  	rollback(to_remove, to_add);
						  } else if(social_echo_button.hasClass('clicked')) {
								// IMPORTANT: social echo button must be expandable!
								toggleSocialPanel();
              }
							if (has_alternatives) { echoable.data('alternativeApi').normal_mode(); }
							social_echo_button.removeClass('clicked');
						},

						error: function() {
							echo_button.removeClass('pending');
							rollback(to_remove, to_add);
						}
			    });

          function rollback(to_remove, to_add) {
            updateEchoButton(to_remove, to_add);
					  echo_label.text(echo_label.data('messages')[to_remove]);
						toggleSocialEchoButton();
            var error_lamp = echo_button.find('.error_lamp');
            error_lamp.css('opacity','0.70').show().fadeTo(1000, 0, function() {
              error_lamp.hide();
            });
          }

					return false;
        });

        // Removing the clicked class
        echo_button.bind('mouseleave', function() {
					echo_button.removeClass('clicked');
				});
			}



			function updateEchoButton(classToAdd, classToRemove) {
        echo_button.removeClass(classToRemove).addClass(classToAdd);
      }

      // Social Sharing
			function toggleSocialEchoButton() {
        if (social_echo_button.length > 0) {
					var expandableApi = social_echo_button.data('expandableApi');
					if (social_echo_button.is(":visible") && expandableApi.isLoaded()) {
            expandableApi.toggle();
          }
          social_echo_button.animate(toggleParams, 350);
        }
      }

			function initSocialPanel() {
				social_panel = social_container.find('.social_echo_panel');
				social_account_list = social_panel.find('.social_account_list');
        social_submit_button = social_panel.find("input[type='submit']");
				initSocialAccountButtons();
				initTextCounter();
        initActionButtons();
				initSocialSubmitButton();
			}

			function initSocialAccountButtons() {
				// 1st step: load enable/disable tags
				var messages = {
					'enabled': social_account_list.data('enabled'),
					'disabled': social_account_list.data('disabled')
				};
				social_account_list.find('.button').each(function() {
					var button_container = $(this);
					var tag = null, toggle_tag = null;
					if (button_container.hasClass('enabled')) {
				  	tag = 'enabled'; toggle_tag = 'disabled';
				  }
				  else if (button_container.hasClass('disabled')) {
			  		tag = 'disabled'; toggle_tag = 'enabled';
			  	}
					if (tag) {
						button_container.text(messages[tag]);
						button_container.bind('click', function(){
							if (button_container.hasClass(tag)) {
								button_container.text(messages[toggle_tag]).removeClass(tag).addClass(toggle_tag);
								button_container.next().val(toggle_tag);
							} else {
								button_container.text(messages[tag]).removeClass(toggle_tag).addClass(tag);
								button_container.next().val(tag);
							}
							updateSocialSubmitButtonState();
						});
					}
				});
			}

      /*
       * Initializes character counter for the message so that it cannot be longer than the tweetable 140 chars.
       */
			function initTextCounter() {
				var text = social_panel.find('.text');
				var preview = social_panel.find('.preview');
				var url = preview.data('url');
				var maxChar = 140 - url.length-1; //-1 = white space
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
				preview.removeAttr('data-url');
			}

      /*
       * Initializes the Cancel button.
       */
      function initActionButtons() {
        var cancel_button = social_panel.find('.cancel_text_button');
        cancel_button.click(function() {
          toggleSocialPanel();
        });
      }

      function initSocialSubmitButton() {
				social_submit_button.bind('click', function() {
					if(social_submit_button.hasClass('disabled')) {
						return false;
					} else {
            toggleSocialPanel();
          }
				});
        updateSocialSubmitButtonState();
			}

      function updateSocialSubmitButtonState() {
				var enabled = social_account_list.find("input[value='enabled']");
				if (enabled.length == 0) {
			  	social_submit_button.addClass('disabled');
			  } else {
			  	social_submit_button.removeClass('disabled');
			  }
			}

      function toggleSocialPanel() {
        social_echo_button.data('expandableApi').toggle();
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

      /*********************/
			/* Alternative Panel */
			/*********************/

      function initAlternativePanel() {
				echoable.alternative();
				has_alternatives = (echoable.find('.alternatives a.statement_link').length > 0);
				if (has_alternatives) {
					var api = echoable.data('alternativeApi');
					echo_button.bind('mouseover', function(){
						if (echo_button.hasClass('not_supported') && !echo_button.hasClass('clicked')) {
							api.highlight();
						}
					});
					echo_button.bind('mouseleave', function(){
						if (!echo_button.hasClass('clicked')) {
							api.normal_mode();
						}
					});
				}
			}
			// Public API
      $.extend(this,
      {
				reinitialize: function() {
          initialize();
        },
				updateState: function(href, supporters_bar, supporters_number) {
          echo_button.attr('href', href);
          echoable.find('.header .supporters_bar').replaceWith(supporters_bar);
          echoable.find('.header .supporters_label').text(supporters_number);
					initEchoIndicators(echoable.find('.header'));
          return this;
        },
				loadEchoLabelMessages: function(messages) {
          echo_label.data('messages', messages);
          return this;
        },
				loadEchoInfoMessages: function(messages) {
          echo_button.data('messages', messages);
          return this;
        },
				loadSocialEchoPanel: function() {
					initSocialPanel();
          social_echo_button.data("expandableApi").activated();
					return this;
				},
        loadRatioBars: function(container) {
          initEchoIndicators(container);
          return this;
			  }
			});
		}

  };

})(jQuery);
