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
}

public enum Incantation.Circle {
    FIRST,       // Recognition — heavy scaffolding
    SECOND,      // Recall — progressive fading
    THIRD,       // Casting — minimal scaffolding
    FOURTH,      // Command — no scaffolding
    FIFTH;       // Transcendence — permanent mastery
}
