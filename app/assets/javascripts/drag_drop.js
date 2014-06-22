// ajouter la class drag_drop_template à un div pour déclencher le processus drag and drop 
                  
$(document).ready(function() { 
	
	$( ".drag_drop_template > div" ).addClass( "drag_drop" );
	$( ".drag_drop > div" ).addClass( "templet" );
	
	set_id_grag_drop();
	
	$( ".drag_drop" ).sortable({
				connectWith: ".drag_drop",
//				handle: ".templet-header",
//				cancel: ".templet-toggle",
				cursor: "move",
				opacity: 0.5,
				revert: true,
				placeholder: "templet-placeholder ui-corner-all",
				stop: function( event, ui ) {set_id_grag_drop();}
				});
	$( ".templet" )
	.addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" );
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

var template_parts=[];

function set_id_grag_drop(){
	template_parts=[];
	$( ".drag_drop" ).each(function(index_col){
		var template_part = {};
		$column = $(this);
		$column.attr('num_col',index_col+1);
		$column.find('.templet').each(function(index_row){
			$row = $(this);
			temp_attr = {
							num_col: index_col + 1,
							num_row: index_row + 1
						}; 
			$row.attr(temp_attr);
			template_part[$row.attr('id')]=temp_attr;
		});
		template_parts.push(template_part);
	});
	get_template_parts();
};

function get_template_parts(){
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
//	alert(result);
};

