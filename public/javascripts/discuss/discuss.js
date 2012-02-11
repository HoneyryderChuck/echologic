
/*
 * Initialization on document ready.
 */
$(document).ready(function () {
	if ($('#echo_discuss').length > 0) {
	  	if ($('#statements').length > 0) {
		    initBreadcrumbs();
			initStatements();
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
	});
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
	else if (type == 'discuss_alternatives_question') {return 'dq';}
	else {return '';}
}


/*
 * Returns breadcrumb keys representing a new origin (being outside of the scope of a given stack).
 */
function getOriginKeys(array) {
  return $.grep(array, function(a, index) {
    return $.inArray(a.substring(0,2), ['sr','ds','mi','fq','jp','dq']) != -1;
  });
}

/*
 * Returns breadcrumb keys representing a new hub (being outside of the scope of a given stack).
 */
function getHubKeys(array) {
  return $.grep(array, function(a, index) {
    return $.inArray(a.substring(0,2), ['al']) != -1;
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
 * Redirects after session expiry.
 */
function redirectToStatementUrl() {
	var url = window.location.href.split('#');
	if (url.length > 1) {
		var fragment = url.pop();
		if (fragment.length > 0) {
			var path = url[0].split('?');
			var sids = $.bbq.getState("sids");
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

