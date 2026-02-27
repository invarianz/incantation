/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.Application : Gtk.Application {
    public Application () {
        Object (
            application_id: "io.github.invarianz.incantation",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/github/invarianz/incantation/app.css");
        Gtk.StyleContext.add_provider_for_display ( // vala-lint=line-length
            Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    protected override void activate () {
        var window = active_window;
        if (window == null) {
            window = new Incantation.MainWindow (this);
        }

        window.present ();
    }

    public static int main (string[] args) {
        return new Incantation.Application ().run (args);
    }
}
