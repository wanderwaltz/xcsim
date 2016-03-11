#!/usr/bin/ruby

require 'fileutils'
require 'optparse'
require 'cfpropertylist'



#---------------------------------------------------------------------------------------------------
# Constants
#---------------------------------------------------------------------------------------------------
SIMULATORS_ROOT = File.expand_path("~/Library/Developer/CoreSimulator/Devices")
DEVICE_APP_BUNDLES_RELATIVE_PATH = "data/Containers/Bundle/Application"
DEVICE_APP_DATA_RELATIVE_PATH = "data/Containers/Data/Application"

DEVICE_SET_PLIST = "device_set.plist"
BUNDLE_METADATA_PLIST = ".com.apple.mobile_container_manager.metadata.plist"

METADATA_ID = "MCMMetadataIdentifier"
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# OSID
#
# OSID is a pair of OS type (iOS, watchOS, tvOS) and version
#---------------------------------------------------------------------------------------------------
class OSID
    attr_reader :type, :version
    @@PREFIX = "com.apple.CoreSimulator.SimRuntime."

    def self.fromPrefixedString(string)
        unless string.start_with? @@PREFIX
            return nil
        end

        components = string.sub(@@PREFIX, "").split("-")
        type = components.first
        version = components[1..-1].join(".")

        return OSID.new(type, version)
    end

    def self.fromString(string)
        components = string.split(" ")
        type = components.first
        version = components[1..-1].join(".")

        return OSID.new(type, version)
    end

    def initialize(type, version)
        @type = type
        @version = version
    end

    def inspect
        "#{@type} #{@version}"
    end

    def to_s
        inspect
    end

    def key
        "#{@@PREFIX}#{@type}-#{@version.gsub(".","-")}"
    end

    include Comparable
    def <=>(other)
        @version <=> other.version
    end

    def hash
        inspect.hash
    end

    def eql?(other)
        inspect.eql?(other.inspect)
    end
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# OSDevices
#---------------------------------------------------------------------------------------------------
class OSDevices
    attr_reader :id, :devices

    def initialize(id, devices)
        @id = id

        devicesHash = {}
        devices.each do |d|
            devicesHash[d.name] = d
        end

        @devices = devicesHash
    end

    def inspect
        "#{@id.inspect} (#{@devices.count} devices)"
    end

    def to_s
        inspect
    end

    include Comparable
    def <=>(other)
        @id <=> other.id
    end
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# DeviceID
#---------------------------------------------------------------------------------------------------
class DeviceID
    attr_reader :name, :guid
    @@PREFIX = "com.apple.CoreSimulator.SimDeviceType."

    def self.fromPrefixedString(string, guid)
        unless string.start_with? @@PREFIX
            return nil
        end

        name = string.sub(@@PREFIX, "").gsub("-", " ")
        return DeviceID.new(name, guid)
    end

    def initialize(name, guid)
        @name = name
        @guid = guid
    end

    def appBundlesPath
        "#{SIMULATORS_ROOT}/#{@guid}/#{DEVICE_APP_BUNDLES_RELATIVE_PATH}"
    end

    def appDataPath
        "#{SIMULATORS_ROOT}/#{@guid}/#{DEVICE_APP_DATA_RELATIVE_PATH}"
    end

    def inspect
        @name
    end

    def to_s
        inspect
    end

    def key
        "#{@@PREFIX}#{@name.gsub(" ","-")}"
    end

    def hash
        inspect.hash
    end

    def eql?(other)
        inspect.eql?(other.inspect)
    end
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# Bundle Info
#---------------------------------------------------------------------------------------------------
class BundleInfo
    attr_reader :bundleID, :bundlePath, :dataPath

    def initialize(bundleID, bundlePath, dataPath)
        @bundleID = bundleID
        @bundlePath = bundlePath
        @dataPath = dataPath
    end

    def inspect
        @bundleID
    end

    def to_s
        inspect
    end
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# device_set.plist parser
#---------------------------------------------------------------------------------------------------
def parseDeviceSet(path)
    plist = CFPropertyList::List.new(:file => path)
    plist = CFPropertyList.native_types(plist.value)
    defaultDevices = plist["DefaultDevices"]

    osIDs = defaultDevices
        .keys
        .map{|s| OSID.fromPrefixedString(s) }
        .select{|id| id != nil}

    oses = osIDs.map do |id|
        osDevices = defaultDevices[id.key]
        devices = osDevices
            .keys
            .map{ |s| DeviceID.fromPrefixedString(s, osDevices[s])}
            .select{ |device| device != nil }
            .select{ |device| File.directory? device.appBundlesPath }

        (devices.count > 0) ? OSDevices.new(id, devices) : nil
    end
    .select{ |os| os != nil }

    osHash = {}

    oses.each do |os|
        osHash[os.id] = os
    end

    osHash
end

devicesByOS = parseDeviceSet("#{SIMULATORS_ROOT}/#{DEVICE_SET_PLIST}")
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# simulator apps list parser
#---------------------------------------------------------------------------------------------------
def findBundleDataPath(deviceID, bundleID)
    path = deviceID.appDataPath
    subdirs = Dir.entries(path).select do |entry|
        File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end

    metadataPairs = subdirs.map do |dir|
        plist = CFPropertyList::List.new(:file => "#{path}/#{dir}/#{BUNDLE_METADATA_PLIST}")
        plist = CFPropertyList.native_types(plist.value)

        { :plist => plist, :dir => "#{path}/#{dir}" }
    end

    result = metadataPairs.select { |pair| pair[:plist][METADATA_ID] == bundleID }

    if result.count > 1
        puts "Multiple data directories matching bundle ID '#{bundleID}' " +
             "found: #{result.map{|pair| pair[:dir]}}"
        exit 1
    end

    result.first[:dir]
end

def parseInstalledBundles(deviceID)
    path = deviceID.appBundlesPath
    subdirs = Dir.entries(path).select do |entry|
        File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end

    bundlePlists = subdirs.map do |dir|
        plist = CFPropertyList::List.new(:file => "#{path}/#{dir}/#{BUNDLE_METADATA_PLIST}")
        plist = CFPropertyList.native_types(plist.value)

        { :plist => plist, :dir => "#{path}/#{dir}" }
    end

    bundleInfos = bundlePlists.map do |pair|
        bundleID = pair[:plist][METADATA_ID]
        bundlePath = pair[:dir]
        dataPath = findBundleDataPath(deviceID, bundleID)
        BundleInfo.new(bundleID, bundlePath, dataPath)
    end

    bundleInfosHash = {}

    bundleInfos.each do |info|
        bundleInfosHash[info.bundleID] = info
    end

    bundleInfosHash
end
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# options parser
#---------------------------------------------------------------------------------------------------
options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: xcsim [options]"

  opts.on("-h", "--help", "Print this message") do
    puts opts
    exit
  end

  opts.on("--list-os", "List available simulator OS") do |v|
    options[:list_oses] = v
  end

  opts.on("--list-devices", "List available simulator devices for the selected OS") do |v|
    options[:list_devices] = v
  end

  opts.on("--default-os", "Display default simulator OS") do |v|
    options[:print_default_os] = v
  end

  opts.on("-o", "--os 'TYPE VERSION'", "Specify OS to work with (default: the newest)") do |v|
    options[:os] = v
  end

  opts.on("-d", "--device 'TYPE'", "Select a simulator to work with (default: iPhone 5s)") do |v|
    options[:device] = v
  end

  opts.on("-b", "--bundle-id ID", "Select an app to work with") do |v|
    options[:bundle] = v
  end

  opts.on("--data", "print application data directory (default)") do |v|
    options[:data_dir] = v
  end

  opts.on("--bundle", "print bundle directory") do |v|
    options[:bundle_dir] = v
  end

  opts.on("--open", "open the selected directory in Finder") do |v|
    options[:open] = v
  end
end

parser.parse!
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# main
#---------------------------------------------------------------------------------------------------
if options[:list_oses]
    puts "Available simulator OS:"
    puts devicesByOS.keys.map { |id| " " + id.to_s }
    exit
end

if options[:print_default_os]
    puts devicesByOS.keys.max
    exit
end

osName = options[:os] || devicesByOS.keys.max.to_s
osID = OSID.fromString(osName)

osDevices = devicesByOS[osID]

if osDevices == nil
    puts "Unknown OS '#{osName}'"
    exit 1
end

deviceName = options[:device] || "iPhone 5s"
device = osDevices.devices[deviceName]

if device == nil || options[:list_devices]
    puts "Available simulators for #{osID}:"
    puts osDevices.devices.keys.map {|s| " " + s }
    exit
end

bundleID = options[:bundle]
bundleInfos = parseInstalledBundles(device)
bnulde = nil

if bundleID != nil
    matchingBundles = bundleInfos.values.select{ |bundle| bundle.bundleID.end_with? bundleID }

    if matchingBundles.count > 1
        puts "Multiple bundles matching ID '#{bundleID}' found: #{matchingBundles}!"
        exit 1
    elsif matchingBundles.count == 1
        bundle = matchingBundles.first
    end
end

if bundle == nil
    unless bundleID == nil
        puts "Unknown bundle ID '#{bundleID}'"
    end

    puts "Applications installed on #{device} #{osID} simulator:"
    puts bundleInfos.keys.map { |b| " " + b.to_s }
    exit 1
end

resultPath = bundle.dataPath

if options[:bundle_dir]
    resultPath = bundle.bundlePath
end

if options[:open]
    `open "#{resultPath}"`
    exit
end

puts resultPath
#---------------------------------------------------------------------------------------------------
