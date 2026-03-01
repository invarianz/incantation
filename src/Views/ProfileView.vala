/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.ProfileView : Gtk.Box {
    public Settings settings { get; construct; }

    public ProfileView (Settings settings) {
        Object (
            settings: settings,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 24
        );
    }

    construct {
        margin_start = 24;
        margin_end = 24;
        margin_top = 24;
        margin_bottom = 24;

        var profile_header = new Granite.HeaderLabel (_("Profile")) {
            secondary_text = _("Your progress and achievements.")
        };

        var oath_header = new Granite.HeaderLabel (_("Study Oath")) {
            secondary_text = _("How much time you pledge to practice each day.")
        };

        var oath_list = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE
        };
        oath_list.add_css_class (Granite.CssClass.CARD);

        Gtk.CheckButton? group = null;
        var current = settings.get_string ("daily-oath");

        group = add_oath_row (
            oath_list, group, "cantrip",
            "\xe2\x9c\xa8 " + _("Cantrip"),
            _("5 minutes \xe2\x80\x94 A brief daily practice"),
            current
        );
        add_oath_row (
            oath_list, group, "invocation",
            "\xf0\x9f\x94\xae " + _("Invocation"),
            _("10 minutes \xe2\x80\x94 A focused study session"),
            current
        );
        add_oath_row (
            oath_list, group, "conjuration",
            "\xf0\x9f\x8c\x80 " + _("Conjuration"),
            _("15 minutes \xe2\x80\x94 Deep immersion in the craft"),
            current
        );
        add_oath_row (
            oath_list, group, "grand-ritual",
            "\xf0\x9f\x8c\x9f " + _("Grand Ritual"),
            _("20 minutes \xe2\x80\x94 Total dedication to mastery"),
            current
        );

        append (profile_header);
        append (oath_header);
        append (oath_list);
    }

    private Gtk.CheckButton add_oath_row (
        Gtk.ListBox list,
        Gtk.CheckButton? group,
        string key,
        string title,
        string description,
        string current
    ) {
        var radio = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER
        };
        if (group != null) {
            radio.group = group;
        }
        if (key == current) {
            radio.active = true;
        }

        var title_label = new Gtk.Label (title) {
            xalign = 0
        };

        var desc_label = new Gtk.Label (description) {
            xalign = 0
        };
        desc_label.add_css_class (Granite.CssClass.DIM);
        desc_label.add_css_class (Granite.CssClass.SMALL);

        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        text_box.append (title_label);
        text_box.append (desc_label);

        var row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        row_box.append (radio);
        row_box.append (text_box);

        var row = new Gtk.ListBoxRow () {
            child = row_box
        };
        list.append (row);

        radio.toggled.connect (() => {
            if (radio.active) {
                settings.set_string ("daily-oath", key);
            }
        });

        // Clicking anywhere on the row activates the radio
        var gesture = new Gtk.GestureClick ();
        row.add_controller (gesture);
        gesture.released.connect (() => {
            radio.active = true;
        });

        return radio;
    }
}
