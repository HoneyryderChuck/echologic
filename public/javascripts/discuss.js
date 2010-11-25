/* Do init stuff. */
$(document).ready(function () {
	
	addTagButtonEvents();
	
	addTagButtons();
	
	loadMessageBoxes();
	
	loadRTEEditor();
	
	loadStatementAutoComplete();
	
	initExpandables();
	
	loadDefaultText();
	
	cleanDefaultsBeforeSubmit();
	
	initEchoNewStatementButtons();
	
	loadStatementSessions();
	
	initPrevNextButtons();
	
	initChildrenPaginationButton();
	
	initStatementHistoryEvents();
  
  initFragmentStatementChange();
	
	initFormStatementType();
	
});

/********************************/
/* Statement navigation helpers */
/********************************/

function collapseStatements() {
	$('#statements .statement .header').removeClass('active').addClass('ajax_expandable');
	$('#statements .statement .content').hide('slow');
	$('#statements .statement .header .supporters_label').hide();
};

function collapseStatement(element) {
  element.find('.header').removeClass('active').addClass('ajax_expandable');
  element.find('.content').hide('slow');
  element.find('.supporters_label').hide();
};

function replaceOrInsert(element, template){
	if(element.length > 0) {
		element.replaceWith(template);
	}
  else 
	{
		$('div#statements').append(template);
	}
};

function renderAncestor(ancestor_element, ancestor_html) {
	replaceOrInsert(ancestor_element, ancestor_html);
}

function removeChildrenStatements(element){
	element.nextAll().each(function(){
		/* delete the session data relative to this statement first */
		$('div#statements').removeData(this.id);
		$(this).remove();
	});
};

function initExpandables(){
	$(".ajax_expandable").livequery(function(){
		var content = $(this).attr('data-content');
		var path = $(this).attr('href');  
		
		$(this).data('content', content);
		$(this).data('path', path);
		
		$(this).removeAttr('data-content');
		$(this).removeAttr('href');
	});
	/* Special ajax event for the discussion (collapse/expand)*/
	$(".ajax_expandable").live("click", function(){
		element = $(this);
		to_show = element.parents("div:first").find($(this).data('content'));
		supporters_label = element.find('.supporters_label'); 
		if (to_show.length > 0) {
			/* if statement already has loaded content */
			element.toggleClass('active');
			to_show.animate(toggleParams, 500);
			supporters_label.animate(toggleParams, 500);
		}
		else 
		{
			/* load the content that is missing */
			href = $(this).data('path');
			
			$.getScript(href, function(){
				element.toggleClass('active');
			});
		}
		return false;
	});
}


/* Gets the siblings of the loaded statement and places them in the client session for navigation purposes */
function loadStatementSessions() {
	$("div.statement, form.statement").livequery(function(){
		
		parent = $(this).prev();
		if (parent.length > 0)      
    {
      /* stores siblings with the parent node id */
      var parent = parent.attr('id');
    }else{
      /* no parent id, that means it's a root node, therefore, stores them into roots */
      var parent = 'roots';
    }
		siblings = eval($(this).attr("data-siblings"));
		if (siblings != null) {
			$("div#statements").data(parent, siblings);
	  }
		$(this).removeAttr("data-siblings");
	});
}

/* initializes prev/next navigation buttons with the proper url */
function initPrevNextButtons() {
	$(".statement .header a.prev").livequery(function(){
		initNavigationButton(this, -1);
	});
	$(".statement .header a.next").livequery(function(){
    initNavigationButton(this, 1);
  });
}

function initNavigationButton(element, inc) {
	current_node_id = eval($(element).attr('data-id'));
	node = $(element).parents('.statement');
	
	if (current_node_id == null) {
		current_node_id = node.attr("id").split('_');
		current_node_id.shift();
		current_node_id = "add/" + current_node_id.join('_');
	}
	/* get current node statement type */
	if (node.attr("id").match('add_')) {
    node_class = node.attr("id").replace('add/','');
  }
  else {
  	node_class = node.attr("id").match(/[a-z]+(?:_[a-z]+)?/);
		node_class = node_class[0].replace('edit_',''); //edit form has prev/next buttons too!!
  }
	/* get parent node from the visited node */
  parent_node = node.prev();
	/* get id where the current node's siblings are stored */
  if(parent_node.length > 0)
  {
		parent_path = parent_node_id = parent_node.attr('id');
	} else {
		parent_node_id = 'roots';
		parent_path = '';
	}
	/* get siblings ids */
	siblings_ids = $("div#statements").data(parent_node_id);
	/* get index of the prev/next sibling */
	id_index = (siblings_ids.indexOf(current_node_id) + inc) % siblings_ids.length;
	//BUG: % operator is not working properly in jquery for negative values (-1%7 => -1)?????????
	if (id_index < 0) {id_index = siblings_ids.length - 1;}
	
  new_node_id = new String(siblings_ids[id_index]);
	/* if 'add' action, then write add link */
	if (new_node_id.match('add')) {
		if(parent_path.length > 0) {
			path = "/" + parent_path.split('_').pop();
		} else {path = '';}
		element.href = element.href.replace(/\/\d+(\/\w+)?/, path + "/" + new_node_id);
	}
	else {
		
		element.href = element.href.replace(/\/\d+(\/\w+)?/, "/" + new_node_id);
	}
	
  $(element).removeAttr('data-id');
}

/****************/
/* Form Helpers */
/****************/

/* write the default message on the text inputs while they don't get filled */
function loadDefaultText() {
	
	$("#statements form.new input[type='text']").livequery(function(){
		var value = $(this).attr('data-default');
		if (this.value.length == 0) {
			$(this).toggleVal({
				populateFrom: 'custom',
				text: value
			});
		}
		$(this).removeAttr('data-default');
		$(this).blur();
	});
	
	$("#statements form.new iframe.rte_doc").livequery(function(){
		var value = $(this).attr('data-default');
		var doc = $(this).contents().get(0);
		text = $(doc).find('body');
		if(text.html().length == 0 || html.val() == '</br>') {
			label = $("<span class='defaultText'></span>").html(value);
			label.insertAfter($(this));
			
			$(doc).bind('click', function(){
				label.hide();
			});
			$(doc).bind('blur', function(){
				new_text = $(this).find('body');
				if (new_text.html().length == 0 || new_text.html() == '</br>') {
					label.show();
				}
			});
		}
		$(this).removeAttr('data-default');
	});
	
	$("#statements form.new").livequery( function() {
    $(this).bind('submit', (function() {
      $(this).find(".toggleval").each(function() {
        if($(this).val() == $(this).data("defText")) {
          $(this).val("");
        }
      });
    }))
  });
}

/* clean input text fields which might still be filled with the default message */
function cleanDefaultsBeforeSubmit() {
	$('form.statement').livequery(function(){
		$(this).bind('submit', function(){
	    $("input[type='text']", $(this)).each(function() {
	      // If the input still with default value, clean it before the submit
	      if ($(this).val() == $(this).attr('data-default')) {
	        $(this).val('');
	      }
	    });
		});
  });
}

function initEchoNewStatementButtons() {
	$('div#echo_button .new_record.not_supported').live('click', function(){
		initEchoStatementButton($(this),'supported','not_supported','echo_indicator','no_echo_indicator',10,'1',true)
	});
	$('div#echo_button .new_record.supported').live('click', function(){
		initEchoStatementButton($(this),'not_supported','supported','no_echo_indicator','echo_indicator',0,'0',false)
  });
}

function initEchoStatementButton(element, class_add, class_remove, ratio_class_add, ratio_class_remove, ratio, supporters_number, value) {
	page = element.parents('form.statement');
	/* modify echo button in element */
	element.removeClass(class_remove).addClass(class_add);
	
  /* modify text in supporters label */
  page.find('#echo').val(value);
	supporters_label = page.find('.supporters_label');
  supporters_text = supporters_label.text();
  supporters_label.text(supporters_text.replace(/[0-9]/, supporters_number));
	
	/* modify the supporters bar */
	old_supporter_bar = page.find('.supporters_bar');
  new_supporter_bar = $('<span></span>').attr('class', old_supporter_bar.attr('class')).addClass(ratio_class_add).removeClass(ratio_class_remove).attr('alt', ratio);
	new_supporter_bar.attr('title', page.find('.supporters_label').text());
	old_supporter_bar.replaceWith(new_supporter_bar);
	info(page.find('.action_bar').data('messages')[class_add]);
}

/**************************/
/* Discussion Tag Helpers */
/**************************/

/* add new tags to be added to statement */
function addTagButtonEvents() {
  $('.discussion #tag_topic_id').live('keypress', (function(event) {
    if (event && event.keyCode == 13) { /* check if enter was pressed */
      if ($('.discussion #tag_topic_id').val().length != 0) {
        $('.discussion .addTag').click();
      }
      return false;
    }
  }));

  $('.discussion .addTag').live('click', (function() {
    entered_tags = $('.discussion #tag_topic_id').val().trim().split(",");
    if (entered_tags.length != 0) {
      /* Trimming all tags */
      entered_tags = jQuery.map(entered_tags, function(tag) {
        return (tag.trim());
      });
      existing_tags = $('.discussion #discussion_tags').val().trim();
      existing_tags = existing_tags.split(',');

      new_tags = new Array(0);
      while (entered_tags.length > 0) {
        tag = entered_tags.shift().trim();
        if (existing_tags.indexOf(tag) < 0 && entered_tags.indexOf(tag) < 0) {
          if (tag.localeCompare(' ') > 0) {
            element = createTagButton(tag, "#discussion_tags");
            $('#discussion_tags_values').append(element);
            new_tags.push(tag);
          }
        }
      }
      discussion_tags = $('.discussion #discussion_tags').val();
      if (new_tags.length > 0) {
        discussion_tags = ((discussion_tags.trim().length > 0) ? discussion + ',' : '') + new_tags.join(',');
        $('.discussion #discussion_tags').val(discussion_tags);
      }
      $('.discussion #tag_topic_id').val('');
      $('.discussion #tag_topic_id').focus();
    }
  }));
}

/* creates a statement tag button */
function createTagButton(text, tags_id) {
  element = $('<span/>').addClass('tag');
  element.text(text);
  deleteButton = $('<span class="delete_tag_button"></span>');
  deleteButton.click(function(){
    $(this).parent().remove();
    tag_to_delete = $(this).parent().text();
    discussion_tags = $(tags_id).val().split(',');
    index_to_delete = discussion_tags.indexOf(tag_to_delete);
    if (index_to_delete >= 0) {
      discussion_tags.splice(index_to_delete, 1);
    }
    $('form.discussion').find(tags_id).val(discussion_tags.join(','));
  });
  element.append(deleteButton);
  return element;
}

/* load the previously existing tags */
function addTagButtons() {
	$('form.discussion.new, form.discussion.edit').livequery(function(){
	  tags_to_load = $('#discussion_tags').val();
		tags_to_load = $.trim(tags_to_load);
		tags_to_load = tags_to_load.split(',');
	  while (tags_to_load.length > 0) {
	    tag = $.trim(tags_to_load.shift());
	    if (tag.localeCompare(' ') > 0) {
	      element = createTagButton(tag, "#discussion_tags");
	      $(this).find('#discussion_tags_values').append(element);
	    }
	  }
	});
}

/* select approved text in the form */
/*function selectApprovedText(id) {
  if (document.selection) document.selection.empty();
  else if (window.getSelection)
          window.getSelection().removeAllRanges();
  if (document.selection) {
    var range = document.body.createTextRange();
        range.moveToElementText(document.getElementById("ip_text"));
    range.select();
    }
    else if (window.getSelection) {
    var range = document.createRange();
    range.selectNode(document.getElementById("ip_text"));
    window.getSelection().addRange(range);
  }
}*/

/*************************/
/* Delayed Message Boxes */
/*************************/

var timer = null;
function loadMessageBoxes() {
	$('.statement .message_box').livequery(function(){
		element = $(this);
		if (timer != null) {
      clearTimeout (timer);
      element.stop(true).hide;
    }
		timer = setTimeout( function(){
		  element.animate(toggleParams, 500);
		}, 1500);
	});
}

/*********************/
/* RTE Editor loader */
/*********************/

/* lwRTE editor loading */
function loadRTEEditor() {
	$('textarea.rte_doc, textarea.rte_tr_doc').livequery(function(){
		defaultText = $(this).attr('data-default');
		
		parent_node = $(this).parents('.statement');
	  url = 'http://' + window.location.hostname + '/stylesheets/';
	  $(this).rte({
	    css: ['jquery.rte.css'],
	    base_url: url,
	    frame_class: 'wysiwyg',
	    controls_rte: rte_toolbar,
	    controls_html: html_toolbar
	  });
		parent_node.find('.focus').focus();
		
		/* for default text */
		parent_node.find('iframe').attr('data-default', defaultText);
	});
}

/********************************/
/* STATEMENT NAVIGATION HISTORY */
/********************************/

function getCurrentStatementsStack(element, new_level) {
	/* get the statement element */
	statement = $(element).parents('.statement');
	/* get statement id current index in the list of statements */
  statement_index = $('.statement').index(statement);
	
	/* get soon to be visible statement */
  path = element.href.split("/");
  id = path.pop().split('?').shift();
	if (id.match(/\d+/)) {
  	current_sid = id;
  } else {
		/* add teaser case */
		current_sid = [path.pop(),id].join('/');
	}
  current_stack = [];
	
	/* get current_stack of visible statements (if any matches the clicked statement, then break) */
  $(".statement").each( function(index){
		if (index < statement_index) {
			id = $(this).attr('id').split('_').pop();
			if(!id.match(/\d+/)){
				id = "add/" + id;
			}
			current_stack.push(id);
		} else if (index == statement_index) {
			 if (new_level) {
			 	current_stack.push($(this).attr('id').split('_').pop());
			 }
		  }
  });
  
  /* insert clicked statement */
  current_stack.push(current_sid);
	return current_stack;
}

function initStatementHistoryEvents() {
	$("#statements .statement .header a.statement_link").live("click", function(){
		current_stack = getCurrentStatementsStack(this, false);
		/* set fragment */
		$.setFragment({ "sid": current_stack.join(','), "new_level" : ''});
		return false;
	});
	
	$("#statements .statement .children a.statement_link").live("click", function(){
    current_stack = getCurrentStatementsStack(this, true);
		/* set fragment */
    $.setFragment({ "sid": current_stack.join(','), "new_level" : true});
		return false;
  });
	
	$("#statements form.statement.new .buttons a.cancel").livequery(function(){
		if ($.fragment().sid) {
			var sid = $.fragment().sid;
			var path = getStatementStackPath($.fragment().sid);
      var new_sid = sid.split(",");
			new_sid.pop();
			
			$(this).addClass("ajax");
			this.href = $.queryString(this.href.replace(/\/\d+(\/\w+)?/,path), {
				"sid": new_sid.join(","),
				"new_level": ''
			})
		}
	});
}

function getStatementStackPath(stack) {
	var stack = stack.split(",");
  var sid = stack.pop();
  if (sid.match(/\d+/)) {
    var path = "/" + sid;
  } else {
    /* add teaser case */
    if (stack.length > 0) {
      var parent_id = stack[stack.length-1];
      var path = "/" + parent_id;
    } else {
      var path = '';
    } 
    path += "/" + sid;
  }
  return path;
}

function initFragmentStatementChange() {
  $(document).bind("fragmentChange.sid", function() {
		if ($.fragment().sid) {
			var sid = $.fragment().sid;
			var path = getStatementStackPath(sid);
			var new_sid = sid.split(",");
			
			path = $.queryString(document.location.href.replace(/\/\d+(\/\w+)?/, path), {
        "sid": new_sid.join(","),
        "new_level": $.fragment().new_level
      })
			$.ajax({
				url:      path,
	      type:     'get',
	      dataType: 'script'
			});
		}
  });
  
  if ($.fragment().sid) {
		$(document).trigger("fragmentChange.sid");
  }
}

/*********************************************/
/*    CHILDREN PAGINATION AND SCROLLING      */
/*********************************************/

function initChildrenPaginationButton() {
  $(".statement .more_pagination a").live("click", function() {
    $(this).replaceWith($('<span/>').text($(this).text()).addClass('more_loading'));
  });
}


function pagination_scroll_down(element) {
  element.jScrollPane({animateTo: true});
  if (element.data('jScrollPanePosition') != element.data('jScrollPaneMaxScroll')) {
    element[0].scrollTo(element.data('jScrollPaneMaxScroll'));
  }

}


/***********/
/* GENERAL */
/***********/

function loadStatementAutoComplete() {
	$('form.statement .tag_value_autocomplete').livequery(function(){
		$(this).autocomplete('../../discuss/auto_complete_for_tag_value', {minChars: 3, selectFirst: false});
	});
}

function loadMessages(element, messages) {
	$(element).data('messages', messages);
}

function initFormStatementType() {
	$("#statements form.new").livequery(function(){
	 input_type = $(this).find('input#type');
	 type = input_type.attr('value');
	 input_type.removeAttr('value');
	 $(this).bind('submit', function() {
	 	 input_type = $(this).find('input#type');
		 input_type.attr('value', type);
	 });
	});
}
