
  function initpostit(){ 

	$( document ).ready(function() {    

	    if ( $('#divpos_postit').length==0){
	        $('body').append("<div id='divpos_postit' data-posx='0' data-posy='0' style='display:none;'></div>");
	    }

	    $(document).mousedown(function(e){
	        $('#divpos_postit').data('posx',e.pageX);
	        $('#divpos_postit').data('posy',e.pageY);
	        /*$('#divpos_postit').text(e.pageX + ' ' + e.pageY);*/
	    }); 



        $(".stickyNote").each(function(index, value) {      
                $( this ).resizable(); 
                $( this ).draggable();  
                $( this ).css({top: index * 10, left: index * 10, position: "absolute", display: "inline", border:"1px solid #aaaaaa"});

                $( this ).prepend( "<span class='delete ui-icon ui-icon-closethick' style='float: right;'></span>" ); 

        }); 
        
        $(".stickyNote .delete").on('click', function() {      
                $( this ).parent().hide(); 
        }); 




        $(".property_windows").each(function(index, value) {      
                /*$( this ).resizable();*/ 
                $( this ).draggable();  
                $( this ).addClass("well");
                $( this ).css({ 'z-index': 802, position: "absolute", display: "inline", border:"1px solid #ffffff", border:"1px solid #000000"});
                $( this ).prepend( "<span class='delete ui-icon ui-icon-closethick' style='float: right;'></span>" ); 
                $(this).offset({ top: $('#divpos_postit').data('posy') - ($(this).height() / 2), left: $('#divpos_postit').data('posx')});
				tmpx = $(this).position().left;
                $( this ).hide();
                $(this).offset({ left: $( document ).width()});
                $( this ).show();
				                
                $(this).animate({left: tmpx}, 500)

        }); 
        
        $(".property_windows .delete").on('click', function() {      
                $( this ).parent().hide(); 
        }); 


	});
  };



  function init_one_property(id_property){ 

	$( document ).ready(function() {    

	    if ( $('#divpos_postit').length==0){
	        $('body').append("<div id='divpos_postit' data-posx='0' data-posy='0' style='display:none;'></div>");
	    }

	    $(document).mousedown(function(e){
	        $('#divpos_postit').data('posx',e.pageX);
	        $('#divpos_postit').data('posy',e.pageY);
	    }); 


        $("#" + id_property).each(function(index, value) {      
            $( this ).draggable();  
            $( this ).addClass("well");
            $( this ).css({ 'z-index': 802, position: "absolute", display: "inline", border:"1px solid #ffffff", border:"1px solid #000000"});
            $( this ).prepend( "<span class='delete ui-icon ui-icon-closethick' style='float: right;'></span>" ); 
            x = $('#divpos_postit').data('posx');
            if (x>($( window ).width()*3/4))
            	x=$('#divpos_postit').data('posx') - $(this).width() - 50;
            $(this).offset({ top: $('#divpos_postit').data('posy') - ($(this).height() / 2), left: x});
			tmpx = $(this).position().left;
            $( this ).hide();
            $(this).offset({ left: $( document ).width()});
            $( this ).show();
			                
            $(this).animate({left: tmpx}, 500)
        }); 

        $("#" + id_property + " .delete").on('click', function() {      
                $( this ).parent().hide(); 
        }); 
	});
  };

