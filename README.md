# gnome_desktop

Ruby bindings for [libgnome-desktop-4](https://gitlab.gnome.org/GNOME/gnome-desktop),
the GNOME Utility Library — the locale and language name database behind
GNOME's language chooser, the XKB layout registry behind its input-source
list, the monitor-vendor table, the thumbnail factory, the wall clock and the
idle monitor.

```ruby
require "gnome_desktop"

ok, language, country = GnomeDesktop.parse_locale("en_GB.UTF-8@euro")
GnomeDesktop.get_language_from_code("en", nil)   # => "English"

xkb = GnomeDesktop::XkbInfo.new
xkb.all_layouts                                  # => ["us", "gb", "de", ...]
xkb.get_layout_info("us")                        # => [true, "English (US)", "en", "us", ""]

GnomeDesktop::PnpIds.new.get_pnp_id("DEL")       # => "Dell Inc."
GnomeDesktop::WallClock.new.clock                # => "3 Nov 00:42"
```

This is `GnomeDesktop-4.0`. Three other namespaces ship from the same C
package and are not defined here: `GnomeDesktop-3.0` is the GTK3 generation of
the same library, and `GnomeBG-4.0` and `GnomeRR-4.0` both depend on
`Gdk-4.0`, so each belongs in a gem of its own rather than dragging GTK4 into
this one.

## How this works

libgnome-desktop ships a GObject Introspection typelib that describes every
class, method, property and signal it has. `GnomeDesktop::Loader` — twenty
lines — hands that typelib to ruby-gnome's `GObjectIntrospection::Loader`,
which defines the Ruby classes from it at `require` time.

So this gem is pure Ruby: no extension of its own, no Cargo workspace, no
per-platform binary. You get the whole namespace rather than the subset
somebody got round to wrapping by hand, and it does not drift when the library
gains API.

It is worth being precise about what that does and does not buy you at install
time. `gem install gnome_desktop` still compiles C, because
`gobject-introspection` and `glib2` are themselves native extensions built
against glib — so a compiler and glib's development headers are needed. What
this gem adds on top of that is nothing: those two are what every ruby-gnome
application already has, since `gtk4` depends on them. If you are writing a
Ruby GTK app, gnome_desktop costs you no build step you were not already
paying.

This is how [ruby-gnome](https://github.com/ruby-gnome/ruby-gnome) itself ships
gtksourceview5, libsecret and the rest.

## What you must install

The typelib is a C-library artefact, so it belongs to your distribution and
this gem cannot install it. Two things are needed: the introspection data for
libgnome-desktop-4, and `gsettings-desktop-schemas`, because
`GnomeDesktop::XkbInfo`'s constructor opens a GSettings for
`org.gnome.desktop.input-sources` and a missing schema is a `g_error`, which
aborts the process rather than raising.

| | typelib | schemas |
|---|---|---|
| Debian / Ubuntu | `gir1.2-gnomedesktop-4.0` | `gsettings-desktop-schemas` |
| Fedora | `gnome-desktop4` | `gsettings-desktop-schemas` |
| Arch | `gnome-desktop-4` | `gsettings-desktop-schemas` |
| nix | `pkgs.gnome-desktop` | `pkgs.gsettings-desktop-schemas` |

If your distribution has renamed one of these, the file to search for is
`GnomeDesktop-4.0.typelib`. Two more typelibs come along as dependencies —
`GDesktopEnums-3.0` (from `gsettings-desktop-schemas`, which is not an obvious
place to look for it) and `GdkPixbuf-2.0` — plus `Gio-2.0` from glib, which
the `glib2` gem already requires.

Several of these lookups read data files rather than compute: xkeyboard-config
supplies the keyboard layout registry, hwdata the monitor-vendor table,
iso-codes and the system locale archive the country and language names. A
machine without them returns empty lists and nils, which is not a fault in
this binding.

If the typelibs are not in the default search path, point `GI_TYPELIB_PATH` at
the directory holding `GnomeDesktop-4.0.typelib` and `GSETTINGS_SCHEMA_DIR` at
the one holding `gschemas.compiled`. The dev shell in `flake.nix` does both.

**One trap worth knowing.** The typelib must come from the same glib build as
the `gobject-introspection` gem. Mixing two registers GIO twice in one process
and fails with `cannot register existing type 'GTlsCertificate'`. Under nix,
take both from one nixpkgs — and note that glib's typelibs are in its `out`
output, not the default `bin` one.

## Known gap

`GnomeDesktop::DesktopThumbnailFactory.new` cannot be called through the
typelib. Its one argument is `GnomeDesktopThumbnailSize`, a plain C enum with
no GType, so GI has nothing to marshal it from and reports the signature as
`interface(NilClass(void))`. The `GnomeDesktop::DesktopThumbnailSize`
constants are defined and the class exists; constructing it needs a fix
upstream in libgnome-desktop's annotations, not here.

## Development

```sh
nix develop
bin/test
```

## Licence

Apache-2.0. libgnome-desktop itself is LGPL-2.0-or-later; this gem links
nothing and copies no libgnome-desktop code — it reads a description of it at
runtime.
