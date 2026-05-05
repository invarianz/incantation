/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.ConceptCard : Gtk.FlowBoxChild {
    public string concept_id { get; construct; }
    public string concept_name { get; construct; }
    public string syntax_label { get; construct; }
    public int exercise_count { get; construct; }
    public ConceptState concept_state { get; construct; default = ConceptState.AVAILABLE; }
    public string? current_circle_label { get; construct; default = null; }
    public string? missing_prereqs { get; construct; default = null; }

    public ConceptCard (string concept_id, string concept_name,
                        string syntax_label, int exercise_count,
                        ConceptState concept_state = ConceptState.AVAILABLE,
                        string? current_circle_label = null,
                        string? missing_prereqs = null) {
        Object (
            concept_id: concept_id,
            concept_name: concept_name,
            syntax_label: syntax_label,
            exercise_count: exercise_count,
            concept_state: concept_state,
            current_circle_label: current_circle_label,
            missing_prereqs: missing_prereqs
        );
    }

    construct {
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        var name_label = new Gtk.Label (concept_name) {
            xalign = 0,
            hexpand = true
        };
        name_label.add_css_class ("h4");
        header_box.append (name_label);

        if (concept_state == ConceptState.LOCKED) {
            var lock_icon = new Gtk.Image.from_icon_name ("changes-prevent-symbolic");
            lock_icon.add_css_class (Granite.CssClass.DIM);
            header_box.append (lock_icon);
        } else if (concept_state == ConceptState.MASTERED) {
            var check_icon = new Gtk.Image.from_icon_name ("object-select-symbolic");
            check_icon.add_css_class ("success");
            header_box.append (check_icon);
        }

        var syntax = new Gtk.Label (syntax_label) {
            xalign = 0
        };
        syntax.add_css_class (Granite.CssClass.DIM);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 10,
            margin_bottom = 10
        };
        box.append (header_box);
        box.append (syntax);

        string info_text;
        string? info_css = null;
        string? frame_css = null;

        switch (concept_state) {
            case ConceptState.LOCKED:
                info_text = missing_prereqs != null
                    ? _("Requires: %s").printf (missing_prereqs)
                    : _("Locked");
                info_css = "prereq-label";
                frame_css = "concept-locked";
                break;
            case ConceptState.IN_PROGRESS:
                info_text = build_exercise_label ();
                if (current_circle_label != null) {
                    info_css = "circle-indicator";
                }
                frame_css = "concept-in-progress";
                break;
            case ConceptState.MASTERED:
                info_text = _("Mastered");
                frame_css = "concept-mastered";
                break;
            default:
                info_text = build_exercise_label ();
                if (current_circle_label != null) {
                    info_css = "circle-indicator";
                }
                break;
        }

        var info_label = new Gtk.Label (info_text) {
            xalign = 0
        };
        info_label.add_css_class (Granite.CssClass.DIM);
        if (info_css != null) {
            info_label.add_css_class (info_css);
        }

        box.append (info_label);

        var frame = new Gtk.Frame (null) {
            child = box
        };
        frame.add_css_class ("concept-card");
        frame.add_css_class (Granite.CssClass.CARD);
        if (frame_css != null) {
            frame.add_css_class (frame_css);
        }

        child = frame;
    }

    private string build_exercise_label () {
        if (current_circle_label != null && exercise_count > 0) {
            return ngettext (
                "%s \xc2\xb7 %d exercise",
                "%s \xc2\xb7 %d exercises",
                (ulong) exercise_count
            ).printf (current_circle_label, exercise_count);
        }

        if (exercise_count > 0) {
            return ngettext (
                "%d exercise", "%d exercises", (ulong) exercise_count
            ).printf (exercise_count);
        }

        return _("(coming soon)");
    }
}
