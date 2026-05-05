project(
    'incantation',
    'vala', 'c',
    version: '0.1.0',
    meson_version: '>= 0.59.0',
)

gnome = import('gnome')
i18n = import('i18n')

app_id = 'io.github.invarianz.incantation'

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c',
)

gtk_dep = dependency('gtk4')
granite_dep = dependency('granite-7')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
json_dep = dependency('json-glib-1.0')
dependencies = [
    gtk_dep,
    granite_dep,
    glib_dep,
    gobject_dep,
    gio_dep,
    json_dep,
]

subdir('data')

config_data = configuration_data()
config_data.set_quoted(
    'CONTENT_DIR',
    get_option('prefix') / get_option('datadir') / meson.project_name() / 'content',
)

config_file = configure_file(
    input: 'src/Config.vala.in',
    output: 'Config.vala',
    configuration: config_data,
)

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Models/ConceptState.vala',
    'src/Models/ExerciseEnums.vala',
    'src/Models/ExerciseData.vala',
    'src/Models/OathTier.vala',
    'src/Models/Language.vala',
    'src/Models/Concept.vala',
    'src/Models/LanguageMapping.vala',
    'src/Models/Exercise.vala',
    'src/Models/MultipleChoiceExercise.vala',
    'src/Models/MatchingExercise.vala',
    'src/Models/TraceExercise.vala',
    'src/Models/ExplainExercise.vala',
    'src/Models/ParsonsExercise.vala',
    'src/Models/MicroParsonsExercise.vala',
    'src/Models/FillBlankExercise.vala',
    'src/Models/TypeCodeExercise.vala',
    'src/Models/SpotBugExercise.vala',
    'src/Models/PredictOutputExercise.vala',
    'src/Models/RefactorExercise.vala',
    'src/Models/FreeWriteExercise.vala',
    'src/Models/SessionResult.vala',
    'src/Services/ContentLoader.vala',
    'src/Services/ProgressService.vala',
    'src/Views/HomeView.vala',
    'src/Views/TowerView.vala',
    'src/Views/GrimoireView.vala',
    'src/Views/ProfileView.vala',
    'src/Views/SessionView.vala',
    'src/Widgets/ConceptCard.vala',
    'src/Widgets/ExerciseWidget.vala',
    'src/Widgets/FlameDisplay.vala',
    'src/Widgets/SessionResultsWidget.vala',
    'src/Widgets/Sidebar.vala',
    'src/Widgets/SpellChainDisplay.vala',
)

executable(
    app_id,
    sources,
    config_file,
    app_resources,
    dependencies: dependencies,
    install: true,
)

subdir('po')
