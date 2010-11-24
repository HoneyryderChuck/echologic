var localtests = {
	test_open_proposal : function()
	{
		module("1");
		test("open proposal statement", function() 
    {
			expect(7);
      stop();
			var statements = $('#statements .statement');
			var statement = $('#statements .statement:last');
			var child = $('#statements .statement .children:first ul li:first a');
			var handler = function(event, data){
				setTimeout( function()
	      {
				  equals($('#statements .statement').length, statements.length + 1, "check if new statement was opened");
					statement = $('#'+statement.attr('id')); 
	        ok(statement.find('.header').hasClass('ajax_expandable'), "has ajax_expandable class");
	        ok(!statement.find('.header').hasClass('active'), "not active elements");
	        ok(statement.find('.content').is(":hidden"), "is hidden");
	        var new_statement = $('#statements .statement:last');
	        ok(!new_statement.find('.header').hasClass('ajax_expandable'), "has ajax_expandable class");
	        ok(new_statement.find('.header').hasClass('active'), "not active elements");
	        ok(new_statement.find('.content').is(":visible"), "is hidden");
				 start();
	      }, 2000);

				
			};
      child.bind("click", {}, handler).trigger('click').unbind("click", handler);
    });
		module("2");
		test("get authors", function() 
    {
		  stop();
      var statements = $('#statements .statement');
      var authors_button = $('#statements .statement:last a.authors_button');
       
      var authors_handler = function(event, data){
        setTimeout( function()
        { 
          statement_authors = $('#statements .statement:last #authors');
          ok(statement_authors.length != 0, "got the statement's authors");
          start();
        }, 2000);
      };
			jQuery.ajax({
          url: authors_button.data('path'),
          complete: function(){ authors_handler; }
      });

      //authors_button.bind("click", {}, handler).trigger('click', function(){alert(this.id);}).unbind("click", handler);
    });  
 }
};

$().extend(tests, localtests);

