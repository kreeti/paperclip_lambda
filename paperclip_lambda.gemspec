$LOAD_PATH.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'paperclip_lambda'
  s.version     = '0.0.0'
  s.date        = '2016-06-03'
  s.summary     = "Paperclip Lambda"
  s.add_runtime_dependency "aws-sdk"
  s.description = "Process your uploaded image through aws lambda"
  s.authors     = ["Santanu Bhattacharya"]
  s.email       = 'sbhattacharya@kreeti.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'http://rubygems.org/gems/paperclip_lambda'
  s.license     = 'MIT'
end
