(function($) {

  $.widget("echo.alternative", {

    options: {
      highlight_color : '#21587F',
      normal_mode_color : '#888888'
    },

    _create: function() {
      var that = this,
          alternative = that.element;

      that.statementApi = alternative.data('statement');
      that.alternatives = alternative.find('.alternatives');
      that.teaser = that.alternatives.find('.teaser');

      // statement is an alternative
      that.closeButton = alternative.find('.alternative_close');
      that._initCloseButton();
    },

    _initPanel: function() {
      var that = this;
      that.alternatives.bind('mouseover', function() {
        that._panelHighlight();
      });
      that.alternatives.bind('mouseleave', function() {
        that._panelNormal();
      });
    },

    _initCloseButton: function() {
      var that = this,
          alternative = that.element;

      that.closeButton.bind('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var statementApi = alternative.data('statement');
        var targetStack = statementApi.getStatementsStack(this, false);

        // BIDS
        // Logic: parent key will be the alternatives breadcrumb, so return the bids til the previous bid
        var currentBids = $('#breadcrumbs').data('breadcrumbs').getBreadcrumbStack(null),
              parentKey = statementApi.getParentKey(),
              parentIndex = $.inArray(parentKey, currentBids),
              targetBids = currentBids.splice(0, parentIndex);

        // Save element after which the breadcrumbs will be deleted while processing the response
        $('#breadcrumbs').data('element_clicked', targetBids[targetBids.length - 1]);
        // ORIGIN
        origin = getState("origin");
        // AL
        var al = statement.data('api').getTargetAls(false);
        pushState({
          "sids": targetStack.join(','),
          "nl": true,
          "bids": targetBids.join(','),
          "origin": origin,
          "al": al.join(',')
        }, that.statementApi);
        var path = $.param.querystring(statementApi.getStatementUrl(), {
          "current_stack" : targetStack.join(','),
          "nl" : true,
          "al" : al.join(',')
        });
        $.getScript(path);
      });
    },

    _panelHighlight: function() {
      var that = this;
      that.alternatives.find('a.statement_link').animate({color : that.options.highlight_color}, 100);
      return that;
    },

    _panelNormal: function() {
      var that = this;
      that.alternatives.find('a.statement_link').animate({color : that.options.normal_mode_color}, 100);
      return that;
    },

    highlight: function() {
      // panelHighlight();
      this.teaser.fadeIn(120);
    },

    normal_mode: function() {
      // panelNormal();
      this.teaser.fadeOut(120);
    }

  });
}(jQuery) );
