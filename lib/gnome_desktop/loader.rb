# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module GnomeDesktop
  # Defines everything in the GnomeDesktop namespace from `GnomeDesktop-4.0.typelib`.
  #
  # Modelled on ruby-gnome's own loaders -- see
  # gtksourceview5/lib/gtksourceview5/loader.rb for one that has to call the
  # library's init function first, and libsecret/lib/libsecret/loader.rb for
  # one that does not.
  #
  # The version string is the typelib's rather than the library's release
  # number, and the two often differ: this one is "4.0", from
  # `GnomeDesktop-4.0.typelib`.
  class Loader < GObjectIntrospection::Loader
    def load
      self.version = "4.0"
      super("GnomeDesktop")
    end

    private

    def post_load(repository, namespace)
      require_libraries
    end

    def require_libraries
      # Nothing yet. Hand-written Ruby that improves on what the typelib gives
      # -- an each that yields, a to_s, a keyword-argument constructor -- goes
      # in files required from here, which is the convention ruby-gnome uses
      # for exactly that purpose.
    end
  end
end
