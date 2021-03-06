$(document).ready(function(){
	$('.fontpicker').fontSelector();
  	});

jQuery.fn.fontSelector = function() {
  var fonts = new Array(
'/',
'Arial,Arial,Helvetica,sans-serif',
'Arial Black,Arial Black,Gadget,sans-serif',
'Comic Sans MS,Comic Sans MS,cursive',
'Courier New,Courier New,Courier,monospace',
'Georgia,Georgia,serif',
'Impact,Charcoal,sans-serif',
'Lucida Console,Monaco,monospace',
'Lucida Sans Unicode,Lucida Grande,sans-serif',
'MV Boli',
'Palatino Linotype,Book Antiqua,Palatino,serif',
'Tahoma,Geneva,sans-serif',
'Times New Roman,Times,serif',
'Trebuchet MS,Helvetica,sans-serif',
'Verdana,Geneva,sans-serif' );
 
  return this.each(function(){
 
    // Get input field
    var sel = this;
 
    // Add a ul to hold fonts
    var ul = $('<ul class="fontselector"></ul>');
    $(sel).after(ul);
    $(ul).hide();
 
    jQuery.each(fonts, function(i, item) {
 
      $(ul).append('<li><a href="#" class="font_' + i + '" style="font-family: ' + item + '">' + item.split(',')[0] + '</a></li>');
 
      // Prevent real select from working
    });
    
    $(sel).focus(function(ev) {
 
      ev.preventDefault();
 
      // Show font list
      $(ul).toggle();
 
      // Position font list
//      $(ul).css({ top:  $(sel).offset().top + $(sel).height() + 4,
 //                 left: $(sel).offset().left});

	  $(ul).offset({ top: $(sel).offset().top + $(sel).outerHeight(), left: $(sel).offset().left});
 
      // Blur field
      $(this).blur();
      return false;
    });
 
    $(ul).find('a').click(function() {
      var font = fonts[$(this).attr('class').split('_')[1]];
      if (font=='/') font='';
      $(sel).val(font);
      $(ul).hide();
      return false;
    });
 
 	$(ul).mouseleave(function(ev) {
        ev.preventDefault();
        $(ul).hide();
        return false;
	});

  });
 
};


