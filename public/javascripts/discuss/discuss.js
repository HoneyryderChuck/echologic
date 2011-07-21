/* Do init stuff. */

/* Initialization on loading the document */
$(document).ready(function () {
	if ($('#function_container.discuss').length > 0) {
  	if ($('#statements').length > 0) {
	    initBreadcrumbs();
	    initStatements();
			initFragmentStatementChange();
	    loadSocialMessages();
	  }
  }
});


function initStatements(){
	var sids = [];
	$('#statements .statement').each(function() {
		$(this).statement({'insertStatement': false});
		if ($(this).is("div")) {
			sids.push($(this).attr('id').match(/\d+/));
		}
	});
	if (sids.length > 0 && (!$.fragment().sids || $.fragment().sids.length == 0)) {
  	$.setFragment({
  		"sids": sids.join(",")
  	});
  }
}

function initBreadcrumbs() {
	var breadcrumbs = $('#breadcrumbs');
  if (breadcrumbs.length > 0) {
   breadcrumbs.breadcrumbs();
  }
}


/* Extracts the statement node Id from the statement DOM Id. */
function getStatementId(domId) {
  return domId.replace(/[^0-9]+/, '');
}

/********************************/
/* STATEMENT NAVIGATION HISTORY */
/********************************/

function initFragmentStatementChange() {
	$(document).bind("fragmentChange.sids", function() {
		if ($.fragment().sids) {
			var sids = $.fragment().sids;
			var new_sids = sids.split(",");
			var path = "/" + new_sids[new_sids.length-1];
			var last_sid = new_sids.pop();

			var visible_sids = $("#statements .statement").map(function(){
				return getStatementId(this.id);
			}).get();


			/* after new statement was created and added to the stack, we needn't load again */
			if ($.inArray(last_sid, visible_sids) != -1 && visible_sids[visible_sids.length-1]==last_sid) {return;}

			sids = $.grep(new_sids, function (a) {
				return $.inArray(a, visible_sids) == -1 ;});

      /* Breadcrumb Logic */
      var bids = $("#breadcrumbs").data('breadcrumbApi').breadcrumbsToLoad($.fragment().bids);

			path = $.queryString(document.location.href.replace(/\/\d+/, path), {
        "sids": sids.join(","),
				"bids": bids.join(","),
        "nl": $.fragment().nl,
				"origin": $.fragment().origin,
				"cs": $.fragment().sids
      });

			$.ajax({
				url:      path,
	      type:     'get',
	      dataType: 'script'
			});
		}
  });

	/* Statement Stack */
  var bids;
  if ($.fragment().sids) {
		if (!$.fragment().bids || $.fragment().bids == 'undefined') {
			bids = $("#breadcrumbs").data('breadcrumbApi').getBreadcrumbStack(null);
			}
		else {
			bids = $.fragment().bids;
			bids = bids ? bids.split(',') : [];
		}

		var origin_bids = $.grep(bids, function(a){
			return $.inArray(a.substring(0,2), ['ds','sr','fq']) != -1;
		});
    var origin;
		if (!$.fragment().origin || $.fragment().origin == 'undefined') {
      origin = origin_bids.length == 0 ? "" : origin_bids.pop();
    } else {
      origin = $.fragment().origin;
    }

    $.setFragment({ "nl" : true, "bids" : bids.join(','), "origin" : origin });
	  $(document).trigger("fragmentChange.sids");
  }


	/* Breadcrumbs */
	if ($.fragment().bids) {
		$(document).trigger("fragmentChange.bids");
	}
}

/*********************************************/
/*    CHILDREN PAGINATION AND SCROLLING      */
/*********************************************/



function resetChildrenList(list, properties) {
	list.animate(properties, 300, function() {
    list.jScrollPane({animateScroll: true});
  });
}


/* REDIRECTION AFTER SESSION EXPIRE */
function redirectToStatementUrl() {
	var url = window.location.href.split('#');
	if (url.length > 1) {
		var fragment = url.pop();
		if (fragment.length > 0) {
			var path = url[0].split('?');
			var sids = $.fragment().sids;
			if (sids) {
				var current_statement = sids.split(',').pop();
				path[0] = path[0].replace(/\/\d+/, '/' + current_statement);
			}
      path[1] = fragment;
      url = path.join('?');
		}
	} else {
		url = url.pop();
	}
	window.location.replace(url);
}

/******************/
/* SOCIAL SHARING */
/******************/

function loadSocialMessages(){
	var social_messages = $('#social_messages');
  var messages = {
    'success'     : social_messages.data('success'),
    'error'       : social_messages.data('error')
  };
  social_messages.data('messages', messages);
  social_messages.removeAttr('data-success').removeAttr('data-error');
}

function socialSharingFinished(array) {
	var aux = false;
	$('#social_messages').data('stuff', array);
	$.map(array, function(elem) {
		if (elem['attempted']) {
			aux = true;
			if (!elem['success']) {
		  	error($('#social_messages').data('messages')['error']);
				return;
			}
		}
	});
	if (aux) {
		$('.rpxnow_lightbox').hide();
		info($('#social_messages').data('messages')['success']);
	}
}


function isEchoStatementUrl(url) {
	return url.match(/^http:\/\/(www\.)?echo\..+\/statement\/(\d+)$/);
}


function generateKey(type) {
	if (type=='proposal'){return 'pr';}
	else if (type =='improvement'){return 'im';}
	else if (type=='pro_argument' || type=='contra_argument'){return 'ar';}
	else if (type=='follow_up_question'){return 'fq';}
	else if (type=='background_info'){return 'bi';}
	else {return '';}
}

function getOriginKeys(array) {
  return $.grep(array, function(a, index) {
    return $.inArray(a.substring(0,2), ['pr','ar','im', 'bi']) == -1;
  });
}
