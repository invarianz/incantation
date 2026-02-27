/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.GrimoireView : Granite.Placeholder {
    public GrimoireView () {
        Object (
            title: _("Grimoire"),
            description: _("Your reference library of spells and incantations."),
            icon: new ThemedIcon ("accessories-dictionary")
        );
    }
}
