Gem::Specification.new do |s|
  s.name        = 'finvoice201'
  s.version     = '0.0.1'
  s.date        = '2016-02-25'
  s.summary     = "Finvoice 2.01"
  s.description = "Finvoice 2.01 xml generator"
  s.authors     = ["Antti Jäppinen"]
  s.email       = 'antti@devlab.fi'
  s.files       = ["lib/finvoice201.rb"]
  s.homepage    = 'https://github.com/devlab-oy/finvoice'
  s.license     = 'MIT'

  s.add_runtime_dependency 'nokogiri'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rest-client'
end
