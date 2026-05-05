/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public enum Incantation.ConceptState {
    LOCKED,       // prerequisites not met
    AVAILABLE,    // prerequisites met, no circle completed
    IN_PROGRESS,  // ≥1 circle completed, more remain
    MASTERED;     // highest circle with exercises completed
}
