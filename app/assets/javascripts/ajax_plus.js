/*use with jquery_ui*/


/*******************/
/* use ajax_action */
/*******************/

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
        	autocompletion = false
        	if ($(obj).attr('ajax_action_auto'))
        	{
        		autocompletion = $(obj).attr('ajax_action_auto').length > 0;
        	}
        	
                if (obj.type == 'text') 
                        $(obj).on('keyup', function(e) { 
                                create_ajax_event(this,arr_obj,autocompletion) 
                        }); 
                else if (obj.type == 'checkbox' || obj.type == 'radio') 
                        $(obj).on('click', function(e) { 
                                create_ajax_event(this,arr_obj,autocompletion) 
                        }); 
                else if (obj.type == 'select-one' || obj.type == 'select-multiple') 
                        $(obj).on('change', function(e) { 
                                create_ajax_event(this,arr_obj,autocompletion) 
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

	function create_ajax_event(obj,arr_obj,autocompletion) { 
	    var values = {}; 
	    var action = $(arr_obj[0]).attr('ajax_action');
	    var tmp_url = $(location).attr('pathname');
	    var action_auto = "";

        if (action=='') 
        {
        	return false;
        }
                        
		if (autocompletion)
		{
			action_auto = $(arr_obj[0]).attr('ajax_action_auto');
		}

        if (action.split('/').length <= 1) 
        { 
            if (tmp_url.split('/').length > 1) 
            { 
                tmp_action 		= tmp_url.split('/'); 
                tmp_action_auto = tmp_url.split('/'); 

                if ($(location).attr('protocol') == 'http:') 
                {
                	tmp_action[2] 		= action;
                	tmp_action_auto[2]  = action_auto;
                }     
                else
                {
                    tmp_action[3] 		= action;                         
                	tmp_action_auto[3]  = action_auto;
                } 
                action 		= tmp_action.join('/'); 
                action_auto = tmp_action_auto.join('/'); 
            } 
            else 
            {
                action 		= $(location).attr('host') + '/' + action; 
                action_auto = $(location).attr('host') + '/' + action_auto; 
            }
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

		if (autocompletion == true)
		{
			alert(action_auto);
	        $.ajax({ 
	            type: 'POST',
	            url: action_auto, 
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
		}
      
	};



  
  function initajaxplus(){ 
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
  };

  

