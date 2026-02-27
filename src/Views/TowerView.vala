/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.TowerView : Granite.Placeholder {
    public TowerView () {
        Object (
            title: _("The Tower"),
            description: _("Your lessons and challenges await."),
            icon: new ThemedIcon ("view-grid-symbolic")
        );
    }
}
