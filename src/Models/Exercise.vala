/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public abstract class Incantation.Exercise : Object {
    // Identity
    public string id;
    public ExerciseType exercise_type;

    // Content
    public string prompt;
    public string? code_snippet;
    public string explanation;

    // Pedagogical metadata
    public string[] concepts;
    public Circle circle;
    public int difficulty;
    public string[] misconceptions;
    public string[] hints;

    // Scoring
    public int ap_base;
}
