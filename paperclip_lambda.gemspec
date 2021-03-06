$LOAD_PATH.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'paperclip_lambda'
  s.version     = '0.0.3'
  s.summary     = "Paperclip Lambda"
  s.add_runtime_dependency "aws-sdk", ["~> 2"]
  s.add_runtime_dependency "paperclip", ["5.0.0.beta2"]
  s.description = "Process your uploaded images through aws lambda"
  s.authors     = ["Santanu Bhattacharya"]
  s.email       = 'eng@kreeti.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'http://rubygems.org/gems/paperclip_lambda'
  s.license     = 'MIT'
end
