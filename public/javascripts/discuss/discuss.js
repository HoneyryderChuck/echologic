
/*
 * Initialization on document ready.
 */
$(document).ready(function () {
	if ($('#echo_discuss').length > 0) {
  	if ($('#statements').length > 0) {
	    initBreadcrumbs();
			initStatements();
      initFragmentChangeHandling();
	    loadSocialSharingMessages();
	  }
  }
});


/*
 * Initializes the breadcrumb plugin to handle all breadcrumbs.
 */
function initBreadcrumbs() {
	var breadcrumbs = $('#breadcrumbs');
  if (breadcrumbs.length > 0) {
   breadcrumbs.breadcrumbs();
  }
}


/*
 * Initializes the statements (by applying the statement plugin on them)
 * and sets the SIDS (statement Ids) in the fragement if it is empty.
 */
function initStatements() {
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


/*
 * Initializes handlers to react on fragement (SIDS - statement Ids) change events.
 */
function initFragmentChangeHandling() {

	$(document).bind("fragmentChange.sids", function() {
		if ($.fragment().sids) {
			var sids = $.fragment().sids;
			var new_sids = sids.split(",");
			var path = "/" + new_sids[new_sids.length-1];
			var last_sid = new_sids.pop();

			var visible_sids = $("#statements .statement").map(function(){
				return getStatementId(this.id);
			}).get();


			// After new statement was created and added to the stack, we needn't load again
			if ($.inArray(last_sid, visible_sids) != -1 && visible_sids[visible_sids.length-1]==last_sid) {return;}

			sids = $.grep(new_sids, function (a) {
				return $.inArray(a, visible_sids) == -1 ;});

      // Breadcrumb logic
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

	// Statement stack
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

    $.setFragment({
      "nl" : true,
      "bids" : bids.join(','),
      "origin" : origin });
	  $(document).trigger("fragmentChange.sids");
  }

	// Breadcrumbs
	if ($.fragment().bids) {
		$(document).trigger("fragmentChange.bids");
	}
}


/*
 * Extracts the statement node Id from the statement DOM Id.
 */
function getStatementId(domId) {
  return domId.replace(/[^0-9]+/, '');
}


/*
 * Returns the key according to the given type of the statement.
 */
function getTypeKey(type) {
	if (type == 'proposal') {return 'pr';}
	else if (type == 'improvement') {return 'im';}
	else if (type == 'pro_argument' || type == 'contra_argument') {return 'ar';}
  else if (type == 'background_info') {return 'bi';}
	else if (type == 'follow_up_question') {return 'fq';}
	else {return '';}
}


/*
 * Returns breadcrumb keys representing a new origin (being outside of the scope of a given stack).
 */
function getOriginKeys(array) {
  return $.grep(array, function(a, index) {
    return $.inArray(a.substring(0,2), ['sr','ds','mi','fq','jp']) != -1;
  });
}


/*
 * Returns true if the URL matches the pattern of an echo statement link.
 */
function isEchoStatementUrl(url) {
	return url.match(/^http:\/\/(www\.)?echo\..+\/statement\/(\d+)/);
}


/*
 * Loads the social sharing success and error messages.
 */
function loadSocialSharingMessages() {
	var social_messages = $('#social_messages');
  var messages = {
    'success'     : social_messages.data('success'),
    'error'       : social_messages.data('error')
  };
  social_messages.data('messages', messages);
  social_messages.removeAttr('data-success').removeAttr('data-error');
}


/*
 * Animates the height of the children list panel and scrolls to the buttom afterwards.
 */
function resetChildrenList(list, properties) {
	list.animate(properties, 300, function() {
    list.jScrollPane({animateScroll: true});
  });
}


/*
 * Redirects after session expiry.
 */
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

