                  //panel_l_slide   : slide left
                  //panel_l_m_slide : slide left with mouse enter
                  //panel_t_slide   : slide top
                  //panel_t_m_slide : slide top with mouse enter
                  //attribut alt='' pour donner un texte au bouton
                  
                    $(document).ready(function() { 
                        // Hide menu once we know its width
						var $slide_t;
						var $slide_l;
						if ($('.panel_l_slide,.panel_l_m_slide').length)
						{
							$( 'body' ).prepend('<div class="container" style="padding-left:0;"> <div class="row"> <div id="body_panel" class="col-md-11"></div></div></div>');
							$body = $( '#body_panel' );
							$( 'body' ).children().each(function( index,obj ) {
								if(index>0)
								{
									$body.append(obj);
								}	
							});
							$( '#body_panel' ).before('<div id="slide_l" class="col-md-1" style="position:relative;left:1px;"><UL class="nav nav-pills" style="list-style:none outside none;"></UL></div>');
							$slide_l = $( '#slide_l > UL' ); 
						}
						if ($('.panel_t_slide,.panel_t_m_slide').length)
						{
							$( 'body' ).prepend('<div id="slide_t" style="position:relative;left:' + $('#slide_l').outerWidth() + 'px;"><UL class="nav nav-pills"></UL></div>');
							$slide_t = $( '#slide_t > UL' ); 
						}

                        $(".panel_t_slide, .panel_t_m_slide").each(function( index ) {
                        	$this = $( this );
                            $this.hide();
                        	id = "panel_t_slide_" + index;
                        	$this.parent().append('<div id="' + id + '"></div>');
                        	$this.css("display","inline-block");
                        	div =  $("#" + id );
                        	div.append($this);
                        	text = $this.attr('alt');
							if ($this.hasClass( "panel_t_m_slide" ))
	                        	$slide_t.append('<LI style="display:inline-block;">&nbsp;<a href="#" style="display:inline-block;" class="btn_slide_t_m" id="btn_slide_t_' + index + '">' + text + '</a></LI>');
                        	else
	                        	$slide_t.append('<LI style="display:inline-block;">&nbsp;<a href="#" style="display:inline-block;" class="btn_slide_t" id="btn_slide_t_' + index + '">' + text + '</a></LI>');
                        	btn = $('#btn_slide_t_' + index);
                        	div.css({"left" : btn.offset().left, 
                        			 "top" : -(div.outerHeight() + 100),
								     "position" : 'fixed',
								     "z-index" : 9999});                        	
                        });

                        $('.btn_slide_t_m').mouseenter(function() {
                        	id = 'panel_t_slide_' + $(this).attr('id').substring(12);
                            $div = $('#' + id);
                            if ($div.offset().top == -($div.outerHeight() + 10)) { 
	                        	$('.panel_t_slide,.panel_t_m_slide').each(function( index ) {	    
	                        		if ($( this ).parent().attr('id') != id)                    		
		                        		$( this ).parent().animate({top: -($( this ).parent().outerHeight() + 100)}); 
	                        	});	
                                // Slide in 
                                //panel = $($div.children()[1]);
                                panel = $slide_t.parent();
                                $div.animate({left: $(this).offset().left, top: panel.outerHeight() + 10},500, function() { 
                                });  
                            } 
                        }); 
                        	
                        $('.btn_slide_t, .btn_slide_t_m').click(function() { 
                        	id = 'panel_t_slide_' + $(this).attr('id').substring(12);
                            $div = $('#' + id);
                            if ($div.css('top').substring(0,1) == '-') { 
	                        	$('.panel_t_slide,.panel_t_m_slide').each(function( index ) {	
		                        	$( this ).parent().animate({top: -($( this ).parent().outerHeight() + 100)},200); 
	                        	});	
                                // Slide in 
                                //panel = $($div.children()[1]);
                                panel = $slide_t.parent();
                                $div.animate({left: $(this).offset().left, top: panel.outerHeight() + 10},500, function() { 
                                });  
                            } 
                            else { 
                                // Slide away 
                                panel = $($div.children()[0]); 
                                panel.show();
                                $div.animate({top: -($div.outerHeight() + 100)},500, function() { 
                                }); 
	                           
                            } 
                        }); 
                        


                        $(".panel_l_slide, .panel_l_m_slide").each(function( index ) {
                        	$this =$( this );
                            $this.hide();
                        	id = "panel_l_slide_" + index;
                        	$this.parent().append('<div id="' + id + '"></div>');
                        	$this.css("display","inline-block");
                        	div =  $("#" + id );
                        	div.append($this);
                        	text = $this.attr('alt');
							if ($this.hasClass( "panel_l_m_slide" ))
	                        	$slide_l.append('<LI style="margin-left:0;"><a href="#" class="btn_slide_l_m" id="btn_slide_l_' + index + '">' + text + '</a></LI>');
                        	else
	                        	$slide_l.append('<LI style="margin-left:0;"><a href="#" class="btn_slide_l" id="btn_slide_l_' + index + '">' + text + '</a></LI>');
                        	btn = $('#btn_slide_l_' + index);
                        	div.css({"left" : -($this.outerWidth()),
								     "position" : 'fixed',
								     "top" : btn.offset().top + btn.outerHeight(),
								     "z-index" : 9999});
                        });
                         
                        $('.btn_slide_l_m').mouseenter(function() {
                        	id = 'panel_l_slide_' + $(this).attr('id').substring(12);
                            $div = $('#' + id);
                            if ($div.offset().left == -$div.outerWidth()) { 
	                        	$('.panel_l_slide,.panel_l_m_slide').each(function( index ) {	    
	                        		if ($( this ).parent().attr('id') != id)                    		
		                        		$( this ).parent().animate({top: -$( this ).parent().outerWidth()}); 
	                        	});	
                                // Slide in 
                                panel = $slide_l;
                                $div.animate({left: $(this).offset().left, top: $(this).offset().top + $(this).outerHeight()},500, function() { 
                                });  
                            } 
                        }); 

                        $('.btn_slide_l, .btn_slide_l_m').click(function() { 
                        	id = 'panel_l_slide_' + $(this).attr('id').substring(12);
                            $div = $('#' + id);
                            if ($div.css('left').substring(0,1) == '-') { 
	                        	$('.panel_l_slide,.panel_l_m_slide').each(function( index ) {	                        		
		                        	$( this ).parent().animate({left: -($( this ).parent().outerWidth())},200); 
	                        	});	
                                // Slide in 
                                panel = $slide_l;
                                $div.animate({left: $(this).offset().left, top: $(this).offset().top + $(this).outerHeight()},500, function() { 
                                });  
                            } 
                            else { 
                                // Slide away 
                                panel = $($div.children()[0]); 
                                panel.show();
                                $div.animate({left: -(panel.outerWidth())},500, function() { 
                                }); 
	                           
                            } 
                        }); 
                    }); 
