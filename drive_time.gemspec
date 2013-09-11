# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drive_time/version'

Gem::Specification.new do |gem|
  gem.name          = "drive_time"
  gem.version       = DriveTime::VERSION
  gem.authors       = ["Pedr Browne"]
  gem.email         = ["pedr.browne@gmail.com"]
  gem.description   = %q{Convert Google Spreadsheets to Rails Models}
  gem.summary       = %q{Map Worksheets to Models and their columns to model attributes. Seed your database directly from Google Drive.}
  gem.homepage      = "https://github.com/stationkeeping/drive_time"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "log4r", "~> 1.1"
  gem.add_dependency "deep_end", "~> 0.0"
  gem.add_dependency "google_drive", "~> 0.3"

  gem.add_development_dependency "rake", '~> 10.1'
  gem.add_development_dependency "rspec", '~> 2.14'
  gem.add_development_dependency "dotenv", "~> 0.9"
  gem.add_development_dependency "activemodel", "3.2.13"
  gem.add_development_dependency "activerecord", "3.2.13"
  gem.add_development_dependency "activesupport", "3.2.13"
end
