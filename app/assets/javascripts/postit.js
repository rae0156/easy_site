
  function initpostit(){ 
	$( document ).ready(function() {    
        $(".stickyNote").each(function(index, value) {      
                $( this ).resizable(); 
                $( this ).draggable();  
                $( this ).css({top: index * 10, left: index * 10, position: "absolute", display: "inline", border:"1px solid #aaaaaa"});

                $( this ).prepend( "<span class='delete ui-icon ui-icon-closethick'></span>" ); 

        }); 
        
        $(".stickyNote .delete").on('click', function() {      
                $( this ).parent().hide(); 
        }); 
	});
  };
