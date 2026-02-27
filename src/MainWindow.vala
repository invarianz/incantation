/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.MainWindow : Gtk.ApplicationWindow {
    private Settings settings;
    private Incantation.Sidebar sidebar;
    private Gtk.Stack content_stack;
    private Gtk.Paned paned;

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

        sidebar = new Incantation.Sidebar (settings);

        content_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        content_stack.add_named (new Incantation.HomeView (settings), "home");
        content_stack.add_named (new Incantation.TowerView (), "tower");
        content_stack.add_named (new Incantation.GrimoireView (), "grimoire");
        content_stack.add_named (new Incantation.ProfileView (), "profile");

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            resize_start_child = false,
            shrink_start_child = false,
            start_child = sidebar,
            end_child = content_stack,
            position = 220
        };

        var toast = new Granite.Toast ("");

        var overlay = new Gtk.Overlay () {
            child = paned
        };
        overlay.add_overlay (toast);

        child = overlay;

        sidebar.navigation_changed.connect ((view_name) => {
            content_stack.visible_child_name = view_name;
        });

        sidebar.select_view ("home");

        close_request.connect (() => {
            save_window_state ();
            return false;
        });
    }

    public void set_sidebar_visible (bool visible) {
        sidebar.visible = visible;
        if (visible) {
            paned.position = 220;
        }
    }

    private void save_window_state () {
        settings.set_boolean ("window-maximized", maximized);

        if (!maximized) {
            settings.set_int ("window-width", default_width);
            settings.set_int ("window-height", default_height);
        }
    }
}
