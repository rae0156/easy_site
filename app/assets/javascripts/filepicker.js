
/*
 * add the class 'window_fixed' with filepicker to have a windows fixed
 */


$(document).ready(function(){
	$('.filepicker').fileSelector();
  	});

jQuery.fn.fileSelector = function() {
  return this.each(function(){
 
    // Get input field
    var sel = this;
 
    // Add a ul to hold fonts
    var div = $('<div id="fileTreeimage" class="fileTreeview"></div>');
    $(sel).after(div);
    $(div).hide();
    var dir = $(sel).attr('rel').split(';')[0]
    var script = $(sel).attr('rel').split(';')[1]
    var extention = $(sel).attr('rel').split(';')[2]
    var enabled = $(sel).attr('rel').split(';')[3]
    
    if(typeof dir === "undefined") { dir = 'public';}
    if(typeof script === "undefined") { script = '';}
    if(typeof extention === "undefined") { extention = '*';}
    if(typeof enabled === "undefined") { enabled = '';}
    
    extention = '?typefile=' + extention
    dir = '*' + dir
     
    $(div).fileTree({ root: dir, script: script + extention }, function(file) {
        $(sel).val(file);
        /*$(div).hide();*/
        return false;

    });
/*
	$(sel).focus(function(ev) {
		
	});
*/
	$(sel).keypress(function(ev) {
		$(div).hide();
	});

	$(sel).click(function(ev) {
 
        ev.preventDefault();
 
        // Show font list
        $(div).toggle();
 
        // Position font list
//        $(div).css({ top:  $(sel).offset().top + $(sel).height() + 4,
//                    left: $(sel).offset().left});
                    
	  	$(div).offset({ top: $(sel).offset().top + $(sel).outerHeight(), left: $(sel).offset().left});
 
        // Blur field
        if (enabled != 'enabled')
        	$(this).blur();
        return false;
		
	});

	$(div).mouseleave(function(ev) {
        ev.preventDefault();
        $(div).hide();
        return false;
	});

  });
 
};


