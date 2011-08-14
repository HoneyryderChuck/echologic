(function($) {

  $.fn.remoteSigninup = function(currentSettings) {

    $.fn.remoteSigninup.defaults = {
      'animation_speed': 250
    };

    // Merging current settings with defaults
    var settings = $.extend({}, $.fn.remoteSigninup.defaults, currentSettings);

    return this.each(function() {
			// Creating and binding the signinup API
			var elem = $(this);
      var signinupApi = elem.data('signinupApi');
	    if (!signinupApi) {
				signinupApi = new RemoteSigninup(elem);
	      elem.data('signinupApi', signinupApi);
	    }
		});


    /*******************************/
    /* The remote signinup handler */
    /*******************************/

    function RemoteSigninup(signinup) {

      var providersPanel = signinup.find('.remote_providers');
      var inputPanel = signinup.find('.remote_input_panel');
      var providerInput = inputPanel.find('.provider_input');
      var busySign = signinup.find('.busy_sign');

      var tokenUrl;
      var providers;
      var inputMode, inputProvider;
      var busy;

      // Initialize the signinup panel
      initialize();

      /*
       * Initializes the signinup panel.
       */
      function initialize() {

        // Getting the token URL
        tokenUrl = signinup.data('token-url');
        signinup.removeAttr('data-token-url');

        // Initializing all providers
        providers = signinup.find('.provider').each(function() {
          var provider = $(this);
          provider.data('providerName', provider.data('provider-name'));
          provider.data('providerUrl', provider.data('provider-url'));
          provider.data('requiresInput', provider.data('requires-input'));
          provider.removeAttr('data-provider-name').removeAttr('data-provider-url').removeAttr('data-requires-input');
          if (provider.data('requiresInput')) {
            provider.data('inputDefault', provider.data('input-default'));
            provider.removeAttr('data-input-default');
          }

          provider.click(function() {
            if (!provider.data('requiresInput')) {
              callProvider(provider, null);
            } else {
              promptForInput(provider);
            }
          });
        });

        // Input panel
        inputPanel.find('.back_button').click(function() {
          chooseProvider();
        });
        inputPanel.find('.signinup_button').click(function() {
          callProviderWithInput();
        });
        providerInput.keypress(function(e) {
          if (e.keyCode == 13) {
            callProviderWithInput();
          }
        });

      }

      /*
       * Switches to the input panel to get the additional info from the user.
       */
      function promptForInput(provider) {
        if (busy) { return; }

        inputMode = true;
        inputProvider = provider;

        if (inputPanel.data('provider')) {
          inputPanel.removeClass(inputPanel.data('provider'));
        }
        var providerName = provider.data('providerName');
        inputPanel.data('provider', providerName).addClass(providerName);

        providersPanel.fadeOut(settings['animation_speed']);
        inputPanel.fadeIn(settings['animation_speed']);

        providerInput.toggleVal({
          populateFrom: 'custom',
          text: provider.data('inputDefault'),
          changedClass: 'changed',
          focusClass: 'focused'
        });

        busySign.addClass('input');
      }

      /*
       * Switches to the providers panel to let the user choose a different provider.
       */
      function chooseProvider() {
        if (busy) { return; }

        inputMode = false;
        inputPanel.fadeOut(settings['animation_speed']);
        providersPanel.fadeIn(settings['animation_speed']);

        busySign.removeClass('input');
      }


      /*
       * Calls the provider according to the user input.
       */
      function callProviderWithInput() {
        var input = providerInput.val();
        if (input.length > 0) {
          callProvider(inputProvider, input);
        } else {
          providerInput.focus();
        }
      }

      /*
       * Calls the provider's URL with the token URL to return to.
       * The 'input', if defined, also gets substituted into the URL.
       */
      function callProvider(provider, input) {
        if (busy) { return; }

        var finalUrl = provider.data('providerUrl').replace("{url}", tokenUrl);
        if (input) {
          finalUrl = finalUrl.replace("{input}", input)
        }
        setBusy(true);
        popup(finalUrl, function() {
          setBusy(false);
        });
      }


      /*
       * Sets the busy state of the signinup component.
       */
      function setBusy(value) {
        busy = value;
        if (busy) {
          busySign.show();
        } else {
          busySign.hide();
        }
      }

	  }
  };
})(jQuery);


