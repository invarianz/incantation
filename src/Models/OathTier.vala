/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.OathTier {
    public static string emoji (string key) {
        switch (key) {
            case "cantrip": return "\xe2\x9c\xa8";
            case "invocation": return "\xf0\x9f\x94\xae";
            case "conjuration": return "\xf0\x9f\x8c\x80";
            case "grand-ritual": return "\xf0\x9f\x8c\x9f";
            default: return "\xf0\x9f\x94\xae";
        }
    }

    public static string label (string key) {
        switch (key) {
            case "cantrip": return _("Cantrip");
            case "invocation": return _("Invocation");
            case "conjuration": return _("Conjuration");
            case "grand-ritual": return _("Grand Ritual");
            default: return key;
        }
    }
}
