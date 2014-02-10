/*use with jquery_ui*/

  function initajax(selector){ 
    var arr_obj = []; 

        $("[ajax_action]").each(function( index ) { 
                if (jQuery.inArray( selector, $(this).attr('ajax_action').split(','))>=0) 
                {
                	$( this ).css("position","relative")
                	$( this ).wrap( "<span class='autocompletion_rails'></span>").after("<ul class='ui-autocomplete ui-front ui-menu ui-widget ui-widget-content ui-corner-all'></ul>");
                	ul=$(this).siblings("ul");
					styles = {
						display: "none",
						top: this.offsetTop + this.offsetHeight,
						left: this.offsetLeft
					};
					ul.css( styles );                	
		          	ul.bind( "mouseleave", function() {
						$( this ).hide();
					});                	
                	
                	arr_obj.push(this);
                } 
          }); 

        $.each(arr_obj,function(index,obj){ 
                if (obj.type == 'text') 
                        $(obj).bind('keyup', function(e) { 
                                create_ajax_event(this,arr_obj) 
                        }); 
                else if (obj.type == 'checkbox' || obj.type == 'radio') 
                        $(obj).bind('click', function(e) { 
                                create_ajax_event(this,arr_obj) 
                        }); 
                else if (obj.type == 'select-one' || obj.type == 'select-multiple') 
                        $(obj).bind('change', function(e) { 
                                create_ajax_event(this,arr_obj) 
                        }); 
        }); 


    }; 

	function create_list_autocompletion(data_completion,arr_obj) { 
        $.each(arr_obj,function(index,obj){ 
			ul=$(obj).siblings("ul").empty();
            jQuery.each( data_completion[obj.name], function( i, elem ) { 
				li=$( "<li class='ui-menu-item' id='" + elem + "'></li>" )
	            .append( "<a>" + elem + "</a>")
	            .appendTo( ul );
	           	li.click(function() {
					obj.value=$(this).children()[0].text;
					$(this).parent().css("display", "none");
					$(obj).focus();
				});

            }); 
        }); 
    }; 

	function create_ajax_event(obj,arr_obj) { 
	    var values = {}; 
	    var action = $(arr_obj[0]).attr('ajax_action');
	    var tmp_url = $(location).attr('pathname');

	    if (action.split('/').length <= 1)
	    {
		    if (tmp_url.split('/').length > 1)
		    	action = tmp_url.split('/')[1] + '/' + action;
		    else
		    	action = $(location).attr('host') + '/' + action;
	    }
	    	
        $.each(arr_obj,function(index,obj){ 
            objs = $(obj).serializeArray(); 
            if (objs.length == 0) 
               values['ajax_param[' + obj.name + ']']=''; 
            jQuery.each( objs, function( i, field ) { 
                if (objs.length < 2) 
                        values['ajax_param[' + field.name + ']'] =field.value; 
                else 
                        values['ajax_param[' + field.name + '][' + i + ']'] = field.value; 
            }); 
                
        }); 

        $.ajax({ 
            type: 'POST',
            url: action, 
            data: values,
            dataType: 'script'
        }); 

        $.ajax({ 
            type: 'POST',
            url: action, 
            data: values,
            dataType: 'json',
            success: function(data){
		            	if ('autocompletion' in data) 
			            {	
			            	create_list_autocompletion(data.autocompletion,arr_obj);
			            	ul=$(obj).siblings("ul").css("display","inline-block");
			            }
				    }
        }); 
	};



  
	$( document ).ready(function() {
	    var arr_action = []; 
	    $("[ajax_action]").each(function( index ) {   	
	    	$.each($(this).attr('ajax_action').split(','), function( index, value ) {
		        if (jQuery.inArray( value, arr_action)<0) 
		        { 
					arr_action.push(value); 
					initajax(value); 
		        } 
			});
	    });
	});

  

