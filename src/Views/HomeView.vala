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
        margin_start = 24;
        margin_end = 24;
        margin_top = 24;
        margin_bottom = 24;

        var welcome_label = new Granite.HeaderLabel (_("Welcome Initiate")) {
            secondary_text = _("Your journey into the arcane arts of programming begins here.")
        };
        welcome_label.add_css_class ("welcome-header");

        var continue_button = new Gtk.Button.with_label (_("Continue")) {
            halign = Gtk.Align.START
        };
        continue_button.add_css_class (Granite.CssClass.SUGGESTED);
        continue_button.add_css_class ("continue-button");

        var stats_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true
        };

        var spells_card = create_stat_card (
            "\xe2\x9c\xa8",
            "0",
            _("Fading Spells")
        );

        var current_oath = settings.get_string ("daily-oath");
        var oath_card = create_stat_card (
            oath_emoji (current_oath),
            format_oath (current_oath),
            _("Study Oath")
        );

        stats_box.append (spells_card);
        stats_box.append (oath_card);

        append (welcome_label);
        append (continue_button);
        append (stats_box);

        settings.changed["daily-oath"].connect (() => {
            var oath = settings.get_string ("daily-oath");
            update_stat_icon (oath_card, oath_emoji (oath));
            update_stat_value (oath_card, format_oath (oath));
        });
    }

    private Gtk.Box create_stat_card (string icon, string value, string label) {
        var card = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            halign = Gtk.Align.FILL
        };
        card.add_css_class (Granite.CssClass.CARD);
        card.add_css_class ("stat-card");

        var icon_label = new Gtk.Label (icon);
        icon_label.add_css_class ("stat-icon");

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

    private string oath_emoji (string oath) {
        switch (oath) {
            case "cantrip": return "\xe2\x9c\xa8";
            case "invocation": return "\xf0\x9f\x94\xae";
            case "conjuration": return "\xf0\x9f\x8c\x80";
            case "grand-ritual": return "\xf0\x9f\x8c\x9f";
            default: return "\xf0\x9f\x94\xae";
        }
    }

    private void update_stat_icon (Gtk.Box card, string emoji) {
        var child = card.get_first_child ();
        if (child != null && child is Gtk.Label) {
            ((Gtk.Label) child).label = emoji;
        }
    }

    private string format_oath (string oath) {
        switch (oath) {
            case "cantrip": return _("Cantrip");
            case "invocation": return _("Invocation");
            case "conjuration": return _("Conjuration");
            case "grand-ritual": return _("Grand Ritual");
            default: return oath;
        }
    }
}
