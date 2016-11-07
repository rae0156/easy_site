// ajouter la class drag_drop_template à un div pour déclencher le processus drag and drop 

  function init_dragdrop_template(){ 
		$(document).ready(function() { 
			
			$( ".drag_drop_template > div" ).addClass( "drag_drop" );
			$( ".drag_drop > [id^=element_part_]" ).addClass( "templet" ); // id commence par 'element_part_'    
			$( ".drag_drop > [id^=template_part_]" ).addClass( "templet" ); // id commence par 'element_part_'    

			$( ".drag_drop > div.no_drag_drop" ).removeClass( "templet" );

			
			set_id_grag_drop();
			
			$( ".drag_drop" ).sortable({
						connectWith: ".drag_drop",
		//				handle: ".templet-header",
						cancel: ".label.label-info",
						items: ".templet",  //div.templet
						cursor: "move",
						opacity: 0.5,
						revert: true,
						placeholder: "templet-placeholder ui-corner-all",
						start: function(e, ui ){							
							is_template = (ui.helper.attr('id').substring(0, 14)=='template_part_');
							tmp_display = document.getElementById(ui.helper.attr('id')).style.display; // ne marche pas avec .css('display') de Jquery
							ui.placeholder.css('display',tmp_display);
     						ui.placeholder.height(ui.helper.outerHeight());
							if (!is_template)
							{
	     						ui.placeholder.width(ui.helper.outerWidth());
							}
						},
						stop: function( event, ui ) {set_id_grag_drop();}
						});
			$( ".templet" )
			.addClass( "ui-widget ui-corner-all" ); //ui-helper-clearfix ui-widget-content
		//	.find( ".templet-header" )
		//	.addClass( "ui-widget-header ui-corner-all" );
		
		/*	
			.prepend( "<span class='ui-icon ui-icon-minusthick templet-toggle'></span>");
			$( ".templet-toggle" ).click(function() {
				var icon = $( this );
				icon.toggleClass( "ui-icon-minusthick ui-icon-plusthick" );
				icon.closest( ".templet" ).find( ".templet-content" ).toggle();
				});
		*/			
		
		}); 
  };
                  

var template_parts=[];

function set_id_grag_drop(){
	template_parts=[];
	$( ".drag_drop" ).each(function(index_part){
		var template_part = {};
		$column = $(this);
		$column.attr('num_part',index_part+1);
		$column.find('.templet').each(function(index_row){
			$row = $(this);
			parent_id = $row.parent().attr('parent_id');
			col_id = $row.parent().attr('col_id');
			temp_attr = {
							num_part: index_part + 1,
							num_row: index_row + 1,
							parent_id: parent_id,
							col_id: col_id
						}; 
						
			$row.attr(temp_attr);
			template_part[$row.attr('id')]=temp_attr;
		});
		template_parts.push(template_part);
	});
	//get_template_parts();
};

function get_template_parts(){
/*
	result="";
	template_parts.forEach(function(elem){
		$.each(elem,function( key, prop ) {
			p_text = key + " : \n";
			$.each(prop,function( p_name, p_value ) {
				p_text += "  - " + p_name + " -> " + p_value + "\n";
			});
			result += p_text + '\n';
		});
	});
	alert(result);
*/	
	return template_parts;
};

init_dragdrop_template();
