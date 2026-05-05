/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.SessionResultsWidget : Gtk.Box {
    public signal void return_home ();

    public int correct { get; construct; }
    public int total { get; construct; }
    public int total_ap { get; construct; }
    public int best_chain { get; construct; }

    public SessionResultsWidget (int correct, int total, int total_ap, int best_chain) {
        Object (
            correct: correct,
            total: total,
            total_ap: total_ap,
            best_chain: best_chain,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 16,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        add_css_class ("session-results");
        margin_start = 48;
        margin_end = 48;
        margin_top = 48;
        margin_bottom = 48;

        var title = new Granite.HeaderLabel (_("Session Complete!"));
        title.halign = Gtk.Align.CENTER;

        var score_label = new Gtk.Label ("%d / %d".printf (correct, total));
        score_label.add_css_class ("results-score");

        var score_desc = new Gtk.Label (_("Questions Correct"));
        score_desc.add_css_class (Granite.CssClass.DIM);

        var ap_label = new Gtk.Label (_("%d AP Earned").printf (total_ap));
        ap_label.add_css_class ("results-ap");

        var home_button = new Gtk.Button.with_label (_("Return to Home")) {
            halign = Gtk.Align.CENTER
        };
        home_button.add_css_class (Granite.CssClass.SUGGESTED);
        home_button.add_css_class ("continue-button");

        append (title);
        append (score_label);
        append (score_desc);
        append (ap_label);

        if (best_chain >= 3) {
            var chain_label = new Gtk.Label (_("Best Chain: %d").printf (best_chain));
            chain_label.add_css_class ("results-chain");
            append (chain_label);
        }

        append (home_button);

        home_button.clicked.connect (() => {
            return_home ();
        });
    }
}
