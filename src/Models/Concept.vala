/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.Concept : Object {
    public string id;
    public string name;
    public string domain;
    public int floor = -1;  // -1 = not assigned to a floor
    public string[] prerequisites;
    public string[] confusion_pairs;
    public string[] misconceptions;
}
