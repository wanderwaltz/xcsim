# -*- coding: utf-8 -*-

module XCSim

  # OSID is used to uniquely identify an iOS Simulator operating system
  # (including watchOS and tvOS operating systems) and is basically
  # a pair of OS type string ('iOS', 'watchOS', 'tvOS') and version string
  # ('9.0', '9.1' etc.)
  class OSID
    # Simulated OS type string ('iOS', 'watchOS', 'tvOS')
    attr_reader :type

    # Simulated OS version string ('7.0', '8.0', '9.0' etc.)
    attr_reader :version

    # Creates an OSID instance from a string prefixed by a standard
    # prefix encountered in +device_set.plist+ (+com.apple.CoreSimulator.SimRuntime.+)
    #
    # Does not perform any additional validation other than checking the prefix.
    def self.fromPrefixedString(string)
      unless string.start_with? @@PREFIX
        return nil
      end

      components = string.sub(@@PREFIX, "").split("-")
      type = components.first
      version = components[1..-1].join(".")

      return OSID.new(type, version)
    end

    # Creates an OSID instance from a non-prefixed string. Assumes 'iOS 9.2' format
    # where components are separated by whitespace and the first component represents
    # OS type while all others are concatenated and assumed to represent OS version.
    def self.fromString(string)
      components = string.split(" ")
      type = components.first
      version = components[1..-1].join(".")

      return OSID.new(type, version)
    end

    # Creates an OSID instance with a given type and version.
    def initialize(type, version)
      @type = type
      @version = version
      @parsed_version = Gem::Version.new(version)
    end

    # Returns a string in <tt>'iOS 9.2'</tt> format
    def inspect
      "#{@type} #{@version}"
    end

    # Same as #inspect
    def to_s
      inspect
    end

    # Returns a string used for indexing OS definitions in +device_set.plist+
    # in +com.apple.CoreSimulator.SimRuntime.iOS-7-1+ format.
    def key
      "#{@@PREFIX}#{@type}-#{@version.gsub(".","-")}"
    end

    include Comparable

    # Uses version for comparison (allows using <tt>Array#max</tt> on arrays of OSID
    # for selecting max version)
    def <=>(other)
      @parsed_version <=> other.parsed_version
    end

    # Returns +inspect.hash+
    def hash
      inspect.hash
    end

    # Checks attribute-wise equality (compares @type and @version)
    def eql?(other)
      @type.eql?(other.type) && @version.eql?(other.version)
    end

    protected
    attr_reader :parsed_version

    private
    @@PREFIX = "com.apple.CoreSimulator.SimRuntime."
  end # class OSID

end # module XCSim

# eof