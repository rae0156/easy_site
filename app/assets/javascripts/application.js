// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui-1.10.3.custom
//= require jqueryFileTree
//= require ajax_plus
//= require_tree ./bootstrap
//= require ./bootstrap-datetimepicker/bootstrap-datetimepicker
//= require_tree ./bootstrap-datetimepicker/locales/
//= require jquery.inputmask
//= require ./../tinymce/tinymce.min
//= require slide
//= require drag_drop
//= require jscolor/jscolor.js
//= require fontpicker.js
//= require filepicker.js
//= require linkpicker.js
//= require postit
//= require_tree ./treeview
// require_tree .


function checkAll(form_name) {
  var f = document.forms[form_name];
  var c = f['toggle_it'].checked;
  var i = 0;

  while (cb = eval('f.cb' + i)) {
    cb.checked = c;
    i ++;
  }
}

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
   $(function() {
//        $( ".datepicker" ).datepicker();
//		$('.datetimepicker').datetimepicker({dateFormat: 'yy-mm-dd ',controlType: 'select', timeFormat: 'HH:mm ', ampm: false});
//		$('.timepicker').timepicker({controlType: 'select',timeFormat: 'HH:mm ', ampm: false});
    });

/**
 * Submit the form with the specified name to the specified url
 */
function submitForm(form_name, url,remote) {
  var f = document.forms[form_name];

  if (url != '') {
    f.action = url;
    if (typeof f.onsubmit == 'function') {
      f.onsubmit = function() { new Ajax.Request(url, {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false; };
    }
    else
    {
    	if (remote)
		{
			$.ajax({
			        type: "POST",
			        url: $(f).attr('action'), 
			        data: $(f).serialize(),
			        dataType: "script"
			   });
			return false;    	
		}
    }
  }

  try {
    f.onsubmit();
  }
  catch (e) {
    f.submit();
  }
}

/**
 * Submit the form with the specified name to the specified url
 */
function submitAndDisableForm(form_name, url, div_to_hide) {
  var f = document.forms[form_name];

  if (url != '') {
    f.action = url;

    if (typeof f.onsubmit == 'function') {
      f.onsubmit = function() { new Ajax.Request(url, {asynchronous:true, evalScripts:true, parameters:Form.serialize(this)}); return false; };
    }
  }

  try {
  	WindowUtilities.disableScreen('alphacube', 'overlay_modal', 'spinner');
	$('spinner').show();
	$(div_to_hide).hide();
    f.onsubmit();
  }
  catch (e) {
    f.submit();
  }
}




/**
 * Check that at least one item has been selected, pops up a confirmation if needed
 * and submit the specified form to the specified url
 */
function checkAndSubmitAndDisableForm(form_name, url, confirmation, div_to_hide) {
  if (!isItemSelected(form_name)) { 
    alert('Aucun élément sélectionnés'); 
  } 
  else if (confirmation) {
    if (confirm('Voulez vous vraiment exécuter cette action sur les éléments sélectionnés ?')) {
      submitAndDisableForm(form_name, url, div_to_hide);
    }
  }
  else {
    submitAndDisableForm(form_name, url, div_to_hide);
  }
}

/**
 * Check that at least one item has been selected, pops up a confirmation if needed
 * and submit the specified form to the specified url
 */
function checkAndSubmitForm(form_name, url, confirmation,msg_confirm,msg_no_selected,remote) {
  if (!isItemSelected(form_name)) { 
    alert(msg_no_selected); 
  } 
  else if (confirmation) {
    if (confirm(msg_confirm)) {
      submitForm(form_name, url,remote);
    }
  }
  else {
    submitForm(form_name, url,remote);
  }
}


/**
 * Check if at least one checkbox is checked
 * Checkboxes have an id attribute in the form cb0, cb1...
 * But inside a page with multiple tables to distinguish ids the form name is used
 */
function isItemSelected(form_name) {
  var i = 0;
  var f = document.forms[form_name];
  var found = false;
  while ((cb = eval('f.cb' + i)) && (!found)) {
    if (cb.checked) {
      found = true;
    }
    i ++;
  }
  return found;
}

/**
 * Opens a dialog window by submiting an Ajax request to the specified url
 * The size of the window is controlled with the width and height parameters
 */
function openDialogWindow(url, width, height) {
  var win = new Window('dialogWindow', {className:"alphacube", width:width, height:height});
  win.setAjaxContent(url, {}, true, true);
  win.setDestroyOnClose();
}

/**
 * Check that at least one item has been selected and opens a dialog window by submiting 
 * an Ajax request to the specified url
 * The size of the window is controlled with the width and height parameters
 */
function checkAndOpenDialogWindow(form_name, url, width, height, confirmation) { 
  if (!isItemSelected(form_name)) {
    alert('Aucun élément sélectionnés');
  }
  else if (confirmation) {
    if (confirm('Voulez vous vraiment exécuter cette action sur les éléments sélectionnés ?')) {
      openDialogWindow(url + '?' + getSelectedItemsValue(form_name), width, height);
    }
  }
  else {
    openDialogWindow(url + '?' + getSelectedItemsValue(form_name), width, height);
  }
}

/**
 * TODO: comment
 */
function openErrorWindow(id, width, height) {
  var win = new Window('dialogWindow', {className:"alphacube", width:width, height:height, resizable:false, closable:true, minimizable:false, maximizable:false});
  win.setContent(id, true, true);
  win.options.hideEffectOptions.afterFinish = function() { $(id).hide() };          /* hack IE6 */
  win.setDestroyOnClose();
  win.setSize(width,height);                                                        /* hack IE6 */
  win.showCenter(true);
}

function openDialogWindow(url, width, height) {
  var win = new Window('dialogWindow', {className:"alphacube", width:width, height:height});
  win.setAjaxContent(url, {}, true, true);
  win.setDestroyOnClose();
}

/**
 * Close the dialog window
 */
function closeDialogWindow() {
  Windows.close('dialogWindow');
}

/**
 * Update the dialog window height
 */
function updateDialogWindowHeight() {
  Windows.getWindow('dialogWindow').updateHeight();
}

/**
 * Recenter the dialog window
 */
function recenterDialogWindow() {
  Windows.getWindow('dialogWindow')._recenter();
}

function toggleSpliter() {
	current_value = $('spliter').rel;
	$('main').className = current_value;
	
	if($('spliter').rel == 'big') {
		$('menu').className = 'hide';
		$('spliter').rel = 'small';
	}
	else {
		$('menu').className = 'show';
		$('spliter').rel = 'big';
	}
	
    new Ajax.Request(spliterUrl()+"?value="+current_value, {display_spinner:false, asynchronous:true, evalScripts:true});
}

function dialog_login() { 
    $("#connection").dialog({ 
        title: 'Connexion',
        bgiframe: true, 
        autoOpen: false, 
        modal: true, 
        show: {effect:'blind',duration:500}, 
  		hide: {effect:'blind',duration:200},
        open: function() { 
            jQuery('.ui-widget-overlay').bind('click', function() { 
                jQuery('#connection').dialog('close'); 
            }) 
        } 
    }); 
}


  
function change_font_fam(elem,font_fam)
{ 
	$(elem).css({'font-family': font_fam})
}

function change_size_font_fam(elem,font_size)
{ 
	$(elem).css({'font-size': font_size})
}

function start_app()
{
	start_slide();
	dialog_login();	
}


function questionAndFuntion(function_name, confirmation,msg_confirm) {
	ok_run = true;
	if (confirmation) 
	{
		if (!confirm(msg_confirm)) 
			ok_run=false;
	}
	if (ok_run)
		window[function_name]();
}

/**
* Check that at least one item has been selected, pops up a confirmation if needed
* and submit the specified form to the specified url
*/
function questionAndSubmitForm(form_name, url, confirmation,msg_confirm,remote) {

	if (confirmation) {
		if (confirm(msg_confirm)) {
			submitForm(form_name, url,remote);
		}
	}
	else {
		submitForm(form_name, url,remote);
	}
}


/*
$( document ).ready(function() {
    $('[data-behaviour~=datepicker]').datepicker({
	    todayBtn: "linked",
	    language: "fr",
	    autoclose: true,
	    todayHighlight: true
    });
});
*/


function init_datepicker() {
	$( document ).ready(function() {
		$('[data-behaviour~=datetimepicker]').datetimepicker({
		  language: 'fr',
		  format: 'dd/MM/yyyy hh:mm:ss'
		});
		$('[data-behaviour~=timepicker]').datetimepicker({
		  language: 'fr',
		  pickDate: false,
		  format: 'hh:mm:ss'
		});
		$('[data-behaviour~=datepicker]').datetimepicker({
		  language: 'fr',
		  pickTime: false,
		  format: 'dd/MM/yyyy'
		});
	});
}

function init_inputmask() {
	$( document ).ready(function() {
		$(".inputmask").inputmask();
	});
}



function init_tree_view_file() {
	$(document).ready( function() {
		$("#tree_view_file").hide();
		$("#tree_view_file").treeview();
		$("#tree_view_file").show();
	} );
}


function init_toggle_by_ref() {
	$( document ).ready(function() {    
		

        $(".toggle_by_ref").each(function(index, value) {      
        	ref = $(this).data('reference-class');
			new_html = "<small><a><span class='glyphicon glyphicon-plus " + ref + "'></span><span class='glyphicon glyphicon-minus " + ref + " init_hide'></span></a></small>"
			$(this).append( new_html );
	        $(this).on('click', function() {      
	        	ref = $(this).data('reference-class');
	            $('.' + ref).toggle('fast'); 
	         }); 
        }); 
		
        $(".init_hide").hide(); 
	});
};


// démarrage de l'application
$( document ).ready(function() {
	$('[title]').tooltip({
	    placement: "right"
    });
});
//


