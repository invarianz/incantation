/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.ExerciseWidget : Gtk.Box {
    public signal void answered (bool is_correct, int ap_earned);

    public Incantation.MultipleChoiceExercise exercise { get; construct; }

    private Gtk.Box options_box;
    private Gtk.Label feedback_label;
    private bool has_answered;

    public ExerciseWidget (Incantation.MultipleChoiceExercise exercise) {
        Object (
            exercise: exercise,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 16
        );
    }

    construct {
        has_answered = false;
        margin_start = 24;
        margin_end = 24;
        margin_top = 16;
        margin_bottom = 16;

        var prompt_label = new Gtk.Label (exercise.prompt) {
            wrap = true,
            xalign = 0
        };
        prompt_label.add_css_class ("exercise-prompt");

        append (prompt_label);

        if (exercise.code_snippet != null) {
            var code_label = new Gtk.Label (exercise.code_snippet) {
                wrap = true,
                xalign = 0,
                selectable = true
            };
            code_label.add_css_class ("code-snippet");
            append (code_label);
        }

        options_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        append (options_box);

        for (int i = 0; i < exercise.options.length; i++) {
            var option = exercise.options[i];
            var button = new Gtk.Button.with_label (option.text) {
                halign = Gtk.Align.FILL
            };
            button.add_css_class ("option-button");
            button.add_css_class ("flat");

            button.set_data<int> ("option-index", i);
            button.clicked.connect (() => {
                on_option_clicked (button, option);
            });

            options_box.append (button);
        }

        feedback_label = new Gtk.Label ("") {
            wrap = true,
            xalign = 0,
            visible = false
        };
        feedback_label.add_css_class ("feedback-label");
        append (feedback_label);
    }

    private void on_option_clicked (Gtk.Button clicked_button, Incantation.Option chosen) {
        if (has_answered) {
            return;
        }
        has_answered = true;

        // Disable all buttons and highlight correct/wrong
        var child = options_box.get_first_child ();
        while (child != null) {
            var btn = (Gtk.Button) child;
            btn.sensitive = false;

            var idx = btn.get_data<int> ("option-index");
            var opt = exercise.options[idx];

            if (opt.is_correct) {
                btn.add_css_class ("option-correct");
            } else if (btn == clicked_button) {
                btn.add_css_class ("option-wrong");
            }

            child = child.get_next_sibling ();
        }

        // Show feedback
        if (chosen.feedback != null) {
            feedback_label.label = chosen.feedback;
        } else if (chosen.is_correct) {
            feedback_label.label = _("Well done!");
        } else {
            feedback_label.label = _("Not quite! Keep going.");
        }
        feedback_label.visible = true;

        int ap = chosen.is_correct ? exercise.ap_base : 0;
        answered (chosen.is_correct, ap);
    }
}
