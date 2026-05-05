/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.ProgressService : Object {
    private HashTable<string, HashTable<string, Circle?>> languages;
    private string file_path;

    public ProgressService () {
        languages = new HashTable<string, HashTable<string, Circle?>> (
            str_hash, str_equal
        );

        var data_dir = Path.build_filename (
            Environment.get_user_data_dir (),
            "io.github.invarianz.incantation"
        );
        file_path = Path.build_filename (data_dir, "progress.json");
    }

    public void load () {
        if (!FileUtils.test (file_path, FileTest.IS_REGULAR)) {
            return;
        }

        var parser = new Json.Parser ();
        try {
            parser.load_from_file (file_path);
        } catch (Error e) {
            warning ("Corrupt progress file, starting fresh: %s", e.message);
            return;
        }

        var root = parser.get_root ();
        if (root == null || root.get_node_type () != Json.NodeType.OBJECT) {
            return;
        }

        var obj = root.get_object ();
        if (!obj.has_member ("languages")) {
            return;
        }

        var langs_obj = obj.get_object_member ("languages");
        langs_obj.foreach_member ((o, lang_id, lang_node) => {
            languages[lang_id] = parse_language_progress (lang_node.get_object ());
        });
    }

    public void save () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("schema_version");
        builder.add_int_value (1);
        builder.set_member_name ("languages");
        builder.begin_object ();

        languages.foreach ((lang_id, concepts) => {
            builder.set_member_name (lang_id);
            build_language_json (builder, concepts);
        });

        builder.end_object ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.root = builder.get_root ();
        generator.pretty = true;

        var dir = Path.get_dirname (file_path);
        DirUtils.create_with_parents (dir, 0700);

        try {
            generator.to_file (file_path);
        } catch (Error e) {
            warning ("Failed to save progress: %s", e.message);
        }
    }

    public Circle? get_highest_circle (string language_id, string concept_id) {
        var concepts = languages[language_id];
        if (concepts == null) {
            return null;
        }
        return concepts[concept_id];
    }

    public Circle? get_next_circle (string language_id, string concept_id) {
        var highest = get_highest_circle (language_id, concept_id);
        if (highest == null) {
            return Circle.FIRST;
        }
        return highest.next ();
    }

    public ConceptState compute_state (string language_id, string concept_id,
                                        string[] prerequisites) {
        for (int i = 0; i < prerequisites.length; i++) {
            if (get_highest_circle (language_id, prerequisites[i]) == null) {
                return ConceptState.LOCKED;
            }
        }

        if (get_highest_circle (language_id, concept_id) == null) {
            return ConceptState.AVAILABLE;
        }

        if (get_next_circle (language_id, concept_id) == null) {
            return ConceptState.MASTERED;
        }

        return ConceptState.IN_PROGRESS;
    }

    public void record_result (SessionResult result) {
        if (!result.is_passed ()) {
            return;
        }

        var current = get_highest_circle (result.language_id, result.concept_id);
        if (current == null || result.circle >= current) {
            var concepts = get_or_create_concepts (result.language_id);
            concepts[result.concept_id] = result.circle;
        }
    }

    public void auto_advance (string language_id, string concept_id, Circle circle) {
        var current = get_highest_circle (language_id, concept_id);
        if (current == null || circle >= current) {
            var concepts = get_or_create_concepts (language_id);
            concepts[concept_id] = circle;
        }
    }

    public string? get_suggested_concept (string language_id,
                                           GenericArray<Concept> concepts) {
        string? first_in_progress = null;

        for (int i = 0; i < concepts.length; i++) {
            var state = compute_state (
                language_id, concepts[i].id, concepts[i].prerequisites
            );

            if (state == ConceptState.AVAILABLE) {
                return concepts[i].id;
            }

            if (state == ConceptState.IN_PROGRESS && first_in_progress == null) {
                first_in_progress = concepts[i].id;
            }
        }

        return first_in_progress;
    }

    public bool is_floor_complete (string language_id, int floor,
                                    GenericArray<Concept> all_concepts) {
        for (int i = 0; i < all_concepts.length; i++) {
            if (all_concepts[i].floor != floor) {
                continue;
            }
            // Check mastery directly: highest circle must be FIFTH (no next)
            var highest = get_highest_circle (language_id, all_concepts[i].id);
            if (highest == null || highest.next () != null) {
                return false;
            }
        }
        return true;
    }

    public bool is_floor_unlocked (string language_id, int floor,
                                    GenericArray<Concept> all_concepts) {
        if (floor == 0) {
            return true;
        }
        return is_floor_complete (language_id, floor - 1, all_concepts);
    }

    private HashTable<string, Circle?> get_or_create_concepts (string language_id) {
        var concepts = languages[language_id];
        if (concepts == null) {
            concepts = new HashTable<string, Circle?> (str_hash, str_equal);
            languages[language_id] = concepts;
        }
        return concepts;
    }

    private HashTable<string, Circle?> parse_language_progress (Json.Object lang_obj) {
        var concepts = new HashTable<string, Circle?> (str_hash, str_equal);
        lang_obj.foreach_member ((lo, concept_id, concept_node) => {
            var co = concept_node.get_object ();
            var circle_str = co.get_string_member ("highest_circle");
            concepts[concept_id] = Circle.from_string (circle_str);
        });
        return concepts;
    }

    private void build_language_json (Json.Builder builder,
                                       HashTable<string, Circle?> concepts) {
        builder.begin_object ();
        concepts.foreach ((concept_id, circle) => {
            if (circle != null) {
                builder.set_member_name (concept_id);
                builder.begin_object ();
                builder.set_member_name ("highest_circle");
                builder.add_string_value (circle.to_string_value ());
                builder.end_object ();
            }
        });
        builder.end_object ();
    }
}
