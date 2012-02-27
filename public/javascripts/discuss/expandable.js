(function($) {

  $.widget("echo.expandable", {

    options: {
      animate: true,
      animation_params : {
        height : 'toggle',
        opacity: 'toggle'
      },
      animation_speed: 300,
      loading_class: '.loading',
      parent_class : 'div:first',
      // SPECIAL CONDITION ELEMENTS
      condition_element: null,
      condition_class: ''
    },

    _create: function() {
      var that = this,
          expandable = that.element;

      that.expandableParent = expandable.parents(that.options.parent_class);
      that.expandableSupportersLabel = expandable.find('.supporters_label');
      that.expandableLoading = expandable.parent().find(that.options.loading_class);
      that.expandableContent = that.expandableParent.children('.expandable_content');

      that.path = expandable.attr('href') || expandable.data('href');
      expandable.removeData('href');

      if (that.expandableContent.length > 0)
        expandable.addClass("active");

      // Collapse/expand clicks
      expandable.bind("click", function(e) {
        e.preventDefault();
        e.stopPropagation();
        if (!that.options.condition_element)
          that._toggleExpandable();
        else if (that.options.condition_element.hasClass(that.options.condition_class))
          that.options.condition_element.hasClass('pending') ?
                 expandable.addClass('clicked') : that._toggleExpandable();
      });
    },

    _toggleExpandable: function() {
      var that = this,
          expandable = that.element;

      if (that.expandableContent.length > 0) {
        // Content is already loaded
        expandable.toggleClass('active');

        that.options.animate ?
               that.expandableContent.animate(that.options.animation_params, that.options.animation_speed) :
               that.expandableContent.toggle();

        if (that.expandableSupportersLabel.length > 0)
          that.options.animate ?
                 that.expandableSupportersLabel.animate(that.options.animation_params, that.options.animation_speed) :
                 that.expandableSupportersLabel.toggle();

      } else if (!expandable.hasClass('pending')) {
        expandable.addClass('pending');

        // Load content now
        if (that.expandableLoading.length > 0) {
          that.expandableLoading.show();
        } else {
          that.expandableLoading = $('<span/>').addClass('loading');
          that.expandableLoading.insertAfter(expandable);
        }
        $.ajax({
          url: that.path,
          type: 'get',
          dataType: 'script',
          success: function() {
            that._activate();
          },
          error: function() {
            that.expandableLoading.hide();
            expandable.removeClass('pending');
          }
        });
      }
    },

    // Designates the expandable as active
    _activate: function () {
      var that = this,
          expandable = that.element;

      that.expandableLoading.hide();
      that.expandableContent = that.expandableParent.children('.expandable_content');
      if (that.expandableContent.length > 0)
        expandable.addClass('active');

      if (that.expandableSupportersLabel)
        that.options.animate ?
               that.expandableSupportersLabel.animate(that.options.animation_params, that.options.animation_speed) :
               that.expandableSupportersLabel.toggle();

      expandable.removeClass('pending');
    },

    toggle: function() {
      var that = this;
      that._toggleExpandable();
      return that;
    },

    activated: function() {
      var that = this;
      that._activate();
      return that;
    },

    isLoaded: function() {
      var that = this;
      return that.expandableContent != null && that.expandableContent.length > 0 && that.expandableContent.is(":visible");
    }

  });

}(jQuery) );
