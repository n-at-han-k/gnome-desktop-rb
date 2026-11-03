# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "lib/gnome_desktop/version"

Gem::Specification.new do |spec|
  spec.name = "gnome_desktop"
  spec.version = GnomeDesktop::VERSION
  spec.authors = ["Nathan Kidd"]
  spec.email = ["nathankidd@hey.com"]
  spec.license = "Apache-2.0"

  spec.summary = "Ruby bindings for the GNOME Utility Library: thumbnails, idle monitoring and desktop metadata."
  spec.description = "The GNOME Utility Library: thumbnails, idle monitoring and desktop metadata, for Ruby. Defined from its GObject "\
    "Introspection typelib at require time rather than wrapped by hand, so the "\
    "binding is the whole library and does not drift as it gains API."
  spec.homepage = "https://github.com/n-at-han-k/gnome-desktop-rb"

  spec.required_ruby_version = ">= 3.3"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://n-at-han-k.github.io/gnome-desktop-rb/"

  # LICENSE and NOTICE ship because the Apache License asks for both: section
  # 4(a) wants every recipient given a copy of the licence, and 4(d) wants the
  # attribution notices carried along with it.
  spec.files = Dir.glob(
    ["{lib}/**/*", "LICENSE", "NOTICE", "README.md", "CHANGELOG.md"],
    File::FNM_DOTMATCH,
    base: __dir__,
  )

  spec.require_paths = ["lib"]

  # GemKit::Deprecate declares a deprecation as a dated promise: the replacement, and the version the old name stops existing in.
  spec.add_dependency "gem_kit", "~> 0.2"

  # The loader. This is the whole binding: GObjectIntrospection::Loader reads
  # the typelib and defines the GnomeDesktop namespace from it. glib2 comes along as
  # its dependency and is what GLib::Log and the GObject base classes are.
  #
  # Note this does mean installing compiles C: glib2 and gobject-introspection
  # are native extensions built against glib, so a compiler and glib headers
  # are needed. This gem adds no build step of its own, and those two are what
  # every ruby-gnome application already has, since gtk4 depends on them.
  #
  # The C library itself is NOT a gem dependency and cannot be: its typelib
  # belongs to the distribution. See the README.
  spec.add_dependency "gobject-introspection", "~> 4.3"
  spec.add_development_dependency "lefthook", "~> 2.2"
end
