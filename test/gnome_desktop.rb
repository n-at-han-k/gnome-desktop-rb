# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "gnome_desktop"

describe GnomeDesktop do
  it "defines the namespace from the typelib" do
    # GnomeDesktop-4.0 is a small namespace -- five classes, one enumeration,
    # their private records and a constant -- so this number is low on purpose
    # and is not a stand-in for "lots of API". What it catches is a loader that
    # silently half-ran: a GnomeDesktop with only the four names this gem
    # defines itself (LOG_DOMAIN, VERSION, Loader, Error) would still be a
    # module that requires cleanly.
    expect(GnomeDesktop.constants.size).to be > 10
  end

  it "defines the classes a caller actually reaches for" do
    expect(GnomeDesktop.const_defined?(:XkbInfo)).to be == true
    expect(GnomeDesktop.const_defined?(:PnpIds)).to be == true
    expect(GnomeDesktop.const_defined?(:WallClock)).to be == true
    expect(GnomeDesktop.const_defined?(:IdleMonitor)).to be == true
    expect(GnomeDesktop.const_defined?(:DesktopThumbnailFactory)).to be == true
  end

  it "maps GObject methods onto the class, not just constants" do
    # The assertion that catches a half-loaded namespace. A loader that
    # registered the types but defined no methods would satisfy every
    # assertion above, so this one subtracts GLib::Object's own methods and
    # insists that what is left came from the typelib: all_layouts,
    # get_layout_info, get_layouts_for_country and the rest.
    own = GnomeDesktop::XkbInfo.instance_methods - GLib::Object.instance_methods

    expect(own.size).to be > 8
    expect(own).to be(:include?, :all_layouts)
    expect(own).to be(:include?, :get_layout_info)
  end

  it "defines the namespace's module functions" do
    expect(GnomeDesktop.respond_to?(:parse_locale)).to be == true
    expect(GnomeDesktop.respond_to?(:normalize_locale)).to be == true
    expect(GnomeDesktop.respond_to?(:all_locales)).to be == true
    expect(GnomeDesktop.respond_to?(:language_has_translations)).to be == true
  end

  # Locale parsing is the one part of this library that consults nothing: it
  # takes a locale name apart by its own grammar, so the answer is the same on
  # a developer's desktop and in an empty container. These are therefore the
  # only exact values in this file worth pinning.
  describe "locale parsing" do
    it "takes a locale name apart" do
      # The GI signature returns the gboolean alongside the four out
      # parameters, so the tuple is [ok, language, country, codeset, modifier].
      ok, language, country, codeset, modifier = GnomeDesktop.parse_locale("en_GB.UTF-8@euro")

      expect(ok).to be == true
      expect(language).to be == "en"
      expect(country).to be == "GB"
      expect(codeset).to be == "UTF-8"
      expect(modifier).to be == "euro"
    end

    it "leaves the parts a bare language name does not have as nil" do
      ok, language, country, codeset, modifier = GnomeDesktop.parse_locale("en")

      expect(ok).to be == true
      expect(language).to be == "en"
      expect(country).to be_nil
      expect(codeset).to be_nil
      expect(modifier).to be_nil
    end

    it "reports failure rather than raising for something that is not a locale name" do
      ok, = GnomeDesktop.parse_locale("")

      expect(ok).to be == false
    end

    it "leaves an already-canonical name alone" do
      expect(GnomeDesktop.normalize_locale("en_US.UTF-8")).to be == "en_US.UTF-8"
    end

    # The name database lives in iso-codes and the system locale archive, and a
    # container has neither. An unknown code is NULL from the C function
    # either way, so what is assertable is the shape.
    it "answers a language code with a string or nil" do
      name = GnomeDesktop.get_language_from_code("en", nil)

      expect(name.nil? || name.is_a?(String)).to be == true
    end

    it "returns nil for a language code that cannot exist" do
      expect(GnomeDesktop.get_language_from_code("zzzz", nil)).to be_nil
    end

    it "lists the installed locales, however few there are" do
      expect(GnomeDesktop.all_locales).to be_a(Array)
    end
  end

  # These three construct without a display, a session bus or a main loop,
  # which is what makes them assertable here at all. IdleMonitor is
  # deliberately not instantiated: it reaches Mutter over D-Bus and reports
  # idleness through signals, so there is nothing for it to answer in a test
  # process.
  describe GnomeDesktop::XkbInfo do
    # XkbInfo's constructor builds a GSettings for
    # org.gnome.desktop.input-sources. A GSettings for a schema that is not
    # installed is a g_error, which aborts the process rather than raising, so
    # this test failing as a crash means GSETTINGS_SCHEMA_DIR is wrong -- see
    # flake.nix.
    it "constructs without a display or a session" do
      expect(GnomeDesktop::XkbInfo.new).to be_a(GnomeDesktop::XkbInfo)
    end

    # The registry comes from xkeyboard-config on the host, so the count is not
    # assertable; the shape is.
    it "lists layouts" do
      expect(GnomeDesktop::XkbInfo.new.all_layouts).to be_a(Array)
    end

    it "reports failure rather than raising for a layout id that cannot exist" do
      ok, = GnomeDesktop::XkbInfo.new.get_layout_info("not-a-layout-id")

      expect(ok).to be == false
    end

    it "returns a list, not nil, for a country code that cannot exist" do
      expect(GnomeDesktop::XkbInfo.new.get_layouts_for_country("ZZ")).to be_a(Array)
    end
  end

  describe GnomeDesktop::PnpIds do
    it "constructs and answers a vendor code with a string or nil" do
      vendor = GnomeDesktop::PnpIds.new.get_pnp_id("ZZZZ")

      expect(vendor.nil? || vendor.is_a?(String)).to be == true
    end
  end

  describe GnomeDesktop::WallClock do
    # The clock string is computed from the current time, not delivered by a
    # main loop, so the initial value is readable straight away. The property
    # is what a caller binds to a label.
    it "has a clock string before anything runs a main loop" do
      expect(GnomeDesktop::WallClock.new.clock).to be_a(String)
    end
  end

  describe GnomeDesktop::DesktopThumbnailSize do
    # The four sizes the freedesktop thumbnail spec names. Worth pinning
    # because the enumeration carries no GType -- `GnomeDesktopThumbnailSize`
    # is a plain C enum -- so GI cannot marshal it as an argument and
    # `DesktopThumbnailFactory.new` is unreachable through the typelib. The
    # constants are what the namespace does give you.
    it "names the four thumbnail sizes" do
      expect(GnomeDesktop::DesktopThumbnailSize.constants.sort)
        .to be == [:LARGE, :NORMAL, :XLARGE, :XXLARGE]
    end
  end
end
