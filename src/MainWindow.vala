/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.MainWindow : Gtk.ApplicationWindow {
    private Settings settings;
    private Incantation.Sidebar sidebar;
    private Gtk.Stack content_stack;
    private Incantation.ProgressService progress_service;
    private Incantation.ContentLoader content_loader;
    private Incantation.TowerView tower_view;
    private Incantation.SessionView session_view;

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

        // Developer override — not available in the production Flatpak
        var content_dir = Environment.get_variable ("INCANTATION_CONTENT_DIR");
        if (content_dir == null || content_dir == "") {
            content_dir = Incantation.Config.CONTENT_DIR;
        }

        content_loader = new Incantation.ContentLoader (content_dir);

        progress_service = new Incantation.ProgressService ();
        progress_service.load ();

        sidebar = new Incantation.Sidebar (settings);

        content_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        var home_view = new Incantation.HomeView (settings);
        content_stack.add_named (home_view, "home");

        tower_view = new Incantation.TowerView (settings, content_loader, progress_service);
        content_stack.add_named (tower_view, "tower");
        content_stack.add_named (new Incantation.GrimoireView (), "grimoire");
        content_stack.add_named (new Incantation.ProfileView (settings), "profile");

        session_view = new Incantation.SessionView (settings, content_loader);
        content_stack.add_named (session_view, "session");

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            resize_start_child = false,
            shrink_start_child = false,
            start_child = sidebar,
            end_child = content_stack,
            position = 220
        };

        child = paned;

        sidebar.navigation_changed.connect ((view_name) => {
            content_stack.visible_child_name = view_name;
        });

        home_view.navigate_to.connect ((view_name) => {
            sidebar.select_view (view_name);
        });

        home_view.start_session.connect (start_suggested_session);

        tower_view.concept_selected.connect ((concept_id, language_id, circle) => {
            try {
                var exercises = content_loader.load_exercises_for_circle (
                    language_id, concept_id, circle
                );
                if (exercises.length > 0) {
                    content_stack.visible_child_name = "session";
                    session_view.start_concept_session (
                        exercises, concept_id, language_id, circle, "tower"
                    );
                }
            } catch (Incantation.ContentError e) {
                warning ("Failed to load exercises for %s: %s", concept_id, e.message);
            }
        });

        session_view.session_finished.connect ((result) => {
            if (result != null && result.is_passed ()) {
                progress_service.record_result (result);
                progress_service.save ();
            }

            tower_view.refresh ();
            sidebar.select_view (session_view.return_view);
        });

        sidebar.select_view ("home");

        close_request.connect (() => {
            save_window_state ();
            return false;
        });
    }

    private void start_suggested_session () {
        var language_id = settings.get_string ("current-language");

        GenericArray<Incantation.Concept> concepts;
        try {
            concepts = content_loader.load_concepts ();
        } catch (Incantation.ContentError e) {
            warning ("Failed to load concepts: %s", e.message);
            concepts = new GenericArray<Incantation.Concept> ();
        }

        var suggested = progress_service.get_suggested_concept (language_id, concepts);
        if (suggested == null) {
            start_fallback_session ();
            return;
        }

        var circle = progress_service.get_next_circle (language_id, suggested);
        if (circle == null) {
            start_fallback_session ();
            return;
        }

        try {
            var exercises = content_loader.load_exercises_for_circle (
                language_id, suggested, circle
            );
            if (exercises.length > 0) {
                content_stack.visible_child_name = "session";
                session_view.start_concept_session (
                    exercises, suggested, language_id, circle, "home"
                );
                return;
            }
        } catch (Incantation.ContentError e) {
            warning ("Failed to load suggested exercises: %s", e.message);
        }

        start_fallback_session ();
    }

    private void start_fallback_session () {
        content_stack.visible_child_name = "session";
        session_view.start ();
    }

    private void save_window_state () {
        settings.set_boolean ("window-maximized", maximized);

        if (!maximized) {
            settings.set_int ("window-width", default_width);
            settings.set_int ("window-height", default_height);
        }
    }
}
