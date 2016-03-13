# xcsim

xcsim is a command-line utility to simplify opening iOS Simulator application directories in Finder.
iOS Simulator uses UUIDs heavily for naming its directories, which makes them not really readable
by human eye. Consider for example:

    /Users/User/Library/Developer/CoreSimulator/Devices/FC138577-990F-4069-9AB1-6D847B8529BD/data/
    Containers/Data/Application/E34BF950-B343-4C73-B50F-EEEA0E34BFAC

Suppose you have an iOS application with bundle ID `com.yourcompany.appname` and want to peek
into its Documents folder, which is stored in iPhone 5s (iOS 9.2) simulator. Finding the right
directory could be a tedious task. With xcsim it is as easy as

    xcsim --os "iOS 9.2" --device "iPhone 5s" com.yourcompany.appname

or even as just

    xcsim com.yourcompany.appname

if it happens that default OS and device values are enough for your needs.

In case you're not sure which exact simulator your app is installed on, you can use xcsim to list
all present simulators by OS type, device name and view bundle IDs of the applications installed
on them.

By default xcsim invokes the `open` command to open the application data directory in Finder. By
providing the `--app` option you can open application bundle directory instead. Using `--echo`
option will print the full path to the selected directory instead of opening Finder.

Usage: `xcsim [options] [bundleID]`

    -l, --list [OS], [DEVICE]        List simulator OS, devices, app bundle IDs
    -o, --os 'TYPE VERSION'          Select simulator OS (default: 'iOS 9.2')
    -d, --device 'TYPE'              Select simulator device (default: 'iPhone 5s')
    -a, --app                        Select application container directory instead of data directory
    -e, --echo                       Echo the selected directory instead of opening it
    -h, --help [OPTION]              Print this message / help for individual options
