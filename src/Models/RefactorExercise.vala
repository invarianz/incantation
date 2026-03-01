/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.RefactorExercise : Incantation.Exercise {
    public string original_code;
    public string quality_criteria;
    public string[] accepted_refactors;
    public GenericArray<Incantation.TestCase>? test_cases;
}
