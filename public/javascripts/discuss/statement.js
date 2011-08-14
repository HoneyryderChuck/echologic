(function($) {

  $.fn.statement = function(currentSettings) {

    $.fn.statement.defaults = {
      'level' : 0,
			'insertStatement' : true,
			'load' : true,
      'echoableClass' : 'echoable',
      'hide_animation_params' : {
        'height' : 'hide',
        'opacity': 'hide'
      },
      'hide_animation_speed': 500,
      'animation_speed': 300,
      'embed_delay': 2000,
      'embed_speed': 500,
      'scroll_speed': 500
    };

    // Merging settings with defaults
    var settings = $.extend({}, $.fn.statement.defaults, currentSettings);

    return this.each(function() {
			// Creating and binding the statement API
			var elem = $(this);
      var statementApi = elem.data('api');
	    if (statementApi) {
	      statementApi.reinitialise(currentSettings);
	    } else {
				statementApi = new Statement(elem);
	      elem.data('api', statementApi);
	    }
		});


    /*************************/
    /* The statement handler */
    /*************************/

    function Statement(statement) {
      var domId = statement.attr('id');
			var domParent = statement.attr('dom-parent');
			var statementType = statement.attr('id').match("new") ? $.trim(statement.find('input#type').val()) :
                                                              $.trim(domId.match(/[^(add_|new_)]\w+[^_\d+]/));
      var statementId = getStatementId(domId);
			var parentStatement, statementLevel;
			var statementUrl;
			var embedPlaceholder = statement.find('.embed_placeholder');

      // Initialize the statement
      initialise();

      // Initializes the statement.
      function initialise() {

        // A new statement is loaded for the first time
        if (settings['load']) {
					insertStatement();

          // Initialise the level and the parent of the current statement
          statementLevel = $('#statements .statement').index(statement);
					parentStatement = statement.prev();

					// Navigation through siblings
	        storeSiblings();
					initNavigationButton(statement.find(".header a.prev"), -1); /* Prev */
	        initNavigationButton(statement.find(".header a.next"),  1); /* Next */
				}

        // echo mechanism
        if (isEchoable()) {
          statement.echoable();
        }

        /* Statement form and statement show */
        if(statement.is('form')) {
					statement.statementForm();
        } else {
					statementUrl = statement.find('.header_link a.statement_link').attr('href');

          // Action menus
					initNewStatementButton();
					initEmbedButton();
					initCopyURLButton();

          // Navigation
          initExpandables();
          initChildrenTabbars();
          initMoreButton();

          // Links
          initContentLinks();
          initAllStatementLinks();

          // Embedded content
					if (hasEmbeddableContent()) {
						initEmbeddedContent();
					}
        }
      }


      /*
       * Returns true if the statement is echoable.
       */
      function isEchoable() {
        return statement.hasClass(settings['echoableClass']);
      }

      /*
       * Returns true if the statement has embeddable content (currently true for Background Infos).
       */
      function hasEmbeddableContent() {
        return embedPlaceholder.length > 0;
      }


      /******************/
      /* Stack handling */
      /******************/

      /*
		   * Gets the siblings of the statement and stores them in the client for navigation.
		   */
		  function storeSiblings() {
		    var siblings = eval(statement.data("siblings"));
        if (!siblings) {return;}

        // Siblings were transferred to the client with the currently loaded statement
        var key;
        if (statementLevel > 0) {
          // Store siblings with the parent node id
          var index = statementLevel-1;
          key = $('#statements .statement:eq(' + index + ')').attr('id');
        } else {
          // No parent means it's a root node => store siblings under the key 'roots'
          key = 'roots';
        }

        $("#statements").data(key, siblings);
        statement.removeAttr("data-siblings");
		  }


		  /*
		   * Generates the links for the prev/next buttons according to the siblings stored in the session.
		   * Navigation is circular.
		   *
		   * button: the prev or next button
		   * inc: the statement index relative to the current statement (-1 for prev, 1 for next)
		   */
		  function initNavigationButton(button, inc) {
		    if (!button || button.length == 0) {return;}
				if (button.attr('href').length == 0) {
					button.attr('href', window.location.pathname);
				}

        // Get statement node id to link to
				var currentStatementId = button.attr('data-id');
		    if (currentStatementId.match('add')) {
		      var idParts = currentStatementId.split('_');
		      currentStatementId = [];
		      // Get parent id
          if(idParts[0].match(/\d+/)) {
            currentStatementId.push(idParts.shift());
          }
		      // Get 'add'
          currentStatementId.push(idParts.shift());
		      currentStatementId.push(idParts.join('_'));
          currentStatementId = "/"+currentStatementId.join('/');
		    } else {
          currentStatementId = eval(currentStatementId);
        }

		    // Get parent element (statement)
		    var parent = statement.prev();
		    // Get id where the current node's siblings are stored
        var parentPath, siblingsKey;
		    if (parent.length > 0) {
		      parentPath = siblingsKey = parent.attr('id');
		    } else {
		      siblingsKey = 'roots';
		      parentPath = '';
		    }

		    // Get siblings ids
		    var siblingIds = $("div#statements").data(siblingsKey);
				// Get index of the prev/next sibling
				var targetIndex = ($.inArray(currentStatementId,siblingIds) + inc + siblingIds.length) % siblingIds.length;
		    var targetStatementId = new String(siblingIds[targetIndex]);
				if (targetStatementId.match('add')) {
          // Add (teaser) link
					button.attr('href', button.attr('href').replace(/statement\/.*/, "statement" + targetStatementId));
		    }
		    else {
					button.attr('href', button.attr('href').replace(/statement\/.*/, "statement/" + targetStatementId));
		    }

		    button.removeAttr('data-id');
		  }


      /*
       * Called if the newly added statement might influance the stack (new level or removing some deeper levels).
       */
			function insertStatement() {
				if (!settings['insertStatement']) {return;}

				collapseStatements();

        var element = $('div#statements .statement').eq(settings['level']);
				if(element.length > 0) {
					// if statement this statement is going to replace is from a different type
					if (domId.match('new') && element.data('api').getType() != statementType) {
						if (domParent && domParent.length > 0) {
							var key = $.inArray(domParent.substring(0,2),['ds','sr']) == -1 ?
							          $("#statements div#" + domParent).data('api').getBreadcrumbKey() :
												domParent.substring(0,2);
							var parentBreadcrumb = $("#breadcrumbs").data('breadcrumbApi').getBreadcrumb(key);
							if (parentBreadcrumb.length > 0) {
								parentBreadcrumb.nextAll().remove();
							}
						}
						else {
							element.data('api').deleteBreadcrumb();
						}
				  }
          element.replaceWith(statement);
        }
        else
        {
          $('div#statements').append(statement);
        }
			}


      /*
		   * Collapses all visible statements to focus on the one appearing on new level.
		   */
		  function collapseStatements() {
				$('#statements .statement .header:Event(!click)').expandable();
				$('#statements .statement .header').removeClass('active').addClass('expandable');
		    $('#statements .statement .content').animate(settings['hide_animation_params'],
                                                     settings['hide_animation_speed']);
		    $('#statements .statement .header .supporters_label').animate(settings['hide_animation_params'],
                                                                      settings['hide_animation_speed']);
		  }


      /**************************/
      /* Action panel functions */
      /**************************/

      /*
		   * Initializes the button for the New Statement function in the action panel.
		   */
		  function initNewStatementButton() {
		    statement.find(".action_bar .new_statement_button").bind("click", function() {
					$(this).next().animate({'opacity' : 'toggle'}, settings['animation_speed']);
		      return false;

		    });
		    statement.find(".action_bar .add_new_panel").bind("mouseleave", function() {
		      $(this).fadeOut();
          return false;
		    });
		  }


      /*
       * Initializes the Embed echo button and panel.
       */
      function initEmbedButton() {
        var embed_code = statement.find('.action_bar .embed_code');
        statement.find('.action_bar a.embed_button').bind("click", function() {
          $(this).next().animate({'opacity' : 'toggle'}, settings['animation_speed']);
          embed_code.selText();
          return false;
        });
        statement.find('.action_bar .embed_panel').bind("mouseleave", function() {
          $(this).fadeOut();
          return false;
        });
      }


      /*
       * Initializes the button for the Copy URL function in the action panel.
       */
	    function initCopyURLButton() {
				var statement_url = statement.find('.action_bar .statement_url');
				statement.find('.action_bar a.copy_url_button').bind("click", function() {
          $(this).next().animate({'opacity' : 'toggle'}, settings['animation_speed']);
					statement_url.selText();
          return false;
        });
				statement.find('.action_bar .copy_url_panel').bind("mouseleave", function() {
          $(this).fadeOut();
          return false;
        });
			}


      /**************/
      /* Navigation */
      /**************/

      /*
       * Initializes all expandable/collapsable elements.
       */
      function initExpandables() {
				statement.find(".expandable:Event(!click)").each(function() {
          var expandableElement = $(this);
					if (expandableElement.hasClass('social_echo_button')) {
						// Social Widget button
            expandableElement.expandable({
              'condition_element': expandableElement.parent().prev(),
							'condition_class': 'supported',
							'animation_params': {
                'opacity': 'toggle'
              }
            });
					}
					else if (expandableElement.hasClass('show_siblings_button')) {
            // Siblings button
				  	expandableElement.expandable({
				  		'animation_params': {
				  			'opacity': 'toggle'
				  		}
				  	});
				  } else if (expandableElement.hasClass('header')) {
            // Title "button" in header
						expandableElement.expandable({
              'loading_class': '.header_buttons .loading'
            });
					} else {
            // Children container
				  	expandableElement.expandable();
				  }
			  });
			}


			/*
       * Handles the children tabbar header their tabs and their content panels.
       */
      function initChildrenTabbars() {
				statement.find(".children").each(function(){
					var container = $(this);
					var tabbar = container.find('.headline');
					var loading = tabbar.find('.loading');
					var childrenContent = container.find('.children_content');

				  container.find("a.child_header").bind('click', function(){
						var oldTab = container.find('a.child_header.selected');
						var newTab = $(this);
            var oldChildrenPanel = childrenContent.find('div.' + oldTab.attr('type'));
						var newChildrenPanel = childrenContent.find('div.' + newTab.attr('type'));

            // Switching tabs
            var tabbarVisible = childrenContent.is(":visible");
            if (newChildrenPanel.length > 0) {
							if (!newChildrenPanel.is(':visible')) {
                switchTabs(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, tabbarVisible);
              }
						} else {
							var path = newTab.attr('href');
							loading.show();
							$.ajax({
				        url:      path,
				        type:     'get',
				        dataType: 'script',
								success: function(data, status) {
									newChildrenPanel = childrenContent.find('.children_container:first');
									if (!newChildrenPanel.is(':visible')) {
		                switchTabs(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, tabbarVisible);
										loading.hide();
		              }
								},
								error: function() {
									loading.hide();
								}
				      });
						}
            // Expanding the content if the headline is closed
            if (!tabbarVisible) { tabbar.data('expandableApi').toggle(); }
						return false;
					});
				});
			}


      /*
       * Switches the tabs in the Children Tabbars.
       */
      function switchTabs(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, animate) {
        oldTab.removeClass('selected');
        newTab.addClass('selected');
        oldChildrenPanel.hide();
        if (animate) {
          newChildrenPanel.fadeIn(settings['animation_speed']);
          childrenContent.height(oldChildrenPanel.height()).
            animate({'height': newChildrenPanel.height()}, settings['animation_speed'], function() {
              childrenContent.removeAttr('style');
            });
        } else {
          newChildrenPanel.show();
        }
      }


		  /*
		   * Handles the click on the more Button event (replaces it with an element of class 'more_loading')
		   */
		  function initMoreButton() {
				initContainerMoreButton(statement);
		  }


      /*
       * Initializes the More button for children/sibling/etc. or all containers in the statement.
       */
			function initContainerMoreButton(container) {
				container.find(".more_pagination a:Event(!click)").bind("click", function() {
          var moreButton = $(this);
					var moreLoading = $('<span/>').text(moreButton.text()).addClass('more_loading');
					moreButton.hide();
					moreLoading.insertAfter(moreButton);
          var path = moreButton.attr('href');
					$.ajax({
				  	url: path,
				  	type: 'get',
				  	dataType: 'script',
				  	success: function(data, status){
							moreButton.remove();
				  	},
				  	error: function(){
				  	 moreLoading.remove();
						 moreButton.show();
				  	}
				  });
					return false;
		    });
			}


      /*
       * Reinitializes the children.
       */
      function reinitialiseChildren(childrenContainerSelector) {
				var container = statement.find(childrenContainerSelector);
        initContainerMoreButton(container);
        initChildrenLinks(container);
        if (isEchoable) {
          statement.data('echoableApi').loadRatioBars(container);
        }
			}


      /*
       * Reinitializes the siblings.
       */
			function reinitialiseSiblings(siblingsContainerSelector) {
	      var container = statement.find(siblingsContainerSelector);
        initContainerMoreButton(container);
        initSiblingsLinks(container);
        if (isEchoable) {
          statement.data('echoableApi').loadRatioBars(container);
        }
	    }


      /******************/
      /* Handling Links */
      /******************/

      /*
       * Initilizes all external URLs and internal echo links in the statement content (text) area.
       */
      function initContentLinks() {
        statement.find(".statement_content a:not(.upload_link)").each(function() {
          var link = $(this);

          var url = link.attr("href");
          if (url.substring(0,7) != "http://" && url.substring(0,8) != "https://") {
            url =  "http://" + url;
          }
					if (isEchoStatementUrl(url)) { // if this link goes to another echo statement => add a jump bid
						initJumpLink(link,url);
					} else {
            link.attr("target", "_blank");
          }
          link.attr('href', url);
        });
      }


      /*
       * Initiates a link for the statement with the dorrect breadcrumbs and a new JUMP breadcrumb in the end.
       */
      function initJumpLink(link, url) {
				var anchor_index = url.indexOf("#");
        if (anchor_index != -1) {
          url = url.substring(0, anchor_index);
        }

        link.bind("click", function() {
				  $.getJSON(url+'/ancestors', function(data) {
            var sids = data['sids'];
					  var bids = data['bids'];
						var targetBids = getTargetBids(getParentKey());

						// if the jump link is for a statement on the same stack, delete those bids
						// as they are going to be introduced anyway by the bids parameter
						if (bids.length > 0) {
							var index;
							if ((index = $.inArray(bids[0], targetBids)) != -1) {
								targetBids = targetBids.splice(0, index);
							}
						}
            var bid = 'jp' + statementId;
						targetBids.push(bid);
						$.merge(targetBids, bids);

						$.setFragment({
              "bids": targetBids.join(","),
              "sids": sids.join(","),
              "nl": true,
              "origin": bid
            });

					});
          return false;
				});
			}


      /*
		   * Sets the different links on the statement UI, after the user clicked on them.
		   */
      function getTargetBids(key) {
        var currentBids = $('#breadcrumbs').data('breadcrumbApi').getBreadcrumbStack(null);
        var targetBids = currentBids;

        var index = $.inArray(key, targetBids);
        if (index != -1) { // if parent breadcrumb exists, then delete everything after it
          targetBids = targetBids.splice(0, index + 1);
        } else { // if parent breadcrumb doesn't exist, it means top stack statement
          targetBids = targetBids.splice(0, currentBids.length - currentBids.length % 3);
        }
        return targetBids;
      }


      /*
       * Initializes all statement link apart from the inline content (jump) links handled separately.
       */
      function initAllStatementLinks() {
        statement.find('.header a.statement_link').bind("click", function() {

					var currentStack = $.fragment().sids;
		      var targetStack = getStatementsStack(this, false);

          var parentKey = getParentKey();
          var targetBids = getTargetBids(parentKey);

          // save element after which the breadcrumbs will be deleted while processing the response
          $('#breadcrumbs').data('element_clicked', parentKey);

					var origin = $.fragment().origin;

		      $.setFragment({
		        "sids": targetStack.join(','),
		        "nl": '',
						"bids": targetBids.join(','),
						"origin": origin
		      });

					var nextStatement = statement.next();
					var triggerRequest = (nextStatement.length > 0 && nextStatement.is("form"));

					if (triggerRequest || targetStack.join(',') != currentStack) {
            statement.find('.header .loading').show();
          }

					// if this is the parent of a form, then it must be triggered a request to render it
          if (triggerRequest) {
            $(document).trigger("fragmentChange.sids");
          }

		      return false;
		    });

	      statement.find('.alternatives').each(function(){
					initSiblingsLinks($(this));
				});
        statement.find('.children').each(function() {
					initChildrenLinks($(this));
				});

				// All form requests must nullify the new_level, so that when one clicks the parent button
				// it triggers one request instead of two.
				statement.find('.add_new_button').each(function() {
					$(this).bind('click', function(){
						$.setFragment({
							"nl" : ''
						});
					});
				})
		  }


      /*
       * Initializes links for all statements but Follow-up Questions.
       * new_level = false
       */
      function initSiblingsLinks(container) {
        initStatementLinks(container, false)
	    }


      /*
       * Initializes links for all statements but Follow-up Questions.
       * new_level = true
       */
			function initChildrenLinks(container) {
        initStatementLinks(container, true)
			}


      /*
       * Initializes links for all statements but Follow-up Questions.
       */
      function initStatementLinks(container, newLevel) {
				container.find('a.statement_link').bind("click", function() {
					var current_stack = getStatementsStack(null, newLevel);
					var childId = $(this).parent().attr('statement-id');
					var key = getTypeKey($(this).parent().attr('class'));
					var bids = $('#breadcrumbs').data('breadcrumbApi').getBreadcrumbStack(null);

          if(newLevel){ // necessary evil: erase all breadcrumbs after the parent of the clicked statement
            var or_index = bids.length == 0 ? 0 : $.inArray($.fragment().origin, bids);
            var level = or_index + (statementLevel+1);
            bids = bids.splice(0, level);
            var new_bid = key + statementId;
            bids.push(new_bid);
          }
					else { // siblings box or maybe alternatives box
						var parentKey = getParentKey();
						var index = $.inArray(parentKey, bids);
	          if (index != -1) { // if parent breadcrumb exists, then delete everything after it
	            bids = bids.splice(0, index + 1);
	          }
					}
					var stack = current_stack, origin;
          switch(key){
						case 'fq':
						  stack = [childId];
							origin = bids.length == 0 ? '' : bids[bids.length - 1];
						  break;
						default :
						  stack.push(childId);
							origin = $.fragment().origin;
						  break;
					}

          $('#breadcrumbs').data('element_clicked', getParentKey());

          $.setFragment({
            "sids": stack.join(','),
            "nl": newLevel ? newLevel : '',
						"bids": bids.join(','),
						"origin": origin
          });
          return false;
        });
      }


      /*
       * Generates a bid for the parent statement.
       */
      function getParentKey() {
				if (parentStatement.length > 0) {
          return getTypeKey(statementType) + getStatementId(parentStatement.attr('id'));
        } else {
          return $.fragment().origin;
        }
			}


		  /*
		   * Returns an array of statement ids that should be loaded to the stack after 'statementLink' was clicked
		   * (and a new statement is loaded).
		   *
		   * - statementLink: HTML element that was clicked
		   * - newLevel: true or false (child statement link)
		   */
		  function getStatementsStack(statementLink, newLevel) {
				if (statementLink) {
					// Get soon to be visible statement
					var path = statementLink.href.split("/");
					var id = path.pop().split('?').shift();

					var current_sids;
					if (id.match(/\d+/)) {
						current_sids = id;
					}
					else {
						// Add teaser case
						// When there's a parent id attached, copy :id/add/:type, or else, just copy the add/:type
						var index_backwards = path[path.length - 2].match(/\d+/) ? 2 : 1;
						current_sids = path.splice(path.length - index_backwards, 2);
						current_sids.push(id);
						current_sids = current_sids.join('/');
					}
		    }

        // Get current_stack of visible statements (if any matches the clicked statement, then break)
				var current_stack = [];
		    $("#statements .statement").each( function(index){
		      if (index < statementLevel) {
		        id = $(this).attr('id').split('_').pop();
		        if(id.match("add")){
		          id = "add/" + id;
		        }
		        current_stack.push(id);
		      } else if (index == statementLevel) {
		         if (newLevel) {
		          current_stack.push($(this).attr('id').split('_').pop());
		         }
		        }
		    });
		    // Insert clicked statement
				if (current_sids) {
					current_stack.push(current_sids);
				}
				return current_stack;
		  }


			/*****************************/
			/* Embedded external content */
			/*****************************/

			function initEmbeddedContent() {
		  	embedPlaceholder.embedly({
          key: 'ccb0f6aaad5111e0a7ce4040d3dc5c07',
          maxWidth: 990,
          maxHeight: 1000,
          className: 'embedded_content',
          success: embedlyEmbed,
					error: manualEmbed
		  	});
		  }

      function embedlyEmbed(oembed, dict) {
        var elem = $(dict.node);
        if (! (oembed) ) { return null; }
        if (oembed.type != 'link') {
          elem.replaceWith(oembed.code);
          showEmbeddedContent();
        } else {
          manualEmbed(embedPlaceholder, null);
        }
      }

      function manualEmbed(node, dict) {
        node.replaceWith($("<div/>").addClass('embedded_content').addClass('manual')
                           .append($("<iframe/>").attr('frameborder', 0).attr('src', node.attr('href'))));
        showEmbeddedContent();
      }

      function showEmbeddedContent() {
        setTimeout(function() {
          statement.find('.embed_container .loading').hide();
          statement.find('.embedded_content').fadeIn(settings['embed_speed']);
          //$.scrollTo(statement, settings['scroll_speed']);
        }, settings['embed_delay']);
      }


      /***************************/
      /* Public API of statement */
      /***************************/

      $.extend(this,
      {
        reinitialise: function(resettings) {
          settings = $.extend({}, resettings, settings, {'load' : false});
          initialise();
        },

        reinitialiseContainerBlock: function(containerSelector, newLevel) {
					newLevel ? reinitialiseChildren(containerSelector) : reinitialiseSiblings(containerSelector);
				},

				reinitialiseChildren: function(childrenContainerSelector) {
					reinitialiseChildren(siblingsContainerSelector);
				},

				reinitialiseSiblings: function(siblingsContainerSelector) {
          reinitialiseSiblings(siblingsContainerSelector);
        },

        insertContent: function(content) {
          statement.append(content);
          return this;
        },

		    removeBelow: function(){
		     statement.nextAll().each(function() {
			     // Delete the session data relative to this statement first
					 /*if (domId.match('new')) {
				   	$(this).data('api').deleteBreadcrumb();
				   }*/
			     $('div#statements').removeData(this.id);
			     $(this).remove();

		     });
				 return this;
		    },

				getBreadcrumbKey: function() {
					return getParentKey();
				},

				deleteBreadcrumb: function() {
					var key = getParentKey();
				  $('#breadcrumbs').data('breadcrumbApi').deleteBreadcrumb(key);
				},

        insert: function() {
		      var element = $('div#statements .statement').eq(settings['level']);
		      if(element.length > 0) {
		        element.replaceWith(statement);
		      } else {
		        collapseStatements();
		        $('div#statements').append(statement);
		      }
					return this;
		    },

		    loadAuthors: function (authors) {
		      authors.insertAfter(statement.find('.summary h2')).animate(toggleParams, settings['animation_speed']);
					var length = authors.find('.author').length;
		      statement.find('.authors_list').jcarousel({
		        scroll: 3,
		        buttonNextHTML: "<div class='next_button'></div>",
		        buttonPrevHTML: "<div class='prev_button'></div>",
		        size: length
		      });
					return this;
		    },

		    insertMore: function (level, type_id) {
		      var element = $('#statements div.statement:eq(' + level + ') ' + type_id + ' .headline');
		      statement.insertAfter(element).animate(toggleParams, settings['animation_speed']);
					return this;
		    },

		    show: function() {
		      statement.find('.content').animate(toggleParams, settings['animation_speed']);
					return this;
		    },

		    hide: function () {
		      statement.find('.header').removeClass('active').addClass('expandable');
		      statement.find('.content').hide('slow');
		      statement.find('.supporters_label').hide();
					return this;
		    },
        loadRatioBars: function(container) {
          statement.data('echoableApi').loadRatioBars(container);
					return this;
        },

				getType: function() {
					return statementType;
				}
      });
	  }

  };

})(jQuery);


