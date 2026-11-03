{
  description = "gnome_desktop — Ruby bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "gnome_desktop-gemspec" { } ''
          mkdir -p $out/lib/gnome_desktop
          cp ${./gnome_desktop.gemspec}         $out/gnome_desktop.gemspec
          cp ${./lib/gnome_desktop/version.rb}  $out/lib/gnome_desktop/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "gnome_desktop-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

        # The namespaces the loader needs at require time. GnomeDesktop-4.0
        # names three dependencies -- GDesktopEnums-3.0, GdkPixbuf-2.0 and
        # Gio-2.0 -- and the loader resolves them transitively, so each one's
        # girepository directory has to be here too or the load fails with
        # "Typelib file for namespace 'GDesktopEnums' not found".
        # GDesktopEnums is the counterintuitive one: it ships in
        # gsettings-desktop-schemas, not in anything called gnome-desktop.
        #
        # pkgs.gtk4 would drag these in by accident, and that is what the
        # generic port scaffold reaches for -- but GnomeDesktop-4.0 does not
        # depend on Gdk at all. (GnomeBG-4.0 and GnomeRR-4.0 do, which is one
        # reason they belong in gems of their own.) The four below are what
        # the GIR's own <include> lines ask for and nothing more.
        #
        # `makeSearchPath` would take each package's *first* output, and glib's
        # first output is `bin`, which carries no typelibs -- hence the
        # explicit `.out`. gdk-pixbuf has the same shape; its first output is
        # `man`. This is the trap the port scaffold documents.
        typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0"
          (map (drv: drv.out or drv) [
            pkgs.gnome-desktop
            pkgs.gsettings-desktop-schemas
            pkgs.gdk-pixbuf
            pkgs.glib
          ]);

        # Not optional, and not visible in the typelib at all. `XkbInfo.new`
        # opens a GSettings for org.gnome.desktop.input-sources, and a
        # GSettings for a schema that is not installed is a GLib-GIO-ERROR,
        # which g_error turns into an abort -- the process dies with
        #   No GSettings schemas are installed on the system
        # rather than raising something Ruby could rescue. So the schemas from
        # gsettings-desktop-schemas have to be found before anything touches
        # that class. This cost one confusing crash to find.
        schemaPath = pkgs.lib.concatMapStringsSep ":" pkgs.glib.getSchemaPath [
          pkgs.gsettings-desktop-schemas
          pkgs.glib
        ];
      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # libgnome-desktop itself, for its typelib. Taking it from the
            # same nixpkgs as the gobject-introspection gem is not a tidiness
            # point: a typelib built against a different glib registers GIO a
            # second time in one process and dies with
            #   cannot register existing type 'GTlsCertificate'
            #
            # pkgs.gnome-desktop (44.5 here) is one derivation holding both
            # libgnome-desktop-3 and -4, and ships four typelibs:
            # GnomeDesktop-4.0, which this gem binds; GnomeDesktop-3.0, the
            # GTK3 generation; and GnomeBG-4.0 / GnomeRR-4.0, which both
            # depend on Gdk-4.0 and so belong in gems of their own.
            gnome-desktop

            # For GDesktopEnums-3.0.typelib, GdkPixbuf-2.0.typelib and the
            # GSettings schemas. Nothing is compiled against any of these:
            # they are here for the typelibs and schemas the shellHook
            # exports, which is why pkg-config, clang and the Rust toolchain
            # are no longer in this shell.
            gsettings-desktop-schemas
            gdk-pixbuf

            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            export GI_TYPELIB_PATH="${typelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
            export GSETTINGS_SCHEMA_DIR="${schemaPath}''${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
          '';
        };
      }
    );
}
