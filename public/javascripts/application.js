// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

  /* Do init stuff. */
  $(function() {

    $.fragmentChange(true);
    initMainMenu();
    initStaticMenu();

    initAjaxClickEvents();
    initLoadAjaxForms();
    initUploadFormSubmit();

    initMoreHideButtons();
    initTabsContainers();
    initTooltips();
    addRoundedCorners();

    initSigninup();
    initAboutUs();

    /* Always send the authenticity_token with Ajax */
    $(document).ajaxSend(function(event, request, settings) {
      if ( settings.type == 'post' ) {
        settings.data = (settings.data ? settings.data + "&" : "")
        + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
      }
    });
  });


  /*********************/
  /* Global parameters */
  /*********************/

  var toggleParams;
  if (jQuery.support.opacity) {
    toggleParams = {
      'height' : 'toggle',
      'opacity': 'toggle'
    };
  } else {
    toggleParams = {
      'height' : 'toggle'
    };
  }


  /*****************/
  /* Menu handling */
  /*****************/

  /*
   * Sets up main menu behaviour and dropdown positioning.
   */
  function initMainMenu() {
    positionMainMenuDropdowns();
    if (isMobileDevice()) {
      $('a.main_menu_item').add('#echo_language_button').click(function(e) {
        initMenuItemHovering($(this).parent(), e);
      });
    }
  }

  function initMenuItemHovering(menuItem, e) {
    menuItem.siblings().removeClass('hover');
    menuItem.toggleClass('hover');
    if (menuItem.hasClass('hover')) {
      e.preventDefault();
      return false;
    }
    return true;
  }

  /*
   * Calculates the positions for the main menu dropdowns.
   */
  function positionMainMenuDropdowns() {
    $('.app_menu li.main_menu_item').each(function () {
      setDropdownPosition($(this), 160);
    });
    $('.embed_menu li.main_menu_item').each(function () {
      setDropdownPosition($(this), 154);
    });
    setDropdownPosition($('#echo_language_button_container'), 154);
  }

  /*
   * Does the actual positioning.
   */
  function setDropdownPosition(menuItem, offset) {
    menuItem.find('.dropdown').css('left', -(offset - menuItem.innerWidth())/2);
  }

  /*
   * If JS is enabled hijack staticMenuButtons to do AJAX requests.
   */
  function initStaticMenu() {
    $(".staticMenuButton").live("click", function() {
      setActionControllerFragment(this.href);
      return false;
    });

    $(".outerMenuItem").live("click", function() {
      $.getScript(this.href);
      return false;
    });

    $(".prevNextButton").live("click", function() {
      setActionControllerFragment(this.href);
      return false;
    });

    $(".illustrationHolder a").live("click", function() {
      setActionControllerFragment(this.href);
      return false;
    });
  }

  /*
   * Remove all activeMenu classes and give it to the static menu item specified
   * through the given parameter.
   */
  function changeMenuImage(item) {
    $('#static_menu a').removeClass('active');
    $('#static_menu #'+item+'_button').toggleClass('active');
  }


  /**********************/
  /* Fragement handling */
  /**********************/

  /*
   * Sets the fragment to the controller and action of the anchors href attribute.
   * TODO: optimize splitting of url!
   * TODO: action set checking
   */
  function setActionControllerFragment(href) {
    var controller = href.toString().split('/')[4];
    var action = href.toString().split('/')[5];
    if (href.toString().split('/')[5]) {
        document.location.hash = '/' + controller + '/' + action;
    } else {
        document.location.hash = '/' + controller;
    }
  }

  /*************************/
  /* Ajax requests & forms */
  /*************************/

  /*
   * Handles Ajax requests.
   */
  function initAjaxClickEvents() {
    $(".ajaxLink").live("click", function() {
      setActionControllerFragment(this.href);
      return false;
    });

    $("#static_menu a").live("click", function() {
      setActionControllerFragment(this.href);
      return false;
    });

    $(".ajax").live("click", function() {
      $.getScript(this.href);
      return false;
    });

    $(".ajax_delete").live("click", function() {
      $.ajax({
        url:      this.href,
        type:     'post',
        dataType: 'script',
        data:   { '_method': 'delete' }
      });
      return false;
    });

    $(".ajax_put").live("click", function() {
      $.ajax({
        url:      this.href,
        type:     'post',
        dataType: 'script',
        data:   { '_method': 'put' }
      });
      return false;
    });

    // Special newsletter submission tag
    $(".newsletter_submit_tag").live("click", function() {
      $("#newsletter_test").val($(this).attr("value"));
      $("#new_newsletter_form").submit();
      return false;
    });
  }

  /*
   * Initializes loading Ajax forms.
   */
  function initLoadAjaxForms() {
    $('form.ajax_form').livequery(function () {
      $(this).ajaxForm({ dataType : 'script' });
    });
  }

  /*
   * Initializes handlers for submitting upload Ajax forms.
   *
   * TODO: Load the upload picture forms here
   */
  function initUploadFormSubmit(){
    $('#dialogContent .upload_form').livequery(function(){
      var element = $(this);
      element.submit(function(){
				$(this).ajaxSubmit({
          beforeSend: function(){
						$('#uploading_progress').show();
          },
          complete: function(){
						$('#uploading_progress').hide();
          },
          success: function(data, status) {
				    $.ajax({
              type: 'get',
              dataType: 'script',
              url: element.data('image-redirect')
            });
            $('#dialogContent').dialog('close');
          }
        });
        return false;
      });
    })
  }


  /*****************************/
  /* Handling general elements */
  /*****************************/

  /*
   * Toggles some detailed information and the More/Less buttons controlling it.
   */
  function initMoreHideButtons() {
    $('.more_button').live('click', (function() {
      $(this).siblings('.toggled_content').animate(toggleParams, 300);
      $(this).hide();
      $(this).prev().show();
    }));

    $('.hide_button').live('click', (function() {
      $(this).siblings('.toggled_content').animate(toggleParams, 300);
      $(this).hide();
      $(this).next().show();
    }));
  }

  /*
   * Initizalize tab containers.
   */
  function initTabsContainers() {
    $('.tab_details_container').livequery(function() {
      $(this).tabs();
    });
  }

  /*
   * Initializing all tooltips.
   * For docu see http://bassistance.de/jquery-plugins/jquery-plugin-tooltip
   */
  function initTooltips() {
    $(".ttLink[title]").livequery(function() {
      $(this).tooltip({
        track:  true,
        showURL: false
      });
    });
  }

  /*
   * Adds rounded corners to all elements with class 'rounded-box'.
   */
  function addRoundedCorners() {
    var str = '<b class="lr l"></b><b class="lr r"></b><b class="tb t"></b><b class="tb b"></b><b class="cn tl"></b><b class="cn tr"></b><b class="cn bl"></b><b class="cn br"></b>';
    $('.rounded-box').livequery(function() {
      $(this).append(str);
    });
  }


  /*****************************/
  /* General user interactions */
  /*****************************/

  /*
   * Shows and info message and hides it with a length-dependent delay.
   */
  function info(text) {
    showMessage('info', text);
  }

  /*
   * Shows an error message and hides it with a length-dependent delay.
   */
  function error(text) {
    showMessage('error', text);
  }

  /*
   * Shows an info or error message and hides it with a length-dependent delay.
   */
  function showMessage(type, text) {
    var messageBox = '#' + type + '_box';
    $('#message_container').children().stop().hide().end().
      find(messageBox + ' .message').html(text).end().
      find(messageBox).slideDown().animate({opacity: 1.0}, 5000 + text.length*50).slideUp();
  }

  /* loads form ajaxs */
  function loadAjaxForms() {
    $('form.ajax_form').livequery(function () {
      $(this).ajaxForm({
				dataType : 'script',
				beforeSubmit: function() {
					if ($(this).hasClass('disabled')) { return false; } 
					else { return true; }
				}
		  });
    });
  }

  /* TODO: Load the upload picture forms here */
  function uploadFormSubmit(){
  	$('#dialogContent .upload_form').livequery(function(){
  		var element = $(this);
  		element.submit(function(){
  			$(this).ajaxSubmit({
  				beforeSend: function(){
  					$(document).trigger("upload_started");
  					$('#uploading_progress').show();
  				},
  				complete: function(){
  					$('#uploading_progress').hide();
  				},
  				success: function(data, status){
  					$.ajax({
  						type: 'get',
  						dataType: 'script',
  						url: element.data('image-redirect'),
  						complete: function(data, status){
  							$(document).trigger("upload_finished");
  						},
  						error: function(){
  							$(document).trigger("upload_finished");
  						}
  					});
  					$('#dialogContent').dialog('close');
  				},
  				error: function(){
  					$(document).trigger("upload_finished");
  				}
  			});
  		});
  	});
  }

  /**************************************/
  /* Handling specific functional units */
  /**************************************/

  /*
   * Initializes the SignInUp panel with the echo and remote social accounts.
   */
  function initSigninup() {
		$('.signinup_container').livequery(function() {
      var signinup = $(this);
      signinup.find('.signinup_toggle_button').click(function() {
        var to_show = $(this).attr('href');
        $(to_show).show();
        $(this).parents('.signinup_container').hide();
        return false;
      });
      signinup.find('#user_session_email').focus();

      // Init remote provider handling
      signinup.find('.remote_signinup').remoteSigninup();
		});
	}

  /*
   * Initializes the About us function.
   */
  function initAboutUs() {
    $('#about_container').livequery(function() {
      $('#about_team_link').click(function() {
        $('#about_container').tabs('select', 1);
        return false;
      });
      $(this).bind('tabsshow', function(event, ui) {
        if (ui.panel.id == "team") {
          $('#team_members').jScrollPane({animateTo: true, wheelSpeed: 25});
        }
				if (ui.panel.id == "partners") {
          $('#partner_orgas').jScrollPane({animateTo: true, wheelSpeed: 25});
        }
      });
    });
  }


  /*****************************************/
  /* Redirection and browsers interactions */
  /*****************************************/

  /*
   * Redirects to the given URL after session expire.
   */
  function redirectToUrl(controller, url) {
    switch(controller) {
      case 'statements': redirectToStatementUrl();
      break;
      default: window.location.replace(url);
    }
  }

  /*
   * Opens a popup browser window with the given URL and window name.
   * Currently it is used to call 3rd party authentication services.
   *
   * callback: called when the window gets closed.
   */
  function popup(url, callback) {
    if (!window.focus) {
      return true;
    }
    var href;
    if (typeof(url) == 'string') {
      href = url;
    }
    else {
      href = url.href;
    }
    var view = $(window);
    var left = (view.width() - 800) / 2;
    var popup = window.open(href, true, 'width=800,height=450,left=' + left + ',top=70,scrollbars=yes,dependent=yes');
    if (callback) {
      popup.onunload = popupClosed(popup, callback);
    }
    return false;
  }

  /*
   * Helper function to handle the callback call on closing the popup.
   */
  function popupClosed(popup, callback) {
    setTimeout(function() {
      if (popup.closed) {
        callback();
      } else {
        popup.onunload = popupClosed(popup, callback);
      }
    }, 500);
  }

  /*
   * Opens the given target URL in the opener window and closes the popup window.
   */
  function openUrlInParentWindow(targetUrl, closeme) {
    if (!(window.focus && window.opener)) {
      return true;
    }
    window.opener.focus();
    if (typeof(targetUrl) == 'string') {
      window.opener.location.href = targetUrl;
    } else {
      window.opener.location.href = targetUrl.href;
    }
    if (closeme) {
      window.close();
    }
    return false;
  }


  /***************************/
  /* General utility methods */
  /***************************/

  /*
   * Returns true if the application is currently being run on a mobile device.
   */
	function isMobileDevice() {
    var userAgent = navigator.userAgent.toLowerCase();
		return userAgent.match(/android/i) ||
           userAgent.match(/iphone/i) ||
           userAgent.match(/ipod/i) ||
           userAgent.match(/ipad/i) ||
           userAgent.match(/webos/i) ||
           userAgent.match(/palm/i) ||
           userAgent.match(/blackberry/i) ||
           userAgent.match(/windows ce/i);
	}


  /*****************************/
  /* Applied jQuery extensions */
  /*****************************/

  /*
   * Selects the text of a given DOM element with browser-specific logic.
   */
  $.fn.selText = function() {
    var range, selection;
    var obj = this[0];
    if ($.browser.msie) {
      range = obj.offsetParent.createTextRange();
      range.moveToElementText(obj);
      range.select();
    } else if ($.browser.mozilla || $.browser.opera) {
      selection = obj.ownerDocument.defaultView.getSelection();
      range = obj.ownerDocument.createRange();
      range.selectNodeContents(obj);
      selection.removeAllRanges();
      selection.addRange(range);
    } else if ($.browser.safari) {
      selection = obj.ownerDocument.defaultView.getSelection();
      selection.setBaseAndExtent(obj, 0, obj, 1);
    }
    return this;
  };