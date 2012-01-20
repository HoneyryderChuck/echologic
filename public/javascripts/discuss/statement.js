(function( $ ) {
	$.widget("echo.statement", {
		options: {
			/**
			 * level at which the statement is placed
			 */
			level : 0,
			/**
			 * tells whether this statement is supposed to be inserted
			 */
	  		insertStatement : true,
	  		load : true,
	   		expand  : false,
	   		message: null,
	   		
       		echoableClass  :  'echoable',
       		
       		// animation metrics
       		hide_animation_params  : {
         		height  : 'hide',
         		opacity : 'hide'
      		},
       		hide_animation_speed : 500,
       		animation_speed : 300,
       		embed_delay : 2000,
       		embed_speed : 500,
       		scroll_speed : 500,
			
			// Children Container Helpers
			childrenPerPage  : 7,
		 	maxPage  : {
		 		animate  : {
			 		single  : 7,
			 		dual  	: 5 
				},
		 		single  : 10,
	 			dual	: 7
			},
 			maxHeight  : {
	 			animate  : {
		 			single  : 203,
		 			dual  	: 225
				},
	 			single  : 290,
	 			dual  	: 314
			},
 			childHeight  : {
	 			single  : 29,
	 			dual  	: 44
			}
		}, 
		/*
		 * constructor method
		 */		
		_create: function() {
			var that = this;
			var statement = that.element;
			that.domId = statement.attr('id');
			that.domParent = statement.attr('dom-parent');
			that.parentId = that.domParent? that.domParent.replace(/[^0-9]+/, '') : '';
			that.statementType = that.domId.match("new") ? $.trim(statement.find('input#type').val()) : $.trim(that.domId.match(/[^(add_|new_)]\w+[^_\d+]/)[0]); 
			that.statementId = that.domId.replace(/[^0-9]+/, '');
			that.statementTypeKey = that._getTypeKey(that.statementType);
			
			
			that.embedPlaceholder = statement.find('.embed_placeholder');
			that.siblingsButton = statement.find('.show_siblings_button');
			that.isEchoable = statement.hasClass(that.options.echoableClass);
			that.hasEmbeddableContent = that.embedPlaceholder.length;
			that.breadcrumbApi = $('#breadcrumbs').data('breadcrumbApi');
			that.refresh();
			
			statement.removeAttr('dom-parent');
		},
		/*
		 * reinitialises the widget for the current statement
		 */
		refresh: function() {
			var that = this;
			var statement = that.element;
        	// A new statement is loaded for the first time
        	if (that.options.load) {
		  		that._insertStatement();

          		// Initialise the level and the parent of the current statement
          		that.statementLevel = $('#statements .statement').index(statement);
		  		that.parentStatement = statement.prev();

				// Navigation through siblings
	        	that._storeSiblings();
				that._loadSiblings();
				that._initNavigationButton(statement.find(".header a.prev"), -1); // Prev 
	        	that._initNavigationButton(statement.find(".header a.next"),  1); // Next 
			     
				that._loadMessage(that.options.message);
				delete that.options.message;
			}

        	// echo mechanism
        	if (that.isEchoable) statement.echoable();

        	// Statement form and statement show 
        	if(statement.is('form'))
				statement.statementForm();
        	else
				that.statementUrl = $.trim(statement.find('.statement_url').text());

          	// Action menus
			that._initNewStatementButton();
			that._initEmbedButton();
			that._initCopyURLButton();

          	// Navigation
          	that._initExpandables();
          	that._initChildrenTabbars();
          	that._initMoreButton();

          	// Links
          	that._initContentLinks();
          	that._initAllStatementLinks();
	        that._initAllNewStatementFormLinks();
					
          	// Embedded content
			if (that.hasEmbeddableContent) that._initEmbeddedContent();
       },
       
       // inserts this statement in the statements stack where it should show up
       _insertStatement: function() {
       		var that = this;
	   		if (!that.options.insertStatement) {return;}
	   		var statement = that.element;
	   		
		 	if (!that.options.expand) that._collapseStatements();
		 
		 	var element = $('#statements .statement').eq(that.options.level);

		 	// if the statement is going to replace a statement already existing in the stack
		 	if(element.length > 0) {
				// if statement this statement is going to replace is from a different type
				if (that.domId.match('new') && element.data('echo.statement').getType() != that.statementType)
					if (that.domParent && that.domParent.length > 0) {	
						var key = $.inArray(domParent.substring(0,2),['ds','sr']) == -1 ?
					          	  $("#" + domParent).data('echo.statement').getBreadcrumbKey() :
								  domParent.substring(0,2);
						var parentBreadcrumb = that.breadcrumbApi.getBreadcrumb(key);
						if (parentBreadcrumb.length > 0) {
							parentBreadcrumb.nextAll().remove();
						}
					} else
						element.data('statement').deleteBreadcrumb();

		  		if (!that.options.expand) 
		  			statement.find('.content').show();
	      	 	element.replaceWith(statement);
    		} 
    		else // no statement on this level of the stack, so insert at the bottom
		    {
			  $('#statements').append(statement);
			  that._showAnimated();
		    }
		        
			if (that.options.expand) {
				that._showAnimated();
				that.reinitialise();
			}
			else 
				that._removeBelow();
		},
		// Collapses all visible statements to focus on the one appearing on new level.
		_collapseStatements: function() {
			var that = this;
			$('#statements .statement .header:Event(!click)').expandable();
			$('#statements .statement .header').removeClass('active').addClass('expandable');
		    $('#statements .statement .content').animate(that.options.hide_animation_params, that.options.hide_animation_speed);
		    $('#statements .statement .header .supporters_label').animate(that.options.hide_animation_params, that.options.hide_animation_speed);
		},
		_showAnimated: function() {
			var that = this,
				statement = that.element;
			var content = statement.find('.content');
			if (!content.is(':visible')) 
				content.animate(toggleParams, that.options.animation_speed);
		},
		// Removes the statements from the lower levels of this statement's stack
		_removeBelow: function() {
	  	 this.element.nextAll().each(function(){
	  		  	// Delete the session data relative to this statement first
				$('#statements').removeData(this.id);
				$(this).remove();
			});
		},
		// Gets the siblings of the statement and stores them in the client for navigation.
		_storeSiblings: function() {
			var that = this,
				statement = that.element,
				siblings = statement.data("siblings");
				
        	if (!siblings) {return;}
	
        	// Siblings were transferred to the client with the currently loaded statement
        	var key = that.statementLevel > 0 ?
	          		  // Store siblings with the parent node id
	          		  $('#statements .statement:eq(' + (that.statementLevel-1) + ')').attr('id') : 
	          		  // No parent means it's a root node => store siblings under the key 'roots'
	          		  'roots';

        	$("#statements").data(key, siblings);
        	statement.removeData("siblings");
		},
		// Loads the siblings from the current statement being loaded.
		_loadSiblings: function() {
			var that = this,
				statement = that.element;
				parent = statement.prev();
        	// Get id where the current node's siblings are stored
        	
        	var siblingsKey = parent.length > 0 ? parent.attr('id') : 'roots';

        	// Get siblings ids
        	that.statementSiblings = $("div#statements").data(siblingsKey);
		},
		/**
		 * Generates the links for the prev/next buttons according to the siblings stored in the session.
	   	 * Navigation is circular.
	   	 *
	   	 * @param {jQuery} button the prev or next button
	   	 * @param {Number} inc the statement index relative to the current statement (-1 for prev, 1 for next) 
		 */
		_initNavigationButton: function(button, inc) {
			if (!button || button.length == 0) {return;}
			
			var that = this,
				statement = that.element;
		    // default
			if (button.attr('href').length == 0) button.attr('href', window.location.pathname);

        	// Get statement node id to link to
			var currentStatementId = button.data('id');
			
			
		    if (typeof(currentStatementId)=='string' && currentStatementId.match('add')) {
		    	var m = /(\d+)?_?add_([a-z_]+)/.exec(currentStatementId);
		      	currentStatementId = (!m[1] ? '' : m[1] + "/")  + "add/" + m[2];
		    }

			// Get index of the prev/next sibling
			var targetIndex = ($.inArray(currentStatementId, that.statementSiblings) + inc + that.statementSiblings.length) % that.statementSiblings.length;
		    var targetStatementId = that.statementSiblings[targetIndex];
			var buttonUrl = button.attr('href').replace(/statement\/.*/, "statement/" + targetStatementId);

        	button.attr('href', buttonUrl);

			if ($.fragment().al && $.fragment().al.length > 0)
				button.attr('al', $.fragment().al);
		    button.removeData('id');
		},
		// Initializes the button for the New Statement function in the action panel.
		_initNewStatementButton: function() {
			var that = this;
			var statement = that.element;
		    statement.find(".action_bar .new_statement_button").bind("click", function(e) { 
		    	e.preventDefault(); 
		    	$(this).next().animate({'opacity' : 'toggle'}, that.options.animation_speed); 
		    });
		    statement.find(".action_bar .add_new_panel").bind("mouseleave", function() { $(this).fadeOut(); });
		},
		// Initializes the Embed echo button and panel.
      	_initEmbedButton: function() {
      		var that = this;
      		var statement = that.element;
        	var embed_code = statement.find('.action_bar .embed_code');
        	statement.find('.action_bar .embed_button').bind("click", function(e) {
        		e.preventDefault();
          		$(this).next().animate({'opacity' : 'toggle'}, that.options.animation_speed);
          		embed_code.selText();
        	});
        	statement.find('.action_bar .embed_panel').bind("mouseleave", function() { $(this).fadeOut(); });
        },
        // Initializes the button for the Copy URL function in the action panel.
	    _initCopyURLButton: function() {
	    	var that = this;
	    	var statement = that.element;
			var statement_url = statement.find('.action_bar .statement_url');
			statement.find('.action_bar a.copy_url_button').bind("click", function(e) {
				e.preventDefault();
          		$(this).next().animate({'opacity' : 'toggle'}, that.options.animation_speed);
				statement_url.selText();
        	});
			statement.find('.action_bar .copy_url_panel').bind("mouseleave", function() { $(this).fadeOut(); });
		},
		// Initializes all expandable/collapsable elements.
        _initExpandables: function() {
			this.element.find(".expandable:Event(!click)").each(function() {
          		var expandableElement = $(this);
          		var vars = expandableElement.hasClass('social_echo_button') ? 
        			{ // Social Widget button
		            	'condition_element': expandableElement.parent().prev(),
						'condition_class': 'supported',
						'animation_params': {
			                'opacity': 'toggle'
			              }
		            } : expandableElement.hasClass('show_siblings_button') ?
		            {  // Siblings button
		            	'animation_params': { 
		            		'opacity': 'toggle' 
		            	} 
		            } : expandableElement.hasClass('header') ?
		            { 'loading_class': '.header_buttons .loading' } // Title "button" in header
		            : {}; // Children container
		    	expandableElement.expandable(vars);
			});
		},
		// Handles the children tabbar header their tabs and their content panels.
      	_initChildrenTabbars: function() {
      		var that = this;
			that.element.find(".children").each(function(){
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
            		if (newChildrenPanel.length > 0)
							if (!newChildrenPanel.is(':visible'))
                			that._switchTabs(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, tabbarVisible);
					else {
						loading.show();
						$.ajax({
				        	url:      newTab.attr('href'),
				        	type:     'get',
				        	dataType: 'script',
							success: function(data, status) {
								newChildrenPanel = childrenContent.find('.children_container:first');
								if (!newChildrenPanel.is(':visible')) {
		                			that._switchTabs(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, tabbarVisible);
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
		},
		// Switches the tabs in the Children Tabbars.
        _switchTabs: function(oldTab, newTab, childrenContent, oldChildrenPanel, newChildrenPanel, animate) {
        	var that = this;
        	oldTab.removeClass('selected');
        	newTab.addClass('selected');
        	oldChildrenPanel.hide();
        	if (animate) {
          		newChildrenPanel.fadeIn(that.options.animation_speed);
          		childrenContent.height(oldChildrenPanel.height()).
            	animate({'height': newChildrenPanel.height()}, that.options.animation_speed, function() {
              		childrenContent.removeAttr('style');
            	});
        	} else
          		newChildrenPanel.show();
      	},
      	// Handles the click on the more Button event (replaces it with an element of class 'more_loading')
		_initMoreButton: function() {
			var that = this;
			that._initContainerMoreButton(that.element);
		},
		//Initializes the More button for children/sibling/etc. or all containers in the statement.
		_initContainerMoreButton: function(container) {
			var that = this;
			// Get total children per column (for doubles, get the max of both columns)
			var totalChildren = container.find('.children_list').map(function(){ return $(this).data('total-elements'); }).get();
        	totalChildren = Math.max.apply(Math, totalChildren);
				
			var more = container.find(".more_pagination a:Event(!click)");
				
			// loading more button
			var moreLoading = $('<span class="more_loading"/>').text(more.text());
			moreLoading.hide().insertAfter(more);
				
				
				
			more.bind("click", function(e) {
				e.preventDefault();
          		var moreButton = $(this);
				moreButton.hide();
				moreButton.next().css({ 'display': 'inline' });
          		var path = moreButton.attr('href');
				$.ajax({
				  	url: path,
				  	type: 'get',
				  	dataType: 'script',
				  	success: function(data, status){
						// get longest number of children as column
						var currentChildren = container.find('.children_list').map(function(){
							return $(this).find('.statement_link').length;
						}).get();
						currentChildren = Math.max.apply(Math, currentChildren);
							
						if (totalChildren == currentChildren) {
							// if at the end, disable more button 
							 moreButton.next().removeClass('more_loading').addClass('disabled');
							 moreButton.remove();
					    }
						else {
							// update the page to load
							moreButton.next().hide();
							var currentPage = currentChildren / that.options.childrenPerPage;
						  	container.find('.children_list').data('current-page', currentPage);
							var moreUrl = moreButton.attr('href').replace(/page\=\d+/, "page="+(currentPage + 1));
							moreButton.attr('href', moreUrl);
							moreButton.show();
					    }
							
				  	},
				  	error: function(){
				  		moreButton.next().hide();
						moreButton.show();
				  	}
				});
		    });
		},
		// Returns an array of statement ids that should be loaded to the stack after a link was clicked (and a new statement is loaded).
		_getStatementsStack: function(link, newLevel) {
			var that = this;
			// Get current_stack of visible statements (if any matches the clicked statement, then break)
			var currentStack = $("#statements .statement").map( function(level){
		      	if (level < that.statementLevel || (level == that.statementLevel && newLevel))
	          		return $(this).attr('id').match(/\d+/)[0];
		    }).get();
		    if (link) {
				// Get soon to be visible statement id
				var idRegexp = /statement\/(.*)/;
				var match = idRegexp.exec(link.attr('href'));
				var currentSid = match[1];
				currentStack.push(currentSid);
		  	}
		    // Insert clicked statement
			return currentStack;
		},
		// Sets the different links on the statement UI, after the user clicked on them.
      	_getTargetBids: function(key) {
      		var that = this,
        		currentBids = that.breadcrumbApi.getBreadcrumbStack(null),
        		targetBids = currentBids;

        	var index = $.inArray(key, targetBids);
        	if (index != -1) // if parent breadcrumb exists, then delete everything after it
          		targetBids = targetBids.splice(0, index + 1);
        	else { // if parent breadcrumb doesn't exist, it means top stack statement
          		//find all origin breadcrumbs
				var originBids = getOriginKeys(currentBids);
				// get last of them, if it exists
				if (originBids.length > 0) {
					var lastOriginBid = originBids.pop();
					var index = $.inArray(lastOriginBid, currentBids);
				 	targetBids = targetBids.splice(0, index + 1);
				} else { // if it doesn't, it means there should be no breadcrumbs
					targetBids = [];
				}
        	}
        	return targetBids;
      	},
      	// Loads the new set of Als
		_getTargetAls: function(inclusive) {
			var that = this,
				al = $.fragment().al || '';
        	al = al.length > 0 ? al.split(',') : [];
        	// eliminate levels below the one we're returning to
        	al = $.grep(al, function(a){
          		return inclusive ? a <= that.statementLevel : a < that.statementLevel;
        	});
			return al;
		},
		// Initializes all statement link apart from the inline content (jump) links handled separately.
      	_initAllStatementLinks: function() {
      		var that = this,
      			statement = that.element;
      		
      		// initialise main header title link
        	statement.find('.header .main_header .statement_link').bind("click", function(e) {
        		e.preventDefault();
				var stat = $(this);
	          	// SIDS
				var currentStack = $.fragment().sids;
			    var targetStack = that._getStatementsStack(stat, false);
	
	          	// BIDS
	          	var parentKey = that._getParentKey();
	          	var targetBids = that._getTargetBids(parentKey);
	
	          	// save element after which the breadcrumbs will be deleted while processing the response
	          	$('#breadcrumbs').data('element_clicked', parentKey);
	
	          	// ORIGIN
				var origin = $.fragment().origin;
	
				// AL: get alternative level if this link is for an alternative level
				var altStack = that._getTargetAls(true);
				var statAl = stat.attr('al');
				if (statAl && $.inArray(statAl,altStack) == -1) 
					altStack.push(statAl);

		    	$.setFragment({
		        	"sids": targetStack.join(','),
		        	"nl": '',
					"bids": targetBids.join(','),
					"origin": origin,
					"al": altStack.join(',')
		      	});

				var nextStatement = statement.next();
				var triggerRequest = (nextStatement.length > 0 && nextStatement.is("form"));

				if (triggerRequest || targetStack.join(',') != currentStack)
            		statement.find('.header .loading').show();

				// if this is the parent of a form, then it must be triggered a request to render it
          		if (triggerRequest) 
            		$(document).trigger("fragmentChange.sids");
		    });

			// DAQ Link
			that._initChildrenLinks(statement.find('.header .alternative_header'));

			// initialise alternative links
	      	statement.find('.alternatives').each(function(){
				that._initSiblingsLinks($(this), { "nl": true, "al": ("al" + that.statementId) });
			});
			// initialise children links
        	statement.find('.children').each(function() {
				that._initChildrenLinks($(this));
			});

			// All form requests must nullify the new_level, so that when one clicks the parent button
			// it triggers one request instead of two.
			statement.find('.add_new_button').each(function() {
				$(this).bind('click', function(){
					$.setFragment({ "nl" : '' });
				});
			})
		},
		// Initializes links for all statements but Follow-up Questions.
		_initChildrenLinks: function(container) {
        	this._initStatementLinks(container, true)
		},
		// Initializes links for all statements but Follow-up Questions.
      	_initSiblingsLinks: function(container) {
			this._initStatementLinks(container, false, arguments[1]);
	    },
		// Initializes links for all statements but Follow-up Questions.
      	_initStatementLinks: function(container, newLevel) {
      		var that = this;
			var params = arguments[2] || {};
			container.find('a.statement_link:not(.registered)').each(function() {
				$(this).bind("click", function(e) {
					e.preventDefault();
					var stat = $(this);
					var stack = that._getStatementsStack(null, newLevel);
					var childId = stat.data('statement-id');
					var key = that._getTypeKey(stat.parent().attr('class'));
					var bids = that.breadcrumbApi.getBreadcrumbStack(null);
					var altStack = $.fragment().al || '';
					var altStack = altStack.length > 0 ? altStack.split(',') : [];
	          		var parentKey = that._getParentKey();
	          		
	          		// see if clicking this child will erase any breadcrumb
					var level = $.inArray(parentKey, bids);
					if (level != -1) // if parent breadcrumb exists, then delete everything after it
	            		bids = bids.splice(0, level+1);
	
	          		if(newLevel){ // insert new breadcrumb if this link triggers a new level in the stach
						var new_bid = key + that.statementId;
	            		bids.push(new_bid);
						altStack = $.grep(altStack, function(a) {
							return a <= statementLevel;
						});
	          		}
	
					var origin;
	          		switch(key){
						case 'fq':
						case 'dq':
							stack = [childId];
							origin = bids.length == 0 ? '' : bids[bids.length - 1];
							altStack = [];
						  	break;
						default:
						  	stack.push(childId);
							origin = $.fragment().origin;
							break;
					}
	
	          		$('#breadcrumbs').data('element_clicked', that._getParentKey());
	
					// so we have the possibility of adding possible breadcrumb entries
					if (params['al']) {
						bids.push(params['al']);
						if ($.inArray(that._statementLevel, altStack) == -1) {
							altStack.push(that._statementLevel);
						}
						params['al'] = altStack.join(',');
					}
	          		$.setFragment(
						$.extend({
		            		"sids": stack.join(','),
		            		"nl": (newLevel ? newLevel : ''),
							"bids": bids.join(','),
							"origin": origin,
							"al" : altStack.join(',')
	            		}, 
	            		params));
	        	}).addClass('registered');
	        });
     	},
     	
     	_initAllNewStatementFormLinks: function() {
			this.element.find('.new_statement').bind('click', function(e){
				e.preventDefault();
				$.getScript(this.href);
			});
		}, 
		
		_initEmbeddedContent: function() {
			var that = this;
		  	that.embedPlaceholder.embedly({
          		key: 'ccb0f6aaad5111e0a7ce4040d3dc5c07',
          		maxWidth: 990,
          		maxHeight: 1000,
          		className: 'embedded_content',
          		success: that._embedlyEmbed,
				error: that._manualEmbed
		  	});
		},
		_embedlyEmbed: function(oembed, dict) {
			var that = this,
	    		elem = $(dict.node);
	    	if (! (oembed) ) { return null; }
	        if (oembed.type != 'link') {
	        	elem.replaceWith(oembed.code);
	          	that._showEmbeddedContent();
	        } else
	          	that._manualEmbed(embedPlaceholder, null);
	    },
	    _manualEmbed: function(node, dict) {
        	node.replaceWith($("<div/>").addClass('embedded_content').addClass('manual')
                           .append($("<iframe/>").attr('frameborder', 0).attr('src', node.attr('href'))));
        	this._showEmbeddedContent();
      	},
      	_showEmbeddedContent: function() {
      		var that = this,
      			statement = that.element;
        	setTimeout(function() {
          		statement.find('.embed_container .loading').hide();
          		statement.find('.embedded_content').fadeIn(that.options.embed_speed);
          		//$.scrollTo(statement, settings['scroll_speed']);
        	}, that.options.embed_delay);
      	},
      	
		
      	// Initialises all external URLs and internal echo links in the statement content (text) area.
      	_initContentLinks: function() {
      		var that = this;
        	that.element.find(".statement_content a:not(.upload_link)").each(function() {
          		var link = $(this);

          		var url = link.attr("href");
          		if (url.substring(0,7) != "http://" && url.substring(0,8) != "https://")
            		url =  "http://" + url;
					
				if (isEchoStatementUrl(url)) // if this link goes to another echo statement => add a jump bid
					that._initJumpLink(link,url);
				else
	            	link.attr("target", "_blank");
          		link.attr('href', url);
        	});
      	},
      	// Initiates a link for the statement with the dorrect breadcrumbs and a new JUMP breadcrumb in the end.
   		_initJumpLink: function(link, url) {
			var anchor_index = url.indexOf("#");
        	if (anchor_index != -1)
	          	url = url.substring(0, anchor_index);

        	link.bind("click", function(e) {
        		e.preventDefault();
				$.getJSON(url+'/ancestors', function(data) {
	            	var sids = data['sids'],
					 	bids = data['bids'],
						targetBids = getTargetBids(getParentKey());
	
					// if the jump link is for a statement on the same stack, delete those bids
					// as they are going to be introduced anyway by the bids parameter
					if (bids.length > 0) {
						var index;
						if ((index = $.inArray(bids[0], targetBids)) != -1) 
							targetBids = targetBids.splice(0, index);
					}
	            	var bid = 'jp' + statementId;
					targetBids.push(bid);
					$.merge(targetBids, bids);
	
					$.setFragment({
	              		"bids": targetBids.join(","),
	              		"sids": sids.join(","),
	              		"nl": true,
	              		"origin": bid,
						"al" : ''
	            	});
				});
			});
		},
      	
      	
      	// Generates a bid for the parent statement.
      	_getParentKey: function() {
      		var that = this,
      			statement = that.element;
			if (that.parentStatement.length > 0)
				if (statement.hasClass('alternative')) {
					// get all alternative breadcrumbs TODO: function from breadcrumbs api that returns alternative breadcrumbs
	          		var breadcrumbs = $.grep(that.breadcrumbApi.getBreadcrumbStack(null), function(a) {
						return a.substring(0, 2) == 'al';
					});
					// look for an alternative breadcrumb that is an alternative of the statement
					$.grep(breadcrumbs, function(a) {
						return $.inArray(a.substring(2), that.statementSiblings) != -1;
					});
					// if there is, get it, that's our parent
					if (breadcrumbs.length > 0)
						return breadcrumbs[0];
					else 
						return "al" + that.statementId;

				} else
					return that.statementTypeKey + that.parentStatement.data('statement').statementId;
        	else
          		return $.fragment().origin;
		},
		// gets a two-letter code for the type of statement
		_getTypeKey: function(type) {
			return 	type == 'proposal' ? 'pr' : 
				   	type == 'improvement' ? 'im' : 
				   	(type == 'pro_argument' || type == 'contra_argument') ? 'ar' :
  					type == 'background_info' ? 'bi' : 
					type == 'follow_up_question' ? 'fq' :
					type == 'discuss_alternatives_question' ? 'dq' : ''
		},
		_loadMessage: function(message) {
			if (!$.isEmptyObject(message)) info(message);
		},
		// Calculates height at which a new statement entries container should be initialised and initialises it
      	_initChildrenScroll: function(container) {
      		var that = this,
      			children = container;
       		if (!container.hasClass('children_container')) children = children.find('.children_container');
       		
			var animate = arguments.length > 1 ? arguments[1] : false;
			 
			var maxPage = that.options.maxPage,
				maxHeight = that.options.maxHeight,
			    elemHeight = that.options.childHeight;
		  
			if (animate) {
			 	maxPage = maxPage.animate;
				maxHeight = maxHeight.animate;
			}
			 
			if (children.hasClass('double')) { maxPage = maxPage.dual; maxHeight = maxHeight.dual; elemHeight = elemHeight.dual; } 
			else { maxPage = maxPage.single; maxHeight = maxHeight.single; elemHeight = elemHeight.single; }
			
			var list = children.children(':first'),
				heights = list.find('.children_list').map(function(){
         	 	var elementsCount = $(this).data('total-elements');
         		return elementsCount <= maxPage ? ((elementsCount + 1) * elemHeight) : maxHeight;
       		}).get();
       		
			height = Math.max.apply(Math, heights);
			if (!list.data('jsp'))
				list.animate({ 'height': height }, 300, function(){
				    list.height(height).jScrollPane({animateScroll: animate});	
				});
			else {
       
	       		// scroll down
	       		var jsp = list.data('jsp');
	       		var active = jsp.getContentPane().find('a.active');
	      
	       		if(active.length > 0) {
	         		var activeHeight = active.parent().index('li.' + statementType) * elemHeight;
	         		jsp.scrollToY(activeHeight);
	       		}
			}
    	},
      	_reinitialiseChildren: function(container) {
      		var that = this;
      			statement = that.element;
        	that._initChildrenLinks(container);
        	if (that.isEchoable)
          		statement.data('echoableApi').loadRatioBars(container);
		},
		_reinitialiseSiblings: function(container) {
			var that = this;	
			// initialise scroll plugin
        	that._initChildrenScroll(container);
        	that._initContainerMoreButton(container);
        	
			var opts = container.hasClass('alternatives') ? {"nl" : true, "al" : ("al" + that.statementId)} : {} ;
        	that._initSiblingsLinks(container, opts);
        	if (that.isEchoable) 
          		statement.data('echoableApi').loadRatioBars(container);
	   	},
		reinitialise: function(settings) {
			that.options = $.extend(that.options, settings, {load : false})
        	that.refresh();
		},
		loadMessage: function(message) {
			this._loadMessage(message);
		},
		insertChildren: function(type, children, page) {
			var that = this,
				statement = that.element;
			var container = statement.find('.children div.'+type);
        	if (container.length > 0) {
          		var lists = container.find('.children_list');
          		
          		// insert children list in the respective containers
          		lists.each(function(index){
            		var l = $(lists.get(index)),
                	c = children[index],
                	total = l.data('total-elements');
            		if (c.length == 0) return; 
            		c.insertBefore(l.find('li:last')); 
            		if (page*that.options.childrenPerPage >= total) l.children(":last").show();
	    	    });
          			
          		
          		// if it's rendering the first 7, initialize scroll plugin, if not, scroll down, mofo
          		if (page == 1)
            		that._initChildrenScroll(container, true);
          		else {
            		var scrollpane = container.children(':first').data('jsp');
            		scrollpane.reinitialise();
            		scrollpane.scrollToBottom();
          		}
          
          		// initialise links according to whether this is a siblings or a children box
          		container.parent().hasClass('siblings_panel') ? that._reinitialiseSiblings(container) : that._reinitialiseChildren(container);
        	}
        	else {
          		statement.find('.children a.' + type).parent().next().prepend(children);
          		that._reinitialiseChildren(container);
        	}
		},
		insertSiblings: function(siblings){
			var that = this;
	    	siblings.insertAfter(that.siblingsButton).bind("mouseleave", function() {
			  $(this).fadeOut();
			}).fadeIn();
			
			that._reinitialiseSiblings(siblings);
		},
		loadAuthors: function (authors) {
			var that = this, 
				statement = that.element;
	    	authors.insertAfter(statement.find('.summary h2')).animate(toggleParams, that.options.animation_speed);
			var length = authors.find('.author').length;
	      	statement.find('.authors_list').jcarousel({
	        	scroll: 3,
	        	buttonNextHTML: "<div class='next_button'></div>",
	        	buttonPrevHTML: "<div class='prev_button'></div>",
	        	size: length
	      	});
	    }
		
	
		
	});
	
}( jQuery ) );
