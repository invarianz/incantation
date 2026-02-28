/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.HomeView : Gtk.Box {
    public Settings settings { get; construct; }

    public HomeView (Settings settings) {
        Object (
            settings: settings,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 24
        );
    }

    construct {
        margin_start = 32;
        margin_end = 32;
        margin_top = 24;
        margin_bottom = 24;

        var welcome_label = new Granite.HeaderLabel (_("Welcome, Initiate")) {
            secondary_text = _("Your journey into the arcane arts begins here.")
        };

        var continue_button = new Gtk.Button.with_label (_("Continue")) {
            halign = Gtk.Align.START
        };
        continue_button.add_css_class (Granite.CssClass.SUGGESTED);
        continue_button.add_css_class ("continue-button");

        var stats_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16) {
            homogeneous = true
        };

        var flame_card = create_stat_card (
            "\xf0\x9f\x94\xa5",
            settings.get_int ("flame-count").to_string (),
            _("Day Flame")
        );

        var spells_card = create_stat_card (
            "\xe2\x9c\xa8",
            "0",
            _("Fading Spells")
        );

        var oath_value = format_oath (settings.get_string ("daily-oath"));
        var oath_card = create_stat_card (
            "\xf0\x9f\x93\x9c",
            oath_value,
            _("Daily Oath")
        );

        stats_box.append (flame_card);
        stats_box.append (spells_card);
        stats_box.append (oath_card);

        append (welcome_label);
        append (continue_button);
        append (stats_box);

        settings.changed["flame-count"].connect (() => {
            update_stat_value (flame_card, settings.get_int ("flame-count").to_string ());
        });

        settings.changed["daily-oath"].connect (() => {
            update_stat_value (oath_card, format_oath (settings.get_string ("daily-oath")));
        });
    }

    private Gtk.Box create_stat_card (string icon, string value, string label) {
        var card = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            halign = Gtk.Align.FILL,
            margin_start = 16,
            margin_end = 16,
            margin_top = 16,
            margin_bottom = 16
        };
        card.add_css_class (Granite.CssClass.CARD);

        var icon_label = new Gtk.Label (icon);

        var value_label = new Gtk.Label (value) {
            name = "stat-value"
        };
        value_label.add_css_class ("stat-value");

        var text_label = new Gtk.Label (label);
        text_label.add_css_class (Granite.CssClass.DIM);
        text_label.add_css_class (Granite.CssClass.SMALL);

        card.append (icon_label);
        card.append (value_label);
        card.append (text_label);

        return card;
    }

    private void update_stat_value (Gtk.Box card, string new_value) {
        var child = card.get_first_child ();
        while (child != null) {
            if (child.name == "stat-value") {
                ((Gtk.Label) child).label = new_value;
                return;
            }
            child = child.get_next_sibling ();
        }
    }

    private string format_oath (string oath) {
        switch (oath) {
            case "ember": return _("Ember");
            case "flame": return _("Flame");
            case "blaze": return _("Blaze");
            case "inferno": return _("Inferno");
            default: return oath;
        }
    }
}
