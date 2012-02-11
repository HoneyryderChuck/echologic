(function( $ ) {
	
	$.widget("echo.placeholder", {
		options: {
			text_class    : "iframe.rte_doc",
			text_area_class : ".statement_text",
			changed_class : "changed",
			default_attr  : "data-default",
			focus_class   : "focused"
		},
		_create: function() {
			var that = this,
				place = that.element;
				
			that.textInputs = place.find("input[type='text']");
			that.textAreas = isMobileDevice() ? place.find('textarea' + that.options.text_area_class) : place.find(that.options.text_class);
				
			that._loadInputs();
			that._loadText();
			that._loadSubmitClean();
			
		},
		_loadInputs: function() {
			var that = this;
			that.textInputs.each(function(index){
				var inputText = $(this),
					initValue = inputText.val(),
          			value = inputText.attr(that.options.default_attr);
          			
          		inputText.toggleVal({
            		populateFrom: 'custom',
            		text: value,
					changedClass: that.options.changed_class,
					focusClass: that.options.focus_class
          		});
          		inputText.removeAttr(that.options.default_attr);
          		if (index == 0) inputText.blur();
          		
          		if (initValue && initValue.length > 0) {
					inputText.val(initValue);
					inputText.focus();
					inputText.blur();
				}
			});
		},
		_loadText: function() {
			var that = this;
			if (isMobileDevice()) {
          		// Simple text area (so that mobile devices detect it as input field)
				that.textAreas.each(function(){
					var textArea = $(this),
						initValue = textArea.val(),
					  	value = textArea.attr(that.options.default_attr);
					  	
            		value = value.replace(/(<([^>]+)>)/ig,""); // Stripping HTML tags
					textArea.toggleVal({
	            		populateFrom: 'custom',
	            		text: value,
	            		changedClass: that.options.changed_class,
	            		focusClass: that.options.focus_class
	          		});
						
					textArea.removeAttr(that.options.default_attr);
					
					if (initValue && initValue.length > 0) {
	            		inputText.val(initValue);
	            		inputText.focus();
	            		inputText.blur();
	          		}
				});
			} else {
				// Text Area (RTE Editor)
				that.textAreas.each(function(){
					var editor = $(this),
						value = editor.attr(that.options.default_attr),
						doc = $(editor.contents().get(0)),
						text = $(doc).find('body');
						if (text && text.html().length == 0) {
							var label = $("<span class='defaultText'/>").html(value);
							label.insertAfter(editor).click(function(){
								doc.click();
							});

							doc.bind('click', function(){
								label.hide();
								editor.focus();
							});
							doc.bind('blur', function(){
								var newText = $(editor.contents().get(0)).find('body');
								if (newText.html().length == 0) 
									label.show();
							});
						}
						editor.removeAttr(that.options.default_attr);
				});
		    }
		},
		_loadSubmitClean: function() {
			var that = this;
			// Clean text inputs on submit
        	that.element.bind('submit', (function() {
					that._cleanToggleValues($(this));
        	}));
		},
		_cleanToggleValues: function(content) {
			content.find(".toggleval").each(function() {
				var inp = $(this);
          		if(inp.val() == inp.data("defText")) 
            		inp.val("");
        	});
		},
		cleanDefaultValues: function () {
			var that = this;
			that._cleanToggleValues(that.element);
		}
	});
}( jQuery ) );
		