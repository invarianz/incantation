/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.MainWindow : Gtk.ApplicationWindow {
    private Settings settings;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            title: _("Incantation")
        );
    }

    construct {
        settings = new Settings ("io.github.invarianz.incantation");

        default_width = settings.get_int ("window-width");
        default_height = settings.get_int ("window-height");

        if (settings.get_boolean ("window-maximized")) {
            maximize ();
        }

        var header_bar = new Gtk.HeaderBar () {
            show_title_buttons = true
        };

        titlebar = header_bar;

        var placeholder = new Granite.Placeholder (_("Welcome, Initiate")) {
            description = _("Your journey into the arcane arts begins here."),
            icon = new ThemedIcon ("applications-development")
        };

        child = placeholder;

        close_request.connect (() => {
            save_window_state ();
            return false;
        });
    }

    private void save_window_state () {
        settings.set_boolean ("window-maximized", maximized);

        if (!maximized) {
            settings.set_int ("window-width", default_width);
            settings.set_int ("window-height", default_height);
        }
    }
}
