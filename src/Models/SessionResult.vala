/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.SessionResult : Object {
    public string concept_id;
    public string language_id;
    public Circle circle;
    public int correct_count;
    public int total_count;
    public int total_ap;
    public int best_chain;

    public bool is_passed () {
        return correct_count == total_count && total_count > 0;
    }
}
