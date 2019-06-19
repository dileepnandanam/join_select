initLightScroll = function() {
  window.onscroll = function() {
    if($(window).height() + 600 + document.documentElement.scrollTop > $('body').height()) {
      Rails.fire($('.view-more')[0], 'click')
    }
  }
  $(document).on('ajax:success', '.view-more', function(e) {
    $(this).closest('.more-items').replaceWith(e.detail[2].responseText)
  })
}
$(document).on('turbolinks:load', function() {
  initLightScroll()
})
$(document).ready(function(){
  initLightScroll()
})
