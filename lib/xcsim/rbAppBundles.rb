# -*- coding: utf-8 -*-

require 'cfpropertylist'
require_relative 'rbBundleInfo'

module XCSim

  # An error raised by XCSim::findBundleDataPath function when multiple directories matching
  # the given bundle ID are found on the same simulator device.
  class NonUniqueBundleIDError < RuntimeError

    # A DeviceID object representing the iOS Simulator on which the error has occurred
    attr_reader :deviceID

    # A bundle ID string, which caused the error
    attr_reader :bundleID

    # An array of strings containing absolute paths for directories matching the given bundle ID
    attr_reader :directories

    # Initializes a NonUniqueBundleIDError object with the given parameters
    def initialize(deviceID, bundleID, directories)
      @bundleID = bundleID
      @deviceID = deviceID
      @directories = directories
    end
  end



  # call-seq:
  #    findBundleDataPath(deviceID, bundleID) => String
  #
  # +deviceID+:: A DeviceID object representing the device simulator on which the application
  #              is installed
  # +bundleID+:: Bundle ID of the application to search for
  #
  # Finds an absolute path for application data directory of an application with a given bundle ID
  # installed on a given device.
  #
  # Searches for directories matching +bundleID+ inside the application data directory of the
  # device. Raises a NonUniqueBundleIDError if multiple matching directories
  # are found (bundle IDs are expected to be unique). Returns the found directory or +nil+
  # otherwise.
  def self.findBundleDataPath(deviceID, bundleID)
    path = deviceID.appDataPath
    subdirs = Dir.entries(path).select do |entry|
      File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end

    metadataPairs = subdirs.map do |dir|
      metadataPath = "#{path}/#{dir}/#{BUNDLE_METADATA_PLIST}"

      if File.exists? metadataPath
        plist = CFPropertyList::List.new(:file => metadataPath)
        plist = CFPropertyList.native_types(plist.value)

        { :plist => plist, :dir => "#{path}/#{dir}" }
      else
        nil
      end
    end
    .select{ |pair| pair != nil }

    result = metadataPairs.select{ |pair| pair[:plist][METADATA_ID] == bundleID }

    if result.count > 1
      raise NonUniqueBundleIDError.new(deviceID, bundleID, result.map{|pair| pair[:dir]})
    elsif result.empty?
      return nil
    else
      result.first[:dir]
    end
  end



  # call-seq:
  #    parseInstalledBundles(deviceID) => Hash
  #
  # +deviceID+:: A DeviceID object to search installed app bundles for
  #
  # Searches the given iOS Simulator device for installed application bundles (excluding the
  # system applications such as Safari) and returns a Hash of <tt>bundle ID string =>
  # BundleInfo</tt> containing BundleInfo instances corresponding the found bundles.
  #
  # May raise a NonUniqueBundleIDError if multiple data directories are found for one
  # of the bundles.
  def self.parseInstalledBundles(deviceID)
    path = deviceID.appBundlesPath
    subdirs = Dir.entries(path).select do |entry|
      File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end

    bundlePlists = subdirs.map do |dir|
      plistPath = "#{path}/#{dir}/#{BUNDLE_METADATA_PLIST}"

      if File.exists? plistPath
        plist = CFPropertyList::List.new(:file => plistPath)
        plist = CFPropertyList.native_types(plist.value)

        { :plist => plist, :dir => "#{path}/#{dir}" }
      else
        nil
      end
    end
    .select { |plist| plist != nil }

    bundleInfos = bundlePlists.map do |pair|
      bundleID = pair[:plist][METADATA_ID]
      bundlePath = pair[:dir]
      dataPath = findBundleDataPath(deviceID, bundleID)
      BundleInfo.new(bundleID, bundlePath, dataPath)
    end

    bundleInfosHash = {}
    bundleInfos.each{ |info| bundleInfosHash[info.bundleID] = info }

    bundleInfosHash
  end

end # module XCSim

# eof