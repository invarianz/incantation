project(
    'incantation',
    'vala', 'c',
    version: '0.1.0',
    meson_version: '>= 0.56.0',
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
json_glib_dep = dependency('json-glib-1.0')
sqlite3_dep = dependency('sqlite3')

dependencies = [
    gtk_dep,
    granite_dep,
    glib_dep,
    gobject_dep,
    gio_dep,
    json_glib_dep,
    sqlite3_dep,
]

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
)

executable(
    app_id,
    sources,
    dependencies: dependencies,
    install: true,
)

subdir('data')
subdir('po')
