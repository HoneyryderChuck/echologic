
/*
 * Initialization on document ready.
 */
$(document).ready(function () {
  if ($('#echo_discuss').length > 0) {
    if ($('#statements').length > 0) {
      // breadcrumbs
      $('#breadcrumbs').breadcrumbs();
      // statements
      $('#statements > .statement').statement({'insertStatement': false});
    }
  }
});

/*
 * Redirects after session expiry.
 */
function redirectToStatementUrl() {
  var url = window.location.href.split('#');
  if (url.length > 1) {
    var fragment = url.pop();
    if (fragment.length > 0) {
      var path = url[0].split('?');
      var sids = getState("sids");
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

