/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public errordomain Incantation.ContentError {
    NOT_FOUND,
    PARSE_ERROR,
    SCHEMA_VERSION
}

public class Incantation.ContentLoader : Object {
    public string content_dir { get; construct; }

    private GenericArray<Incantation.Concept>? cached_concepts = null;

    public ContentLoader (string content_dir) {
        Object (content_dir: content_dir);
    }

    public string[] get_available_languages () throws ContentError {
        string[] languages = {};
        Dir dir;
        try {
            dir = Dir.open (content_dir);
        } catch (FileError e) {
            throw new ContentError.NOT_FOUND (
                "Cannot open content directory: %s", e.message
            );
        }
        string? name;
        while ((name = dir.read_name ()) != null) {
            var path = Path.build_filename (content_dir, name, "manifest.json");
            if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                languages += name;
            }
        }
        return languages;
    }

    public GenericArray<Incantation.Concept> load_concepts () throws ContentError {
        if (cached_concepts != null) {
            return cached_concepts;
        }

        var path = Path.build_filename (content_dir, "concepts.json");
        var root = parse_file (path);
        var obj = root.get_object ();

        check_schema_version (obj, path);

        var arr = obj.get_array_member ("concepts");
        var result = new GenericArray<Incantation.Concept> ();

        arr.foreach_element ((array, index, node) => {
            var co = node.get_object ();
            var concept = new Incantation.Concept ();
            concept.id = co.get_string_member ("id");
            concept.name = co.get_string_member ("name");
            concept.domain = co.get_string_member ("domain");
            concept.floor = co.has_member ("floor") ? (int) co.get_int_member ("floor") : -1;
            concept.prerequisites = get_string_array (co, "prerequisites");
            concept.confusion_pairs = get_string_array (co, "confusion_pairs");
            concept.misconceptions = get_string_array (co, "misconceptions");
            result.add (concept);
        });

        cached_concepts = result;
        return result;
    }

    public Incantation.Language load_language_manifest (string language_id,
            out GenericArray<Incantation.LanguageMapping> mappings) throws ContentError {
        var path = Path.build_filename (content_dir, language_id, "manifest.json");
        var root = parse_file (path);
        var obj = root.get_object ();

        check_schema_version (obj, path);

        var lang_obj = obj.get_object_member ("language");
        var lang = new Incantation.Language ();
        lang.id = lang_obj.get_string_member ("id");
        lang.name = lang_obj.get_string_member ("name");
        lang.icon_name = lang_obj.get_string_member ("icon_name");
        lang.description = lang_obj.get_string_member ("description");
        lang.is_available = true;

        if (lang_obj.has_member ("tower_identity")) {
            var ti = lang_obj.get_object_member ("tower_identity");
            lang.roof_color_top = ti.get_string_member ("roof_color_top");
            lang.roof_color_bottom = ti.get_string_member ("roof_color_bottom");
            lang.logo_path = ti.get_string_member ("logo_path");
            lang.logo_center_x = ti.get_double_member ("logo_center_x");
            lang.logo_center_y = ti.get_double_member ("logo_center_y");
            lang.logo_scale = ti.get_double_member ("logo_scale");
        }

        var result_mappings = new GenericArray<Incantation.LanguageMapping> ();
        var mapping_arr = obj.get_array_member ("mappings");
        mapping_arr.foreach_element ((array, index, node) => {
            var mo = node.get_object ();
            var m = new Incantation.LanguageMapping ();
            m.concept_id = mo.get_string_member ("concept_id");
            m.language_id = language_id;
            m.syntax_label = mo.get_string_member ("syntax_label");
            m.is_supported = mo.get_boolean_member ("is_supported");
            m.confusion_pairs = get_string_array (mo, "confusion_pairs");
            m.misconceptions = get_string_array (mo, "misconceptions");
            result_mappings.add (m);
        });

        mappings = result_mappings;
        return lang;
    }

    public GenericArray<Incantation.Exercise> load_exercises (string language_id,
            string concept_id) throws ContentError {
        var path = Path.build_filename (
            content_dir, language_id, "exercises", concept_id + ".json"
        );

        if (!FileUtils.test (path, FileTest.IS_REGULAR)) {
            return new GenericArray<Incantation.Exercise> ();
        }

        var root = parse_file (path);
        var obj = root.get_object ();

        check_schema_version (obj, path);

        var arr = obj.get_array_member ("exercises");
        var result = new GenericArray<Incantation.Exercise> ();

        for (uint i = 0; i < arr.get_length (); i++) {
            var eo = arr.get_object_element (i);
            var exercise = parse_exercise (eo, language_id);
            if (exercise != null) {
                result.add (exercise);
            }
        }

        return result;
    }

    public GenericArray<Incantation.Exercise> load_all_exercises (string language_id)
            throws ContentError {
        var concepts = load_concepts ();
        var result = new GenericArray<Incantation.Exercise> ();

        for (int i = 0; i < concepts.length; i++) {
            var exercises = load_exercises (language_id, concepts[i].id);
            for (int j = 0; j < exercises.length; j++) {
                result.add (exercises[j]);
            }
        }

        return result;
    }

    public GenericArray<Incantation.Exercise> load_exercises_for_circle (
            string language_id, string concept_id,
            Circle circle) throws ContentError {
        var all = load_exercises (language_id, concept_id);
        var result = new GenericArray<Incantation.Exercise> ();

        for (int i = 0; i < all.length; i++) {
            if (all[i].circle == circle) {
                result.add (all[i]);
            }
        }

        return result;
    }

    public int count_exercises_at_circle (string language_id, string concept_id,
                                           Circle circle) {
        try {
            var all = load_exercises (language_id, concept_id);
            int count = 0;
            for (int i = 0; i < all.length; i++) {
                if (all[i].circle == circle) {
                    count++;
                }
            }
            return count;
        } catch (ContentError e) {
            return 0;
        }
    }

    private Incantation.Exercise? parse_exercise (Json.Object eo, string language_id) {
        var type_str = eo.get_string_member ("exercise_type");
        var exercise_type = Incantation.ExerciseType.from_string (type_str);

        if (exercise_type == null) {
            debug ("Unknown exercise type '%s', skipping", type_str);
            return null;
        }

        switch (exercise_type) {
            case Incantation.ExerciseType.IDENTIFY_SIGIL:
            case Incantation.ExerciseType.DISCERN_SIGILS:
                return parse_mc_exercise (eo, language_id, exercise_type);
            default:
                debug ("Exercise type '%s' not yet implemented, skipping", type_str);
                return null;
        }
    }

    private Incantation.MultipleChoiceExercise parse_mc_exercise (
            Json.Object eo, string language_id,
            Incantation.ExerciseType exercise_type) {
        var ex = new Incantation.MultipleChoiceExercise ();

        ex.id = eo.get_string_member ("id");
        ex.exercise_type = exercise_type;
        ex.language = language_id;
        ex.prompt = eo.get_string_member ("prompt");
        ex.code_snippet = eo.get_null_member ("code_snippet")
            ? null : eo.get_string_member ("code_snippet");
        ex.explanation = eo.get_string_member ("explanation");
        ex.concepts = get_string_array (eo, "concepts");

        var circle_str = eo.get_string_member ("circle");
        var circle = Incantation.Circle.from_string (circle_str);
        ex.circle = circle != null ? circle : Incantation.Circle.FIRST;

        ex.difficulty = (int) eo.get_int_member ("difficulty");
        ex.misconceptions = get_string_array (eo, "misconceptions");
        ex.hints = get_string_array (eo, "hints");
        ex.ap_base = (int) eo.get_int_member ("ap_base");

        ex.options = new GenericArray<Incantation.Option> ();
        var options_arr = eo.get_array_member ("options");
        options_arr.foreach_element ((array, index, node) => {
            var oo = node.get_object ();
            var opt = new Incantation.Option ();
            opt.id = oo.get_string_member ("id");
            opt.text = oo.get_string_member ("text");
            opt.is_correct = oo.get_boolean_member ("is_correct");
            opt.feedback = oo.get_string_member ("feedback");
            opt.misconception_id = oo.get_null_member ("misconception_id")
                ? null : oo.get_string_member ("misconception_id");
            ex.options.add (opt);
        });

        return ex;
    }

    private Json.Node parse_file (string path) throws ContentError {
        if (!FileUtils.test (path, FileTest.IS_REGULAR)) {
            throw new ContentError.NOT_FOUND ("Content file not found: %s", path);
        }

        var parser = new Json.Parser ();
        try {
            parser.load_from_file (path);
        } catch (Error e) {
            throw new ContentError.PARSE_ERROR (
                "Failed to parse %s: %s", path, e.message
            );
        }

        var root = parser.get_root ();
        if (root == null) {
            throw new ContentError.PARSE_ERROR ("Empty JSON file: %s", path);
        }

        return root;
    }

    private void check_schema_version (Json.Object obj, string path) throws ContentError {
        var version = (int) obj.get_int_member ("schema_version");
        if (version != 1) {
            throw new ContentError.SCHEMA_VERSION (
                "Unsupported schema version %d in %s", version, path
            );
        }
    }

    private string[] get_string_array (Json.Object obj, string member) {
        if (!obj.has_member (member)) {
            return {};
        }

        var arr = obj.get_array_member (member);
        string[] result = {};
        arr.foreach_element ((array, index, node) => {
            result += node.get_string ();
        });
        return result;
    }
}
