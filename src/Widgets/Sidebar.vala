/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.Sidebar : Gtk.Box {
    public signal void navigation_changed (string view_name);

    public Settings settings { get; construct; }

    private Gtk.ListBox list_box;

    public Sidebar (Settings settings) {
        Object (
            settings: settings,
            orientation: Gtk.Orientation.VERTICAL,
            width_request: 200
        );
    }

    construct {
        add_css_class ("sidebar");

        list_box = new Gtk.ListBox ();
        list_box.vexpand = true;

        add_nav_row ("go-home-symbolic", _("Home"), "home");
        add_nav_row ("view-grid-symbolic", _("The Tower"), "tower");
        add_nav_row ("accessories-dictionary", _("Grimoire"), "grimoire");
        add_nav_row ("avatar-default-symbolic", _("Profile"), "profile");

        list_box.row_selected.connect ((row) => {
            if (row != null) {
                navigation_changed (row.name);
            }
        });

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var flame_display = new Incantation.FlameDisplay (settings);

        append (list_box);
        append (separator);
        append (flame_display);
    }

    private void add_nav_row (string icon_name, string label_text, string name) {
        var icon = new Gtk.Image.from_icon_name (icon_name);
        var label = new Gtk.Label (label_text) {
            xalign = 0,
            hexpand = true
        };

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 8,
            margin_bottom = 8
        };
        box.append (icon);
        box.append (label);

        var row = new Gtk.ListBoxRow () {
            child = box,
            name = name
        };

        list_box.append (row);
    }

    public void select_view (string view_name) {
        var row = list_box.get_row_at_index (0);
        for (int i = 0; row != null; i++) {
            if (row.name == view_name) {
                list_box.select_row (row);
                return;
            }
            row = list_box.get_row_at_index (i + 1);
        }
    }

}
