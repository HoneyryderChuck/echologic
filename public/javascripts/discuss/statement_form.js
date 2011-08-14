(function($) {

  $.fn.statementForm = function(currentSettings) {

    $.fn.statementForm.defaults = {
      'animation_speed': 500,
      'taggableClass' : 'taggable'
    };

    // Merging settings with defaults
    var settings = $.extend({}, $.fn.statementForm.defaults, currentSettings);

    return this.each(function() {
	    // Creating and binding the statement form API
	    var elem = $(this), statementFormApi = elem.data('statementFormApi');
	    if (statementFormApi) {
	      statementFormApi.reinitialise();
	    } else {
	      statementFormApi = new StatementForm(elem);
	      elem.data('statementFormApi', statementFormApi);
	    }
		});


    /******************************/
    /* The statement form handler */
    /******************************/

    function StatementForm(form) {
		var title = form.find('.statement_title input');
		var type = $.trim(form.find('input#type').val());
		var text;
		var language_combo;
		var chosenLanguage = form.find('select.language_combo');
		var statementLinked, statementParentId;
		var publishRadios = form.find('.publish_radios');
		var linkButton;
      	var linkingMessages;
		var linkedTags;
		var linkedTitle, linkedText;

		initialise();

		

      
		function initialise() {
      
			loadFormEvents();
			loadRTEEditor();

      if (form.hasClass('embeddable')) {
				form.embeddable();
      }

      // New Statement Form Helpers
      if (form.hasClass('new')) {
				language_combo = form.find('.statement_language select');
				statementLinked = form.find('input#statement_node_statement_id');
				
				
				// Get Id that will be used on the conditions for possible linkable statements
				var parentForLinking = form.prev();
				if(parentForLinking.length > 0) {
					statementParentId = getStatementId(parentForLinking.attr('id'));
				} else {
				  statementParentId = form.find('input#statement_node_parent_id').val();	
				}
				
				
        loadDefaultText();
        initFormCancelButton();
				initLinking();
				handleContentChange();
				unlinkStatement();
      }

      // Taggable Form Helpers
      if (form.hasClass(settings['taggableClass'])) {
        form.taggable();
      }
		}
			
			/*
       * Inits the listening to other possible events
       */
      function loadFormEvents(){
	  	/* listen to upload image events */
				$(document).bind("upload_started", function(){
					form.addClass("disabled");
				});
				$(document).bind("upload_finished", function(){
					form.removeClass("disabled");
				});
			}

			/*
       * Loads the Rich Text Editor for the statement text.
       */
      function loadRTEEditor() {
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

					text = $(form.find('iframe.rte_doc').contents().get(0)).find('body');
				} else {
          text = textArea;
				}
      }


			/*
       * Loads the form's default texts for title, text and tags.
       */
			function loadDefaultText() {
        if (!form.hasClass('new')) {return;}
        form.placeholder();
      }

			/*
       * Handles Cancel Button click on new statement forms.
       */
      function initFormCancelButton() {
        var cancelButton = form.find('.buttons a.cancel');
        if ($.fragment().sids) {
          var sids = $.fragment().sids;
          var new_sids = sids.split(",");
          var path = "/" + new_sids[new_sids.length-1];
          new_sids.pop();

					var bids = $.fragment().bids;
					bids = bids ? bids.split(',') : [];
					var current_bids = $('#breadcrumbs').data('breadcrumbApi').getBreadcrumbStack(null);

					var i = -1;
					for(j=0;j<bids.length;j++) {
						if($.inArray(bids[j], current_bids) == -1) {
              i = j;
              break;
            }
					}

					var bids_to_load = i > -1 ? bids.splice(i, bids.length) : [];

          cancelButton.addClass("ajax");
          cancelButton.attr('href', $.queryString(cancelButton.attr('href').replace(/\/\d+/, path), {
            "sids": new_sids.join(","),
            "bids": bids_to_load.join(','),
						"origin": $.fragment().origin,
						"cs" : $.fragment().sids
          }));
        }
      }

      /**********************/
      /* Statement Linking  */
      /**********************/

			/*
       * Turns the link button green and with the label 'linked'.
       */
			function activateLinkButton() {
				toggleLinkButton('on','off');
			}

			/*
       * Turns the auto complete button grey and with the label 'link'
       */
			function deactivateLinkButton() {
				toggleLinkButton('off','on');
			}

      /*
       * Updates the link button with css classes and a new label.
       */
      function toggleLinkButton(to_add, to_remove) {
				linkButton.addClass(to_add).removeClass(to_remove).text(linkingMessages[to_add]);
			}

      /*
       * Initializes the whole auto completion and linking behaviour.
       */
      function initLinking() {

        // gets the auto complete button
				linkButton = form.find('.header .link_button');

				// loads the labels
				linkingMessages = {
					'on' : linkButton.attr('linking_on'),
					'off': linkButton.attr('linking_off')
				};

				linkButton.removeAttr('linking_on').removeAttr('linking_off');

				// initialize the autocompletion plugin
				title.autocompletes('../../statements/auto_complete_for_statement_title', {
          minChars: 100,
          selectFirst: false,
          multipleSeparator: "",
          extraParams: {
            code: function(){ return chosenLanguage.val(); },
            parent_id: function() {return statementParentId; },
            type: type
          }
        });

				// handle the selection of an auto completion results entry
				title.result(function(evt, data, formatted) {
					if (data) {
				  	linkStatement(data[1]);
				  }
				});

        // what happens when i click the auto completion button
        linkButton.bind('click', function(){
          if ($(this).hasClass('on')) {
            unlinkStatement();
          } else {
            if ($(this).hasClass('off')) {
              var titleValue = title.val();
              if (isEchoStatementUrl(titleValue)) {
                var statementNodeId = titleValue.match("statement/([0-9]+).*")[1];
                linkStatementNode(statementNodeId);
              }	else {
                var longWords = 0;
                $.each(titleValue.split(" "), function(index, word){
                  if (word.length > 3) {
                    longWords++;
                  }
                });
                if (longWords >= 2) {
                  title.addClass('ac_loading');
                  title.search();
                }
              }
            }
          }

        });

			}


			/*
       * Given a statement node Id, gets the statement remotely and fills the form with the given data.
       */
			function linkStatementNode(nodeId) {
				var path = '../../statement/' + nodeId + '/link_statement_node/' + type;
        path = $.queryString(path, {
          "code" : chosenLanguage.val(),
					"parent_id": statementParentId
        });
        $.getJSON(path, function(data) {
					if (data['error']) {
		        error(data['error']);
				  }
				  else {
				  	linkStatementData(data);
				  }
        });
			}


			/*
       * Given a statement Id, gets the statement remotely and fills the form with the given data.
       */
			function linkStatement(statementId) {

				var path = '../../statement/' + statementId + '/link_statement';
				path = $.queryString(path, {
					"code" : chosenLanguage.val()
				});
				$.getJSON(path, function(data) {
					linkStatementData(data);

          // Embedded Data
					if (form.hasClass('embeddable')) {
						form.data('embeddableApi').linkEmbeddedContent(data);
					}
				});
			}

			function linkStatementData(data) {
				statementId = data['id'];
				linkedTitle = data['title']; // used for the key pressed event
        linkedText = data['text'];
        var statementTags = data['tags'];
        var statementState = data['editorial_state'];

        // write title
        if (title.val() != linkedTitle) {
          title.val(linkedTitle);
        }

        // disable language combo
        language_combo.attr('disabled', true);

        // fill in summary text
        if(text && text.is('textarea')) {
          text.val(linkedText);
        } else {
          text.empty().html(linkedText).click().blur();
        }

        // fill in tags
        if (form.hasClass(settings['taggableClass'])) {
          linkedTags = statementTags;
          form.data('taggableApi').removeAllTags().addTags(statementTags);
        }

        // check right editorial state and disable the radio buttons
        publishRadios.find('input:radio[value=' + statementState + ']').attr('checked', true);
        publishRadios.find('input:radio').attr('disabled', true);

        // activate link button
        activateLinkButton();

        form.addClass('linked');

        //TODO: Not working when text is inside the iframe!!!
        if (!isMobileDevice()) {
          text.addClass('linked');
        }

        // link statement Id
        statementLinked.val(statementId);
			}

			/*
       * Unlinks the previously linked statement (delete statement Id field and deactivate auto completion button.
       */
			function unlinkStatement() {
				linkedTitle = null;
				linkedText = null;
				statementLinked.val('');
        deactivateLinkButton();
				form.removeClass('linked');

				// Disable language combo
        language_combo.removeAttr('disabled');

				//TODO: Not working when text is inside the iframe!!!
				if (!isMobileDevice()) {
          text.removeClass('linked');
        }

				// Enable editorial state buttons
				publishRadios.find(' input:radio').removeAttr('disabled');
			}


			/*
       * Handles the event of writing new content in one of the fields
       * (in the case, has to unlink a previously unlinked statement).
       */
			function handleContentChange() {

				// Title
				title.bind('keypress', function(){
					if (statementLinked.val()) {
						  if (title.val() != linkedTitle) {
							 unlinkStatement();
							}
            }
				});

				// Text
				if (text && text.is('textarea')) {
		      text.bind('keypress', function(){
						if (statementLinked.val()) {
							if (text.val() != linkedText) {
						  	unlinkStatement();
						  }
						}
					});
				} else {
					text.bind('DOMSubtreeModified', function() {
						if (statementLinked.val() && text && text.html().length > 0) {
							unlinkStatement();
						}
					});
				}

				// Tags
				form.bind('tagremoved', function(event, tag) {
					if (statementLinked.val()) {
						if ($.inArray(tag, linkedTags) != -1) {
							unlinkStatement();
						}
					}
				});

        // Unlink event to be fired by the embeddable part and cathed again here
        if (form.hasClass('embeddable')) {
					form.data('embeddableApi').handleContentChange('unlink');
				}
				form.bind('unlink', function() {
					if (statementLinked.val()) {
						unlinkStatement();
		      }
				});
			}


			// Public API functions
			$.extend(this,
      {
        reinitialise: function() {
          initialise();
        }
			});

		}
  };

})(jQuery);