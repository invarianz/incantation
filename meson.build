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
dependencies = [
    gtk_dep,
    granite_dep,
    glib_dep,
    gobject_dep,
    gio_dep,
]

subdir('data')

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Views/HomeView.vala',
    'src/Views/TowerView.vala',
    'src/Views/GrimoireView.vala',
    'src/Views/ProfileView.vala',
    'src/Widgets/FlameDisplay.vala',
    'src/Widgets/Sidebar.vala',
)

executable(
    app_id,
    sources,
    app_resources,
    dependencies: dependencies,
    install: true,
)

subdir('po')
