require 'pty'

# Execute a shell command while continously printing the output to the shell
# from which `rake` has been started.
#
# Implementation from http://stackoverflow.com/a/1162850/892696
def execute(cmd)
  puts "> #{cmd}"
  PTY.spawn(cmd) do |stdout, stdin, pid|
    begin
      stdout.each { |line| print line }
    rescue Errno::EIO
    end
  end
end

task :clean do
  execute("rm *.gem")
end

task :build do
  execute("gem build xcsim.gemspec")
end

task :install => [:clean, :build] do
  execute("gem install `ls *.gem`")
end

task :publish => [:clean, :build] do
  execute("gem push `ls *.gem`")
end

