$(document).ready(function () {
	if ($('.search_container').length > 0) {
		$("#search_form").placeholder();
  	initHistoryEvents();
  	initPaginationButtons();
  	initFragmentChange();
		loadSearchAutoComplete();
		$('#questions_container').statement_search();
  }
});


/**************************/
/*    SEARCH HISTORY      */
/**************************/


function initHistoryEvents() {
	$("#search_form .submit_button").live("click", function(){
    setSearchHistory();
    return false;
  });

	$('#search_form #search_terms').live("keypress", function(event) {
    if (event && event.keyCode == 13) { /* check if enter was pressed */
      setSearchHistory();
      return false;
    }
  });

  $("a.ajax_sort").live("click", function() {
    var sort = $(this).attr('value');
		$(':input[id=sort]').val(sort);
		setSearchHistory();
    return false;
  });

  $("a.ajax_no_sort").live("click", function() {
		$(':input[id=sort]').val('');
		setSearchHistory();
    return false;
  });
}



function setSearchHistory() {
	$("#search_form").data('placeholderApi').cleanDefaultValues();
  var search_terms = $("#search_terms").val();
  if (search_terms.length > 0) {
    search_terms = $.trim(search_terms);
  }
  if ($(':input[id=sort]').length > 0) {
    var sort = $(':input[id=sort]').val();
	  $.setFragment({ "search_terms": search_terms, "sort" : sort, "page": "1", "page_count" : "", "page_count" : ""});
  } else {
    $.setFragment({ "search_terms": search_terms, "page": "1", "page_count" : ""});
  }
}

/**********************/
/*    PAGINATION      */
/**********************/

function initPaginationButtons() {
	$(".pagination a").live("click", function() {
    $.setFragment({ "page" : $.queryString(this.href).page })
    return false;
  });
}


function initFragmentChange() {
  $(document).bind("fragmentChange.page", function() {
	  if ($.fragment().page) {triggerSearchQuery();}
  });

  if ($.fragment().page_count) {
    $.setFragment({"page": "1"});
  }

  if ($.fragment().page) {
    $(document).trigger("fragmentChange.page");
  }

}

function triggerSearchQuery(){
  $.getScript($.queryString(document.location.href.split('?')[0], {
    "page_count": $.fragment().page_count,
    "page": $.fragment().page,
    "sort": $.fragment().sort,
    "search_terms": $.fragment().search_terms
  }));
}


/*
 * Initializes auto_complete property for the tags text input
 */
function loadSearchAutoComplete() {
	var path = $('.function_container').is('#echo_discuss_search') ? '../../discuss/auto_complete_for_tag_value' : '../users/users/auto_complete_for_tag_value';

  $('#search_form .tag_value_autocomplete').autocompletes(path, {minChars: 3,
                                                                 selectFirst: false,
                                                                 multiple: true});
}

