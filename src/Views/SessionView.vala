/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.SessionView : Gtk.Box {
    public signal void session_finished (SessionResult? result);

    public Settings settings { get; construct; }
    public Incantation.ContentLoader? content_loader { get; construct; }
    public string return_view { get; set; default = "home"; }

    private GenericArray<Incantation.Exercise> exercises;
    private int current_index;
    private int correct_count;
    private int chain_count;
    private int best_chain;
    private int total_ap;

    private string? session_concept_id;
    private string? session_language_id;
    private Circle session_circle;

    private Gtk.ProgressBar progress_bar;
    private Incantation.SpellChainDisplay chain_display;
    private Gtk.Box content_area;

    public SessionView (Settings settings, Incantation.ContentLoader? content_loader = null) {
        Object (
            settings: settings,
            content_loader: content_loader,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );
    }

    construct {
        progress_bar = new Gtk.ProgressBar () {
            show_text = false
        };

        chain_display = new Incantation.SpellChainDisplay () {
            margin_top = 8,
            margin_bottom = 8
        };

        content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true
        };

        var scrolled = new Gtk.ScrolledWindow () {
            child = content_area,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        append (progress_bar);
        append (chain_display);
        append (scrolled);
    }

    public void start () {
        return_view = "home";
        session_concept_id = null;
        session_language_id = null;

        if (content_loader != null) {
            try {
                var language_id = settings.get_string ("current-language");
                exercises = content_loader.load_all_exercises (language_id);
            } catch (Incantation.ContentError e) {
                warning ("Failed to load exercises: %s", e.message);
                exercises = new GenericArray<Incantation.Exercise> ();
            }
        } else {
            exercises = new GenericArray<Incantation.Exercise> ();
        }

        begin_session ();
    }

    public void start_concept_session (GenericArray<Incantation.Exercise> injected,
                                        string concept_id, string language_id,
                                        Circle circle, string ret_view) {
        exercises = injected;
        return_view = ret_view;
        session_concept_id = concept_id;
        session_language_id = language_id;
        session_circle = circle;
        begin_session ();
    }

    private void begin_session () {
        current_index = 0;
        correct_count = 0;
        chain_count = 0;
        best_chain = 0;
        total_ap = 0;

        if (exercises.length > 0) {
            show_exercise ();
        }
    }

    private void show_exercise () {
        clear_box (content_area);

        progress_bar.fraction = (double) current_index / exercises.length;
        chain_display.visible = true;

        var exercise = exercises[current_index];

        if (exercise is Incantation.MultipleChoiceExercise) {
            var mc = (Incantation.MultipleChoiceExercise) exercise;
            var widget = new Incantation.ExerciseWidget (mc);
            widget.answered.connect (on_answered);
            content_area.append (widget);
        } else {
            // Unsupported exercise type — auto-skip
            debug ("Skipping unsupported exercise type for '%s'", exercise.id);
            GLib.Timeout.add (100, () => {
                advance ();
                return Source.REMOVE;
            });
        }
    }

    private void on_answered (bool is_correct, int ap_earned) {
        if (is_correct) {
            correct_count++;
            chain_count++;
            if (chain_count > best_chain) {
                best_chain = chain_count;
            }

            // Chain bonus: +2 AP per chain link above 2
            int chain_bonus = chain_count > 2 ? (chain_count - 2) * 2 : 0;
            total_ap += ap_earned + chain_bonus;
        } else {
            chain_count = 0;
            total_ap += ap_earned;
        }

        chain_display.update_chain (chain_count);

        // Auto-advance after 1.5 seconds
        GLib.Timeout.add (1500, () => {
            advance ();
            return Source.REMOVE;
        });
    }

    private void advance () {
        current_index++;

        if (current_index >= exercises.length) {
            show_results ();
        } else {
            show_exercise ();
        }
    }

    private void show_results () {
        clear_box (content_area);

        progress_bar.fraction = 1.0;
        chain_display.visible = false;

        SessionResult? result = null;
        if (session_concept_id != null && session_language_id != null) {
            result = new SessionResult ();
            result.concept_id = session_concept_id;
            result.language_id = session_language_id;
            result.circle = session_circle;
            result.correct_count = correct_count;
            result.total_count = exercises.length;
            result.total_ap = total_ap;
            result.best_chain = best_chain;
        }

        var results_widget = new Incantation.SessionResultsWidget (
            correct_count, exercises.length, total_ap, best_chain
        );
        results_widget.return_home.connect (() => {
            session_finished (result);
        });

        content_area.append (results_widget);
    }

    private static void clear_box (Gtk.Box box) {
        var child = box.get_first_child ();
        while (child != null) {
            var next = child.get_next_sibling ();
            box.remove (child);
            child = next;
        }
    }
}
