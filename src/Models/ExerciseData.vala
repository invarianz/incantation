/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.Option : Object {
    public string id;
    public string text;
    public bool is_correct;
    public string? misconception_id;
    public string? feedback;
}

public class Incantation.MatchItem : Object {
    public string id;
    public string content;
}

public class Incantation.MatchPair : Object {
    public string left_id;
    public string right_id;
}

public class Incantation.CodeBlock : Object {
    public string id;
    public string code;
    public int correct_position;
    public int indent_level;
}

public class Incantation.Fragment : Object {
    public string id;
    public string text;
    public int correct_position;
}

public class Incantation.BlankChoice : Object {
    public string id;
    public string text;
}

public class Incantation.Blank : Object {
    public string id;
    public string[] correct_values;
    public GenericArray<Incantation.BlankChoice>? choices;
}

public class Incantation.ExecutionStep : Object {
    public int line;
    public HashTable<string, string> variables;
}

public class Incantation.Checkpoint : Object {
    public int after_step;
    public string variable;
    public string expected;
    public string? prompt;
}

public class Incantation.TestCase : Object {
    public string input;
    public string expected_output;
}

public class Incantation.WrongAnswer : Object {
    public string value;
    public string explanation;
}
