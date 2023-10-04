formTools = {
    dragstart: function (ev) {
        ev.dataTransfer.setData("text/plain", ev.target.id);
        // Tell the browser both copy and move are possible
        ev.effectAllowed = "copy";

        jQuery(ev.target).addClass('current');
        jQuery(ev.target).find('.formtools-element-placeholder').addClass('hidden');
        jQuery(ev.target).next().find('.formtools-element-placeholder').addClass('hidden');
    },

    dragenter: function (ev) {
        ev.preventDefault();
        jQuery(ev.target).closest('.formtools-content').find('.formtools-element-placeholder').removeClass('active');
        jQuery(ev.target).closest('.formtools-element').children('.formtools-element-placeholder').addClass('active');
    },

    dragleave: function (ev) {
        ev.preventDefault();
    },

    dragover: function (ev) {
        ev.preventDefault();
        if ( ev.target.classList.contains('formtools-content') ) {
            const last_element = jQuery(ev.target).find('.formtools-element').get(-1);
            if ( last_element ) {
                const last_position = last_element.getBoundingClientRect();
                if ( ev.y > last_position.y + last_position.height ) {
                    jQuery(ev.target).find('.formtools-element .formtools-element-placeholder').removeClass('active');
                    jQuery(ev.target).children('.formtools-element-placeholder').addClass('active');
                }
            }
        }
    },

    drop: function (ev) {
        ev.preventDefault();

        const source = document.getElementById(ev.dataTransfer.getData("text"));

        const sibling = ev.target.closest('.formtools-element');
        const area = ev.target.closest('.formtools-content');
        if ( source.closest('.formtools-content') ) {
            if ( sibling ) {
                area.insertBefore(source, sibling);
            }
            else {
                area.insertBefore(source, area.children[area.children.length-1]);
            }
        }
        else {
            const source_copy = source.cloneNode(true);

            const old_id = source_copy.id;
            source_copy.id = 'formtools-element-' + area.dataset.pageId + '-' + Date.now();
            jQuery(source_copy).find('#' + old_id + '-modal').attr('id', source_copy.id + '-modal' );
            jQuery(source_copy).find('a.edit').attr('data-target', '#' + source_copy.id + '-modal' );
            jQuery(source_copy).find('form.formtools-element-form').on('submit', formTools.elementSubmit);
            jQuery(source_copy).find('.formtools-element-modal').modal('show');
            jQuery(source_copy).attr('ondragenter', 'formTools.dragenter(event);');
            if ( sibling ) {
                area.insertBefore(source_copy, sibling);
            }
            else {
                area.insertBefore(source_copy, area.children[area.children.length-1]);
            }
        }
    },

    dragend: function (ev) {
        jQuery('.formtools-content:visible').find('.formtools-element-placeholder').removeClass('active hidden');
        jQuery('.formtools-content:visible').find('.formtools-element').removeClass('current');
        jQuery('.formtools-component-menu').find('.formtools-element').removeClass('current');
    },

    elementSubmit: function(e) {
        e.preventDefault();
        const form = jQuery(this);
        const element = form.closest('.formtools-element');
        const value = element.data('value');

        if ( value.type === 'raw_html' ) {
            value.html = form.find(':input[name=html]').val();
            element.find('span.content').text(value.html.length > 40 ? value.html.substr(0, 40) + '...' : value.html);
        }
        else if ( value.type === 'component' && value.comp_name === 'Field' ) {
            const label = form.find(':input[name=label]').val();
            if ( label.length ) {
                value.arguments.label = label;
            }
            else {
                delete value.arguments.label;
            }

            const default_value = form.find(':input[name=default]').val();

            if ( default_value.length ) {
                value.arguments.default = default_value;
            }
            else {
                delete value.arguments.default;
            }
        }
        else if ( value.type === 'hidden' ) {
            value['input-name'] = form.find(':input[name=name]').val();
            value['input-value'] = form.find(':input[name=value]').val();
            element.find('span.content').text(value['input-name'] + ': ' + value['input-value']);
        }
        element.data('value', value);
        form.closest('.formtools-element-modal').modal('hide');
    },

    submit: function(e) {
        const form = jQuery(this);
        const content = {};
        jQuery('div.formtools-content').each(function() {
            let page = jQuery(this).data('page');
            content[page] ||= {};

            for ( let attr of ['name', 'sort_order', 'validation'] ) {
                if ( attr === 'validation' ) {
                    content[page][attr] = jQuery(this).closest('div.tab-pane').find(':input[name="' + attr + '"]').is(':checked') ? 1 : 0;
                }
                else {
                    content[page][attr] = jQuery(this).closest('div.tab-pane').find(':input[name="' + attr + '"]').val();
                }
            }

            content[page]['content'] ||= [];
            jQuery(this).children('.formtools-element').each(function() {
                content[page]['content'].push(jQuery(this).data('value'));
            });
        });
        form.find('input[name=ActiveTab]').val(jQuery('.formtools-content:visible').data('page-id'));
        form.find('input[name=Content]').val(JSON.stringify(content));
    },

    deletePage: function() {
        const tab = jQuery(this).closest('.tab-pane');

        tab.fadeOut(function() {
            jQuery('#formtools-pages').find('a.nav-link[href="#' + tab.attr('id') + '"]').closest('li').remove();
            jQuery('#formtools-pages').find('li:first a.nav-link').tab('show');
        }).remove();
        return false;
    }
};
