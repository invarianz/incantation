/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.SpellChainDisplay : Gtk.Box {
    private Gtk.Label chain_label;
    private Gtk.Label tier_label;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 8;
        halign = Gtk.Align.CENTER;
        add_css_class ("chain-display");
        visible = false;

        chain_label = new Gtk.Label ("") {
            halign = Gtk.Align.CENTER
        };
        chain_label.add_css_class ("chain-count");

        tier_label = new Gtk.Label ("") {
            halign = Gtk.Align.CENTER
        };

        append (chain_label);
        append (tier_label);
    }

    public void update_chain (int chain_count) {
        if (chain_count < 3) {
            visible = false;
            return;
        }

        visible = true;

        remove_css_class ("chain-bronze");
        remove_css_class ("chain-silver");
        remove_css_class ("chain-gold");

        if (chain_count >= 8) {
            add_css_class ("chain-gold");
            tier_label.label = _("Archmage Chain!");
        } else if (chain_count >= 5) {
            add_css_class ("chain-silver");
            tier_label.label = _("Spell Chain!");
        } else {
            add_css_class ("chain-bronze");
            tier_label.label = _("Combo!");
        }

        chain_label.label = "%d".printf (chain_count);
    }
}
