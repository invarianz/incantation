/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.ProfileView : Granite.Placeholder {
    public ProfileView () {
        Object (
            title: _("Profile"),
            description: _("Your progress and achievements."),
            icon: new ThemedIcon ("avatar-default")
        );
    }
}
