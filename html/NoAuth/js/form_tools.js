function disable_form_field(disable, selector) {
    if ( disable ) {
        jQuery(selector).addClass('hidden').find('input,select').attr('disabled', 'disabled');
    }
    else {
        jQuery(selector).removeClass('hidden');
        jQuery(selector).find('input,select').filter( function() {
            return jQuery(this).closest('.hidden').length == 0
        } ).removeAttr('disabled');
    }
}

function should_disable_form_field( fields, values ) {
    for ( var i = 0; i<fields.length; i++ ) {
        var field = fields[i];
        var active = jQuery('input:enabled[name="'+ field +'"], input:enabled[name="'+ field +'s"]').filter(function() {
            var value = this.value;
            if ( this.type == 'radio' || this.type == 'checkbox' ) {
                if ( !jQuery(this).is(':checked') ) return 0;
            }
            for ( var i = 0; i < values[field].length; i++ ) {
                if ( value == values[field][i] ) { return 1 }
            }
            return 0;
        }).length;
        if ( active ) return 0;
    }
    return 1;
}
