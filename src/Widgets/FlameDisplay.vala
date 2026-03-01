/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.FlameDisplay : Gtk.Box {
    public Settings settings { get; construct; }

    private Gtk.Label count_label;

    public FlameDisplay (Settings settings) {
        Object (
            settings: settings,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 2
        );
    }

    construct {
        halign = Gtk.Align.CENTER;
        margin_top = 12;
        margin_bottom = 12;

        var flame_icon = new Gtk.Image.from_resource (
            "/io/github/invarianz/incantation/images/magic-circle.svg"
        ) {
            pixel_size = 48
        };
        flame_icon.add_css_class ("magic-circle");

        count_label = new Gtk.Label (settings.get_int ("flame-count").to_string ());
        count_label.add_css_class ("flame-count");

        var day_label = new Gtk.Label (_("Daily Incantations"));
        day_label.add_css_class (Granite.CssClass.DIM);
        day_label.add_css_class (Granite.CssClass.SMALL);

        append (flame_icon);
        append (count_label);
        append (day_label);

        settings.changed["flame-count"].connect (() => {
            count_label.label = settings.get_int ("flame-count").to_string ();
        });
    }
}
