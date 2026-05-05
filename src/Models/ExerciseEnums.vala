/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/**
 * 14 enum values for 12 concrete exercise classes. DISPEL_CURSE and
 * DISCERN_SIGILS are pedagogical variants of FIND_MISCAST and
 * IDENTIFY_SIGIL respectively — they reuse SpotBugExercise and
 * MultipleChoiceExercise with optional fields (error_message,
 * contrast_concepts) rather than requiring separate classes.
 */
public enum Incantation.ExerciseType {
    IDENTIFY_SIGIL,          // Multiple Choice
    BIND_PAIRS,              // Matching
    FOLLOW_THREAD,           // Trace the Code
    READ_RUNES,              // Explain the Code
    ASSEMBLE_INCANTATION,    // Parsons Problem
    FORGE_LINE,              // Micro Parsons
    COMPLETE_INCANTATION,    // Fill-in-the-Blank
    INSCRIBE_SPELL,          // Type the Code
    FIND_MISCAST,            // Spot the Bug
    SCRY_OUTPUT,             // Predict Output
    REFINE_INCANTATION,      // Refactor
    CAST_FROM_MEMORY,        // Free Write
    DISPEL_CURSE,            // Debug Challenge (variant of FIND_MISCAST)
    DISCERN_SIGILS;          // Contrast Exercise (variant of IDENTIFY_SIGIL)

    public static ExerciseType? from_string (string name) {
        switch (name) {
            case "IDENTIFY_SIGIL": return IDENTIFY_SIGIL;
            case "BIND_PAIRS": return BIND_PAIRS;
            case "FOLLOW_THREAD": return FOLLOW_THREAD;
            case "READ_RUNES": return READ_RUNES;
            case "ASSEMBLE_INCANTATION": return ASSEMBLE_INCANTATION;
            case "FORGE_LINE": return FORGE_LINE;
            case "COMPLETE_INCANTATION": return COMPLETE_INCANTATION;
            case "INSCRIBE_SPELL": return INSCRIBE_SPELL;
            case "FIND_MISCAST": return FIND_MISCAST;
            case "SCRY_OUTPUT": return SCRY_OUTPUT;
            case "REFINE_INCANTATION": return REFINE_INCANTATION;
            case "CAST_FROM_MEMORY": return CAST_FROM_MEMORY;
            case "DISPEL_CURSE": return DISPEL_CURSE;
            case "DISCERN_SIGILS": return DISCERN_SIGILS;
            default: return null;
        }
    }
}

public enum Incantation.Circle {
    FIRST,       // Recognition — heavy scaffolding
    SECOND,      // Recall — progressive fading
    THIRD,       // Casting — minimal scaffolding
    FOURTH,      // Command — no scaffolding
    FIFTH;       // Transcendence — permanent mastery

    public static Circle? from_string (string name) {
        switch (name) {
            case "FIRST": return FIRST;
            case "SECOND": return SECOND;
            case "THIRD": return THIRD;
            case "FOURTH": return FOURTH;
            case "FIFTH": return FIFTH;
            default: return null;
        }
    }

    public Circle? next () {
        switch (this) {
            case FIRST: return SECOND;
            case SECOND: return THIRD;
            case THIRD: return FOURTH;
            case FOURTH: return FIFTH;
            default: return null;
        }
    }

    public string to_roman () {
        switch (this) {
            case FIRST: return "I";
            case SECOND: return "II";
            case THIRD: return "III";
            case FOURTH: return "IV";
            case FIFTH: return "V";
            default: return "?";
        }
    }

    public string to_string_value () {
        switch (this) {
            case FIRST: return "FIRST";
            case SECOND: return "SECOND";
            case THIRD: return "THIRD";
            case FOURTH: return "FOURTH";
            case FIFTH: return "FIFTH";
            default: return "FIRST";
        }
    }
}
