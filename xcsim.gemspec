Gem::Specification.new do |s|
  s.name        = 'xcsim'
  s.version     = '1.0.1'
  s.date        = '2016-03-13'
  s.summary     = "Open iOS Simulator application/data directories by bundle ID"
  s.description = <<-EOD
xcsim is a command-line utility to simplify opening iOS Simulator application/data directories. It's as simple as running `xcsim com.yourcompany.application`.
EOD
  s.authors     = ["Egor Chiglintsev"]
  s.email       = 'egor.chiglintsev@gmail.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.executables << 'xcsim'
  s.homepage    = 'https://github.com/wanderwaltz/xcsim'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2.0'

  s.add_runtime_dependency 'CFPropertyList', '~> 2.2'
end
