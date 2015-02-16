
$(document).ready(function(){
	$('.linkpicker').linkPicker();
  	});

jQuery.fn.linkPicker = function() {
  return this.each(function(){
 
    // Get input field
    var sel = this;
 
    var rel_id = $(sel).attr('rel')
    if(typeof rel_id === "undefined") { rel_id = 'nothing';}

	$(sel).click(function(ev) {
 
        ev.preventDefault();

		url = $('#' + rel_id).val();
		if (url!="")
		{
			if (url.toLowerCase().match("^http://") || url.toLowerCase().match("^https://"))      
				window.open(url, '_blank');
			else
				window.open('http://' + url, '_blank');
		}	
                    
//	  	$(div).offset({ top: $(sel).offset().top + $(sel).outerHeight(), left: $(sel).offset().left});
 
        // Blur field
        return false;
		
	});


  });
 
};


