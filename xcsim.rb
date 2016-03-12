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
    devices.each{ |d| devicesHash[d.name] = d }

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
  oses.each{ |os| osHash[os.id] = os }

  osHash
end

@devicesByOS = parseDeviceSet("#{SIMULATORS_ROOT}/#{DEVICE_SET_PLIST}")
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

  result = metadataPairs.select{ |pair| pair[:plist][METADATA_ID] == bundleID }

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
  bundleInfos.each{ |info| bundleInfosHash[info.bundleID] = info }

  bundleInfosHash
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# helper funcrions
#---------------------------------------------------------------------------------------------------
@options = {}

def os_by_name(osName)
  osID = OSID.fromString(osName)

  osDevices = @devicesByOS[osID]

  if osDevices == nil
    puts "Unknown OS '#{osName}'"
    exit 1
  end

  return osDevices
end


def matching_oses(namePattern)
  if namePattern == nil
    return @devicesByOS.values
  end

  return @devicesByOS.values.select{ |os| os.id.to_s.include? namePattern }
end


def device_by_name(osDevices, deviceName)
  device = osDevices.devices[deviceName]

  if device == nil
    puts "Available simulators for #{osDevices.id}:"
    puts osDevices.devices.keys.map {|s| " " + s }
    exit 1
  end

  device
end


DEFAULT_OS_NAME = @devicesByOS.keys.max.to_s
DEFAULT_DEVICE_NAME = "iPhone 5s"

def selected_os_name
  @options[:selected_os_name] || DEFAULT_OS_NAME
end

def selected_device_name
  @options[:selected_device_name] || DEFAULT_DEVICE_NAME
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# options parser
#---------------------------------------------------------------------------------------------------
@parser = OptionParser.new do |opts|
  opts.banner = "Usage: xcsim [options] [bundleID]"

  opts.on_tail("-h", "--help", "Print this message") do
    puts opts
    exit
  end

  opts.on("-l", "--list [OS], [DEVICE]",
    "List simulator OS, devices, app bundle IDs") do |v|
      @options[:command] = :list
      @options[:argument] = v || :os_versions
  end

  opts.on("-o", "--os 'TYPE VERSION'",
    "Select simulator OS (default: '#{DEFAULT_OS_NAME}')") do |v|
      @options[:selected_os_name] = v
  end

  opts.on("-d", "--device 'TYPE'",
    "Select simulator device (default: '#{DEFAULT_DEVICE_NAME}')") do |v|
      @options[:selected_device_name] = v
  end

  opts.on("-a", "--app", "Select application container directory instead of data directory") do |v|
    @options[:argument] = :app_dir
  end

  opts.on("-e", "--echo", "Echo the selected directory instead of opening it") do |v|
    @options[:command] = :echo
  end
end

@parser.parse!
#---------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------
# commands
#---------------------------------------------------------------------------------------------------
def show_help
  puts @parser
  exit
end

def show_no_match(string)
  puts "Could not find simulators matching '#{string}'!\n"
  show_help
end

def list_os_versions
  puts @devicesByOS.values.map { |os| " " + os.to_s }
  exit
end

def list_matching(string)
  components = string.split(",").map{ |s| s.strip }

  case components.count
  when 2
    # assume first pattern is always for OS,
    # second - for device
    osPattern = components.first
    devicePattern = components.last

  when 1
    # we don't know whether the pattern is for OS or device,
    # try OS first
    osPattern = components.first
    devicePattern = nil
    matchingOSes = matching_oses(osPattern)

    # if no OSes match, assume the pattern is for device
    if matchingOSes.empty?
      osPattern = nil
      matchingOSes = nil
      devicePattern = components.first
    end

  else
    show_help

  end

  matchingOSes ||= matching_oses(osPattern)

  devicePairs = matchingOSes
    .map{ |os| os.devices.values.map{ |d| {:os => os, :device => d} } }
    .flatten

  # try finding a strict match first (disambiguate "iPad Air" from "iPad Air 2")
  matchingDevices = devicePairs
    .select{ |p| p[:device].name == devicePattern }

  # find partial matches otherwise
  if matchingDevices.empty?
    matchingDevices = devicePairs
      .select{ |p| p[:device].name.include? (devicePattern || "") }
  end

  if matchingDevices.count > 1
    unless devicePattern == nil
      if matchingOSes.count > 1
        puts matchingDevices.map{ |p| "#{p[:device]} (#{p[:os].id})" }
        exit
      else
        puts matchingDevices.map{ |p| p[:device] }
        exit
      end
    else
      puts matchingOSes
      exit
    end

  elsif matchingDevices.count == 1
    device = matchingDevices.first[:device]
    bundleInfos = parseInstalledBundles(device)

    unless bundleInfos.empty?
      puts bundleInfos.values
      exit
    else
      puts "Could not find bundles installed on #{device} (#{matchingDevices.first[:os].id})"
      exit 1
    end

  else
    show_no_match(string)
  end
end

def command_list
  # cannot mix --list with other options
  if @options.count > 2
    show_help
  end

  arg = @options[:argument]

  case arg
  when :os_versions
    list_os_versions

  else
    list_matching(([arg.to_s] + ARGV).join(" "))

  end
end
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
# main
#---------------------------------------------------------------------------------------------------
case @options[:command]
when :list
  command_list

end

if ARGV.empty? || ARGV.count > 1
  show_help
end

bundleID = ARGV.first
osDevices = os_by_name(selected_os_name)
device = device_by_name(osDevices, selected_device_name)

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

  puts "Applications installed on #{device} #{osDevices.id} simulator:"
  puts bundleInfos.keys.map { |b| " " + b.to_s }
  exit 1
end

resultPath = bundle.dataPath

if @options[:argument] == :app_dir
  resultPath = bundle.bundlePath
end

if @options[:command] == :echo
  puts resultPath
  exit
end

`open "#{resultPath}"`
exit
#---------------------------------------------------------------------------------------------------
