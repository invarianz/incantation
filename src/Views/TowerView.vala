/*
 * Copyright 2026 Incantation Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Incantation.TowerView : Gtk.Box {
    public signal void concept_selected (string concept_id, string language_id,
                                          Circle circle);

    public Settings settings { get; construct; }
    public Incantation.ContentLoader content_loader { get; construct; }
    public Incantation.ProgressService progress_service { get; construct; }

    // SVG viewBox: -80 -120 600 780 → image scaled 1.2× for 20% bigger
    private const double PIXEL_SCALE = 1.2;
    private const int IMG_WIDTH = 720;   // 600 * 1.2
    private const int IMG_HEIGHT = 936;  // 780 * 1.2
    private const double VB_Y_MIN = -120.0;

    private const int NUM_FLOORS = 7;

    private Gtk.DropDown language_dropdown;
    private Gtk.Picture tower_image;
    private Gtk.Button[] floor_buttons;
    private string[] available_languages;
    private string[] language_display_names;
    private string current_language;
    private Incantation.Language[] language_objects;
    private bool is_dark_mode;
    private bool[] floor_completed;

    private string svg_template;

    public TowerView (Settings settings, Incantation.ContentLoader content_loader,
                       Incantation.ProgressService progress_service) {
        Object (
            settings: settings,
            content_loader: content_loader,
            progress_service: progress_service,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );
    }

    construct {
        current_language = settings.get_string ("current-language");

        var granite_settings = Granite.Settings.get_default ();
        is_dark_mode = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            is_dark_mode = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            update_tower_image ();
        });

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 24,
            margin_end = 24,
            margin_top = 24,
            margin_bottom = 8
        };

        var spacer = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };

        language_dropdown = new Gtk.DropDown.from_strings ({}) {
            valign = Gtk.Align.CENTER
        };
        language_dropdown.notify["selected"].connect (on_language_changed);

        header_box.append (spacer);
        header_box.append (language_dropdown);

        tower_image = new Gtk.Picture () {
            can_shrink = false,
            content_fit = Gtk.ContentFit.CONTAIN,
            width_request = IMG_WIDTH,
            height_request = IMG_HEIGHT
        };

        // Layout: tower image + floor buttons in a Fixed container
        var layout = new Gtk.Fixed () {
            halign = Gtk.Align.CENTER
        };
        layout.put (tower_image, 0, 0);

        // Floor buttons aligned with each tower floor
        string[] floor_labels = {
            "Arcanum", "Observatory", "Scriptorium", "Laboratory",
            "Library", "Vestibule", "Dungeon"
        };
        double[] floor_center_y = { 115, 185, 255, 325, 395, 465, 535 };

        int btn_x = IMG_WIDTH + 16;
        floor_buttons = new Gtk.Button[NUM_FLOORS];
        floor_completed = new bool[NUM_FLOORS];

        for (int i = 0; i < NUM_FLOORS; i++) {
            var btn = new Gtk.Button.with_label (floor_labels[i]) {
                width_request = 110
            };
            btn.add_css_class ("floor-button");

            int floor_index = i;
            btn.clicked.connect (() => {
                on_floor_clicked (floor_index);
            });

            double pixel_y = (floor_center_y[i] - VB_Y_MIN) * PIXEL_SCALE;
            layout.put (btn, btn_x, (int) (pixel_y - 20));
            floor_buttons[i] = btn;
        }

        var scrolled = new Gtk.ScrolledWindow () {
            child = layout,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.AUTOMATIC
        };

        append (header_box);
        append (scrolled);

        load_svg_template ();
        populate_languages ();
    }

    public void refresh () {
        update_floor_states ();
        update_tower_image ();
    }

    private void update_floor_states () {
        GenericArray<Incantation.Concept> concepts;
        try {
            concepts = content_loader.load_concepts ();
        } catch (Incantation.ContentError e) {
            return;
        }

        for (int i = 0; i < NUM_FLOORS; i++) {
            floor_completed[i] = progress_service.is_floor_complete (
                current_language, i, concepts
            );
            bool unlocked = progress_service.is_floor_unlocked (
                current_language, i, concepts
            );
            floor_buttons[i].sensitive = unlocked;
        }
    }

    private void on_floor_clicked (int floor) {
        GenericArray<Incantation.Concept> concepts;
        try {
            concepts = content_loader.load_concepts ();
        } catch (Incantation.ContentError e) {
            return;
        }

        // Find the first non-mastered concept on this floor
        for (int i = 0; i < concepts.length; i++) {
            if (concepts[i].floor != floor) {
                continue;
            }
            var state = progress_service.compute_state (
                current_language, concepts[i].id, concepts[i].prerequisites
            );
            if (state != ConceptState.MASTERED) {
                var next_circle = progress_service.get_next_circle (
                    current_language, concepts[i].id
                );
                if (next_circle != null) {
                    concept_selected (concepts[i].id, current_language, next_circle);
                }
                return;
            }
        }
        // All concepts on this floor mastered — select the first one for review
        for (int i = 0; i < concepts.length; i++) {
            if (concepts[i].floor == floor) {
                concept_selected (concepts[i].id, current_language, Circle.FIRST);
                return;
            }
        }
    }

    private void load_svg_template () {
        try {
            var bytes = resources_lookup_data (
                "/io/github/invarianz/incantation/images/tower.svg",
                ResourceLookupFlags.NONE
            );
            svg_template = (string) bytes.get_data ();
        } catch (Error e) {
            warning ("Failed to load tower SVG template: %s", e.message);
        }
    }

    private string generate_atmosphere_defs () {
        if (is_dark_mode) {
            return """
    <radialGradient id="moon-glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0%%" stop-color="#e8e0d0" stop-opacity="0.2"/>
      <stop offset="50%%" stop-color="#c8c0b0" stop-opacity="0.08"/>
      <stop offset="100%%" stop-color="#c8c0b0" stop-opacity="0"/>
    </radialGradient>
    <mask id="crescent-mask">
      <rect x="-80" y="-120" width="600" height="780" fill="black"/>
      <circle cx="-20" cy="-65" r="20" fill="white"/>
      <circle cx="-10" cy="-70" r="16" fill="black"/>
    </mask>
    <linearGradient id="hill-far" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#1a2840"/>
      <stop offset="100%%" stop-color="#1e2a3a"/>
    </linearGradient>
    <linearGradient id="hill-near" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#1e3028"/>
      <stop offset="100%%" stop-color="#263828"/>
    </linearGradient>
    <linearGradient id="tree-fill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#1a3020"/>
      <stop offset="100%%" stop-color="#142818"/>
    </linearGradient>
    <radialGradient id="particle-glow">
      <stop offset="0%%" stop-color="#c8a8f0" stop-opacity="0.8"/>
      <stop offset="60%%" stop-color="#c8a8f0" stop-opacity="0.2"/>
      <stop offset="100%%" stop-color="#c8a8f0" stop-opacity="0"/>
    </radialGradient>
""";
        } else {
            return """
    <radialGradient id="sun-glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0%%" stop-color="#fff8e0" stop-opacity="0.5"/>
      <stop offset="30%%" stop-color="#ffe880" stop-opacity="0.15"/>
      <stop offset="60%%" stop-color="#ffd040" stop-opacity="0.05"/>
      <stop offset="100%%" stop-color="#ffd040" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="hill-far" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#4a7848"/>
      <stop offset="100%%" stop-color="#3a6838"/>
    </linearGradient>
    <linearGradient id="hill-near" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#3a7838"/>
      <stop offset="100%%" stop-color="#2e6830"/>
    </linearGradient>
    <linearGradient id="tree-fill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#2a5828"/>
      <stop offset="100%%" stop-color="#1e4820"/>
    </linearGradient>
    <radialGradient id="particle-glow">
      <stop offset="0%%" stop-color="#d8c0f8" stop-opacity="0.6"/>
      <stop offset="60%%" stop-color="#d8c0f8" stop-opacity="0.15"/>
      <stop offset="100%%" stop-color="#d8c0f8" stop-opacity="0"/>
    </radialGradient>
""";
        }
    }

    private string generate_atmosphere_scene () {
        var sb = new StringBuilder ();

        if (is_dark_mode) {
            // Stars
            sb.append ("  <!-- Stars -->\n");
            sb.append ("  <circle cx=\"-40\" cy=\"-100\" r=\"1\" fill=\"#e0d8f0\" opacity=\"0.7\"/>\n");
            sb.append ("  <circle cx=\"30\" cy=\"-80\" r=\"0.6\" fill=\"#d0c8e0\" opacity=\"0.5\"/>\n");
            sb.append ("  <circle cx=\"100\" cy=\"-110\" r=\"1.2\" fill=\"#e8e0f8\" opacity=\"0.8\"/>\n");
            sb.append ("  <circle cx=\"160\" cy=\"-90\" r=\"0.5\" fill=\"#d8d0e8\" opacity=\"0.4\"/>\n");
            sb.append ("  <circle cx=\"250\" cy=\"-115\" r=\"0.8\" fill=\"#e0d8f0\" opacity=\"0.6\"/>\n");
            sb.append ("  <circle cx=\"320\" cy=\"-95\" r=\"1\" fill=\"#e8e0f0\" opacity=\"0.7\"/>\n");
            sb.append ("  <circle cx=\"380\" cy=\"-108\" r=\"0.7\" fill=\"#d0c8e0\" opacity=\"0.5\"/>\n");
            sb.append ("  <circle cx=\"440\" cy=\"-85\" r=\"1.1\" fill=\"#e0d8f0\" opacity=\"0.65\"/>\n");
            sb.append ("  <circle cx=\"490\" cy=\"-105\" r=\"0.6\" fill=\"#d8d0e8\" opacity=\"0.45\"/>\n");
            sb.append ("  <circle cx=\"-10\" cy=\"-55\" r=\"0.7\" fill=\"#e0d8f0\" opacity=\"0.5\"/>\n");
            sb.append ("  <circle cx=\"70\" cy=\"-40\" r=\"0.5\" fill=\"#d0c8e0\" opacity=\"0.4\"/>\n");
            sb.append ("  <circle cx=\"180\" cy=\"-60\" r=\"0.9\" fill=\"#e8e0f8\" opacity=\"0.6\"/>\n");
            sb.append ("  <circle cx=\"360\" cy=\"-55\" r=\"1\" fill=\"#e0d8f0\" opacity=\"0.55\"/>\n");
            sb.append ("  <circle cx=\"460\" cy=\"-45\" r=\"0.8\" fill=\"#e8e0f0\" opacity=\"0.5\"/>\n");
            sb.append ("  <circle cx=\"500\" cy=\"-70\" r=\"0.9\" fill=\"#d8d0e8\" opacity=\"0.5\"/>\n");
            // Twinkling
            sb.append ("  <circle cx=\"140\" cy=\"-110\" r=\"2.5\" fill=\"#e8e0f8\" opacity=\"0.08\"/>\n");
            sb.append ("  <circle cx=\"140\" cy=\"-110\" r=\"1\" fill=\"#e8e0f8\" opacity=\"0.9\"/>\n");
            sb.append ("  <circle cx=\"400\" cy=\"-70\" r=\"2\" fill=\"#e0d8f0\" opacity=\"0.06\"/>\n");
            sb.append ("  <circle cx=\"400\" cy=\"-70\" r=\"0.8\" fill=\"#e0d8f0\" opacity=\"0.8\"/>\n");
            // Crescent moon using mask
            sb.append ("  <circle cx=\"-20\" cy=\"-65\" r=\"50\" fill=\"url(#moon-glow)\"/>\n");
            sb.append ("  <rect x=\"-80\" y=\"-120\" width=\"600\" height=\"780\" fill=\"#e8e0d0\" opacity=\"0.85\" mask=\"url(#crescent-mask)\"/>\n");
            sb.append ("  <circle cx=\"-26\" cy=\"-72\" r=\"2.5\" fill=\"#d8d0c0\" opacity=\"0.15\" mask=\"url(#crescent-mask)\"/>\n");
            sb.append ("  <circle cx=\"-18\" cy=\"-58\" r=\"2\" fill=\"#d8d0c0\" opacity=\"0.1\" mask=\"url(#crescent-mask)\"/>\n");
            sb.append ("  <circle cx=\"-28\" cy=\"-62\" r=\"1.2\" fill=\"#d8d0c0\" opacity=\"0.12\" mask=\"url(#crescent-mask)\"/>\n\n");
        } else {
            // Sun (larger)
            sb.append ("  <!-- Sun -->\n");
            sb.append ("  <circle cx=\"460\" cy=\"-50\" r=\"100\" fill=\"url(#sun-glow)\"/>\n");
            sb.append ("  <circle cx=\"460\" cy=\"-50\" r=\"28\" fill=\"#fff4d0\" opacity=\"0.95\"/>\n");
            sb.append ("  <circle cx=\"460\" cy=\"-50\" r=\"23\" fill=\"#ffe880\" opacity=\"0.6\"/>\n\n");
            // Clouds
            sb.append ("  <!-- Clouds -->\n");
            sb.append ("  <ellipse cx=\"80\" cy=\"-50\" rx=\"50\" ry=\"14\" fill=\"white\" opacity=\"0.35\"/>\n");
            sb.append ("  <ellipse cx=\"60\" cy=\"-55\" rx=\"30\" ry=\"10\" fill=\"white\" opacity=\"0.3\"/>\n");
            sb.append ("  <ellipse cx=\"110\" cy=\"-48\" rx=\"25\" ry=\"9\" fill=\"white\" opacity=\"0.25\"/>\n\n");
            sb.append ("  <ellipse cx=\"300\" cy=\"-80\" rx=\"40\" ry=\"12\" fill=\"white\" opacity=\"0.3\"/>\n");
            sb.append ("  <ellipse cx=\"280\" cy=\"-84\" rx=\"25\" ry=\"8\" fill=\"white\" opacity=\"0.25\"/>\n");
            sb.append ("  <ellipse cx=\"325\" cy=\"-78\" rx=\"22\" ry=\"8\" fill=\"white\" opacity=\"0.2\"/>\n\n");
            sb.append ("  <ellipse cx=\"-30\" cy=\"-20\" rx=\"35\" ry=\"10\" fill=\"white\" opacity=\"0.2\"/>\n");
            sb.append ("  <ellipse cx=\"480\" cy=\"-15\" rx=\"30\" ry=\"9\" fill=\"white\" opacity=\"0.18\"/>\n\n");
        }

        // Landscape elements (masked for edge fade)
        sb.append ("  <g mask=\"url(#edge-fade)\">\n");
        // Hills (shared, different colors via gradients)
        sb.append ("  <!-- Distant hills -->\n");
        sb.append ("  <path d=\"M-80,460 Q-20,380 60,420 Q140,370 220,400 Q300,350 380,390 Q440,360 520,410 L520,500 L-80,500 Z\" fill=\"url(#hill-far)\" opacity=\"0.6\"/>\n");
        sb.append ("  <path d=\"M-80,480 Q0,420 80,450 Q160,400 240,440 Q320,410 400,445 Q460,420 520,450 L520,500 L-80,500 Z\" fill=\"url(#hill-near)\" opacity=\"0.5\"/>\n\n");

        // Trees
        var tree_opacity = is_dark_mode ? "0.5" : "0.7";
        var tree_opacity2 = is_dark_mode ? "0.45" : "0.6";
        var trunk_color = is_dark_mode ? "#2a1a12" : "#4a3020";
        sb.append ("  <!-- Background trees -->\n");
        sb.append_printf ("  <path d=\"M-55,458 L-50,435 L-45,458 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M-42,455 L-38,428 L-34,455 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity2);
        sb.append_printf ("  <path d=\"M-30,460 L-25,438 L-20,460 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M440,440 L445,415 L450,440 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M455,445 L460,418 L465,445 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity2);
        sb.append_printf ("  <path d=\"M470,438 L475,412 L480,438 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M485,442 L489,420 L493,442 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n\n", tree_opacity2);

        // Foreground trees
        sb.append ("  <!-- Foreground trees -->\n");
        sb.append_printf ("  <rect x=\"-52\" y=\"445\" width=\"4\" height=\"52\" fill=\"%s\" opacity=\"0.7\"/>\n", trunk_color);
        sb.append ("  <path d=\"M-70,460 L-50,380 L-30,460 Z\" fill=\"url(#tree-fill)\" opacity=\"0.85\"/>\n");
        sb.append_printf ("  <path d=\"M-65,440 L-50,395 L-35,440 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M-62,420 L-50,385 L-38,420 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n\n", tree_opacity2);

        sb.append_printf ("  <rect x=\"-25\" y=\"460\" width=\"3.5\" height=\"37\" fill=\"%s\" opacity=\"0.6\"/>\n", trunk_color);
        sb.append ("  <path d=\"M-40,470 L-23,410 L-6,470 Z\" fill=\"url(#tree-fill)\" opacity=\"0.75\"/>\n");
        sb.append_printf ("  <path d=\"M-36,455 L-23,420 L-10,455 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n\n", tree_opacity2);

        sb.append_printf ("  <rect x=\"488\" y=\"440\" width=\"4\" height=\"57\" fill=\"%s\" opacity=\"0.7\"/>\n", trunk_color);
        sb.append ("  <path d=\"M470,455 L490,370 L510,455 Z\" fill=\"url(#tree-fill)\" opacity=\"0.85\"/>\n");
        sb.append_printf ("  <path d=\"M474,435 L490,385 L506,435 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n", tree_opacity);
        sb.append_printf ("  <path d=\"M477,415 L490,382 L503,415 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n\n", tree_opacity2);

        sb.append_printf ("  <rect x=\"460\" y=\"455\" width=\"3.5\" height=\"42\" fill=\"%s\" opacity=\"0.6\"/>\n", trunk_color);
        sb.append ("  <path d=\"M445,465 L462,405 L479,465 Z\" fill=\"url(#tree-fill)\" opacity=\"0.75\"/>\n");
        sb.append_printf ("  <path d=\"M449,450 L462,415 L475,450 Z\" fill=\"url(#tree-fill)\" opacity=\"%s\"/>\n\n", tree_opacity2);

        // Bushes
        var bush_color = is_dark_mode ? "#1e3020" : "#2a5028";
        var bush_color2 = is_dark_mode ? "#223824" : "#305830";
        sb.append_printf ("  <ellipse cx=\"-10\" cy=\"492\" rx=\"18\" ry=\"10\" fill=\"%s\" opacity=\"0.6\"/>\n", bush_color);
        sb.append_printf ("  <ellipse cx=\"5\" cy=\"490\" rx=\"12\" ry=\"8\" fill=\"%s\" opacity=\"0.5\"/>\n", bush_color2);
        sb.append_printf ("  <ellipse cx=\"440\" cy=\"490\" rx=\"15\" ry=\"9\" fill=\"%s\" opacity=\"0.6\"/>\n", bush_color);
        sb.append_printf ("  <ellipse cx=\"455\" cy=\"492\" rx=\"12\" ry=\"8\" fill=\"%s\" opacity=\"0.5\"/>\n", bush_color2);
        sb.append ("  </g>\n\n");

        return sb.str;
    }

    private string generate_atmosphere_overlay () {
        var sb = new StringBuilder ();

        // Mist
        var mist_color = is_dark_mode ? "#8898b0" : "#c0d0e0";
        sb.append_printf ("  <ellipse cx=\"220\" cy=\"495\" rx=\"250\" ry=\"18\" fill=\"%s\" opacity=\"0.08\"/>\n", mist_color);
        sb.append_printf ("  <ellipse cx=\"180\" cy=\"490\" rx=\"180\" ry=\"12\" fill=\"%s\" opacity=\"0.06\"/>\n", mist_color);
        sb.append_printf ("  <ellipse cx=\"280\" cy=\"492\" rx=\"160\" ry=\"10\" fill=\"%s\" opacity=\"0.05\"/>\n\n", mist_color);

        // Magical particles
        sb.append ("  <circle cx=\"170\" cy=\"120\" r=\"4\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"170\" cy=\"120\" r=\"1.2\" fill=\"#c8a8f0\" opacity=\"0.9\"/>\n");
        sb.append ("  <circle cx=\"275\" cy=\"200\" r=\"3.5\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"275\" cy=\"200\" r=\"1\" fill=\"#c8a8f0\" opacity=\"0.85\"/>\n");
        sb.append ("  <circle cx=\"130\" cy=\"310\" r=\"3\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"130\" cy=\"310\" r=\"0.9\" fill=\"#c8a8f0\" opacity=\"0.8\"/>\n");
        sb.append ("  <circle cx=\"310\" cy=\"370\" r=\"3.5\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"310\" cy=\"370\" r=\"1\" fill=\"#c8a8f0\" opacity=\"0.85\"/>\n");
        sb.append ("  <circle cx=\"160\" cy=\"440\" r=\"2.5\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"160\" cy=\"440\" r=\"0.8\" fill=\"#c8a8f0\" opacity=\"0.75\"/>\n");
        sb.append ("  <circle cx=\"350\" cy=\"260\" r=\"3\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"350\" cy=\"260\" r=\"0.9\" fill=\"#c8a8f0\" opacity=\"0.8\"/>\n");
        sb.append ("  <circle cx=\"80\" cy=\"470\" r=\"2.5\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"80\" cy=\"470\" r=\"0.8\" fill=\"#c8a8f0\" opacity=\"0.7\"/>\n");
        sb.append ("  <circle cx=\"370\" cy=\"460\" r=\"3\" fill=\"url(#particle-glow)\"/>\n");
        sb.append ("  <circle cx=\"370\" cy=\"460\" r=\"0.9\" fill=\"#c8a8f0\" opacity=\"0.75\"/>\n");

        if (is_dark_mode) {
            // Fireflies
            sb.append ("  <circle cx=\"-30\" cy=\"470\" r=\"1.5\" fill=\"#e0d860\" opacity=\"0.4\"/>\n");
            sb.append ("  <circle cx=\"460\" cy=\"465\" r=\"1.2\" fill=\"#e0d860\" opacity=\"0.35\"/>\n");
            sb.append ("  <circle cx=\"0\" cy=\"485\" r=\"1\" fill=\"#e0d860\" opacity=\"0.3\"/>\n");
            sb.append ("  <circle cx=\"480\" cy=\"480\" r=\"1.3\" fill=\"#e0d860\" opacity=\"0.3\"/>\n");
        }

        return sb.str;
    }

    private string generate_side_light () {
        if (is_dark_mode) {
            // Moonlight from the left (moon is at x=-20)
            return """    <linearGradient id="side-light" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%%" stop-color="#8090c0" stop-opacity="0.10"/>
      <stop offset="30%%" stop-color="#8090c0" stop-opacity="0.04"/>
      <stop offset="70%%" stop-color="black" stop-opacity="0.03"/>
      <stop offset="100%%" stop-color="black" stop-opacity="0.10"/>
    </linearGradient>
""";
        } else {
            // Sunlight from the right (sun is at x=460)
            return """    <linearGradient id="side-light" x1="1" y1="0" x2="0" y2="0">
      <stop offset="0%%" stop-color="#fff0c0" stop-opacity="0.14"/>
      <stop offset="30%%" stop-color="#fff0c0" stop-opacity="0.06"/>
      <stop offset="70%%" stop-color="black" stop-opacity="0.02"/>
      <stop offset="100%%" stop-color="black" stop-opacity="0.06"/>
    </linearGradient>
""";
        }
    }

    private string generate_window_defs () {
        if (is_dark_mode) {
            // Night: original blue-teal stained glass
            return """    <linearGradient id="glass" x1="0.1" y1="0" x2="0.9" y2="1">
      <stop offset="0%%" stop-color="#6a9aaa"/>
      <stop offset="30%%" stop-color="#7eaab8"/>
      <stop offset="70%%" stop-color="#8ab4c0"/>
      <stop offset="100%%" stop-color="#6e9ea8"/>
    </linearGradient>
    <linearGradient id="window-depth" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#1a1a2a" stop-opacity="0.4"/>
      <stop offset="100%%" stop-color="#1a1a2a" stop-opacity="0.1"/>
    </linearGradient>
""";
        } else {
            // Day: sky-reflecting blue-teal glass
            return """    <linearGradient id="glass" x1="0.1" y1="0" x2="0.9" y2="1">
      <stop offset="0%%" stop-color="#88b8d0"/>
      <stop offset="30%%" stop-color="#9ac8d8"/>
      <stop offset="70%%" stop-color="#a0cce0"/>
      <stop offset="100%%" stop-color="#88bcd0"/>
    </linearGradient>
    <linearGradient id="window-depth" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#4080a0" stop-opacity="0.15"/>
      <stop offset="100%%" stop-color="#4080a0" stop-opacity="0.05"/>
    </linearGradient>
""";
        }
    }

    private string generate_roof_defs (Incantation.Language lang) {
        var top = lang.roof_color_top ?? "#c49af0";
        var bottom = lang.roof_color_bottom ?? "#6a30a8";

        return """    <!-- Roof left face (lit side) -->
    <linearGradient id="roof-left" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%%" stop-color="%s"/>
      <stop offset="30%%" stop-color="%s" stop-opacity="0.9"/>
      <stop offset="100%%" stop-color="%s" stop-opacity="0.85"/>
    </linearGradient>

    <!-- Roof right face (shadow side) -->
    <linearGradient id="roof-right" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="%s" stop-opacity="0.9"/>
      <stop offset="40%%" stop-color="%s" stop-opacity="0.85"/>
      <stop offset="100%%" stop-color="%s"/>
    </linearGradient>

    <!-- Slate shingle pattern for roof -->
    <pattern id="roof-shingle" patternUnits="userSpaceOnUse" width="16" height="8">
      <rect width="16" height="8" fill="none"/>
      <line x1="0" y1="8" x2="16" y2="8" stroke="black" stroke-width="0.4" opacity="0.15"/>
      <line x1="4" y1="0" x2="4" y2="8" stroke="black" stroke-width="0.3" opacity="0.08"/>
      <line x1="12" y1="0" x2="12" y2="8" stroke="black" stroke-width="0.3" opacity="0.08"/>
    </pattern>

""".printf (top, top, bottom, top, bottom, bottom);
    }

    private string generate_roof_rendering (Incantation.Language lang) {
        var logo_path = lang.logo_path ?? "";
        var scale = lang.logo_scale > 0 ? lang.logo_scale : 0.7;
        var cx = lang.logo_center_x;
        var cy = lang.logo_center_y;
        var tx = 220.0 - cx * scale;
        var ty = 50.0 - cy * scale;
        var top = lang.roof_color_top ?? "#c49af0";
        var bottom = lang.roof_color_bottom ?? "#6a30a8";

        var sb = new StringBuilder ();
        sb.append ("  <!-- ========== ROOF ========== -->\n");
        sb.append ("  <polygon points=\"220,18 185,80 220,80\" fill=\"url(#roof-left)\"/>\n");
        sb.append ("  <polygon points=\"220,18 185,80 220,80\" fill=\"url(#roof-shingle)\" opacity=\"0.5\"/>\n");
        sb.append ("  <polygon points=\"220,18 220,80 255,80\" fill=\"url(#roof-right)\"/>\n");
        sb.append ("  <polygon points=\"220,18 220,80 255,80\" fill=\"url(#roof-shingle)\" opacity=\"0.4\"/>\n");
        sb.append_printf ("  <line x1=\"220\" y1=\"18\" x2=\"220\" y2=\"80\" stroke=\"%s\" stroke-width=\"1\" opacity=\"0.35\"/>\n", top);
        sb.append_printf ("  <line x1=\"220\" y1=\"18\" x2=\"185\" y2=\"80\" stroke=\"%s\" stroke-width=\"1\" opacity=\"0.5\"/>\n", top);
        sb.append_printf ("  <line x1=\"220\" y1=\"18\" x2=\"255\" y2=\"80\" stroke=\"%s\" stroke-width=\"1\" opacity=\"0.4\"/>\n", bottom);
        sb.append_printf ("  <line x1=\"185\" y1=\"80\" x2=\"255\" y2=\"80\" stroke=\"%s\" stroke-width=\"0.8\" opacity=\"0.3\"/>\n\n", bottom);

        if (logo_path.length > 0) {
            sb.append_printf ("  <g transform=\"translate(%.1f, %.1f) scale(%.1f)\" opacity=\"0.5\">\n", tx, ty, scale);
            sb.append_printf ("    <path d=\"%s\" fill=\"white\"/>\n", logo_path);
            sb.append ("  </g>\n\n");
        }

        return sb.str;
    }

    private void update_tower_image () {
        if (svg_template == null || svg_template.length == 0) {
            return;
        }

        Incantation.Language? lang = null;
        for (int i = 0; i < language_objects.length; i++) {
            if (language_objects[i].id == current_language) {
                lang = language_objects[i];
                break;
            }
        }

        if (lang == null) {
            return;
        }

        // Build the SVG by replacing placeholders
        var svg = svg_template;
        svg = svg.replace ("    <!-- ATMOSPHERE_DEFS_PLACEHOLDER -->", generate_atmosphere_defs ());
        svg = svg.replace ("    <!-- SIDE_LIGHT_PLACEHOLDER -->", generate_side_light ());
        svg = svg.replace ("    <!-- WINDOW_DEFS_PLACEHOLDER -->", generate_window_defs ());
        svg = svg.replace ("  <!-- ATMOSPHERE_SCENE_PLACEHOLDER -->", generate_atmosphere_scene ());
        svg = svg.replace ("  <!-- ATMOSPHERE_OVERLAY_PLACEHOLDER -->", generate_atmosphere_overlay ());

        // Strip decorations for incomplete floors
        // DECORATION_FLOOR_N appears when floor N is complete
        for (int i = 1; i <= 6; i++) {
            var start_marker = "  <!-- DECORATION_FLOOR_%d_START -->".printf (i);
            var end_marker = "  <!-- DECORATION_FLOOR_%d_END -->".printf (i);
            if (!floor_completed[i]) {
                // Remove everything between start and end markers (inclusive)
                var start_pos = svg.index_of (start_marker);
                var end_pos = svg.index_of (end_marker);
                if (start_pos >= 0 && end_pos >= 0) {
                    svg = svg[0:start_pos] + svg[end_pos + end_marker.length:svg.length];
                }
            }
        }

        // Replace roof defs
        var roof_def_marker = "    <!-- Roof left face";
        var roof_def_pos = svg.index_of (roof_def_marker);
        var shingle_end_marker = "    </pattern>\n\n    <radialGradient id=\"star-glow\">";
        var shingle_end_pos = svg.index_of (shingle_end_marker);

        var roof_render_marker = "  <!-- ========== ROOF";
        var roof_render_pos = svg.index_of (roof_render_marker);
        var star_marker = "  <!-- Star with subtle glow";
        var star_pos = svg.index_of (star_marker);

        if (roof_def_pos >= 0 && shingle_end_pos >= 0 &&
            roof_render_pos >= 0 && star_pos >= 0) {
            var before_roof_defs = svg[0:roof_def_pos];
            var after_defs_start = shingle_end_pos + "    </pattern>\n".length;
            var between = svg[after_defs_start:roof_render_pos];
            var after_roof = svg[star_pos:svg.length];

            svg = before_roof_defs
                + generate_roof_defs (lang)
                + between
                + generate_roof_rendering (lang)
                + after_roof;
        }

        var bytes = new Bytes (svg.data);
        try {
            var texture = Gdk.Texture.from_bytes (bytes);
            tower_image.paintable = texture;
        } catch (Error e) {
            warning ("Failed to render tower SVG: %s", e.message);
        }
    }

    private void populate_languages () {
        try {
            available_languages = content_loader.get_available_languages ();
        } catch (Incantation.ContentError e) {
            warning ("Failed to load languages: %s", e.message);
            available_languages = {};
            return;
        }

        language_display_names = {};
        language_objects = {};
        int selected_index = 0;

        for (int i = 0; i < available_languages.length; i++) {
            try {
                GenericArray<Incantation.LanguageMapping> mappings;
                var lang = content_loader.load_language_manifest (
                    available_languages[i], out mappings
                );
                language_display_names += _("Tower of %s").printf (lang.name);
                language_objects += lang;
            } catch (Incantation.ContentError e) {
                language_display_names += _("Tower of %s").printf (available_languages[i]);
                language_objects += new Incantation.Language ();
            }

            if (available_languages[i] == current_language) {
                selected_index = i;
            }
        }

        language_dropdown.model = new Gtk.StringList (language_display_names);
        language_dropdown.selected = selected_index;
        update_floor_states ();
        update_tower_image ();
    }

    private void on_language_changed () {
        var idx = (int) language_dropdown.selected;
        if (idx >= 0 && idx < available_languages.length) {
            current_language = available_languages[idx];
            settings.set_string ("current-language", current_language);
            update_floor_states ();
            update_tower_image ();
        }
    }
}
