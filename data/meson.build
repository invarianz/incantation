app_id = 'io.github.invarianz.incantation'

# Desktop file
desktop_file = i18n.merge_file(
    input: app_id + '.desktop.in',
    output: app_id + '.desktop',
    po_dir: meson.project_source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications',
)

# Validate desktop file
desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
    test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

# AppStream metainfo
metainfo_file = i18n.merge_file(
    input: app_id + '.metainfo.xml.in',
    output: app_id + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

# Validate metainfo
appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
    test('Validate metainfo file', appstreamcli,
        args: ['validate', '--no-net', '--explain', metainfo_file],
    )
endif

# GSettings schema
install_data(
    app_id + '.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

# Compile schemas for testing
compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test('Validate GSettings schemas',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.current_source_dir()],
    )
endif

# GResource bundle (CSS, icons, etc.)
gnome.compile_resources(
    app_id,
    app_id + '.gresource.xml',
    gresource_bundle: true,
    install: true,
    install_dir: get_option('datadir') / app_id,
)

# Icons
icon_sizes = ['32', '48', '64', '128']

foreach size : icon_sizes
    install_data(
        'icons' / size + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / size + 'x' + size / 'apps',
        rename: app_id + '.svg',
    )
endforeach
