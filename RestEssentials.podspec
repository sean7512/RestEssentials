Pod::Spec.new do |s|
  s.name = 'RestEssentials'
  s.version = '0.1'
  s.license = 'MIT'
  s.summary = 'RestEssentials is an extremely lightweight REST and JSON library for Swift.'
  s.homepage = 'https://github.com/sean7512/RestEssentials'
  s.authors = 'sean7512'
  s.source = { :git => 'https://github.com/sean7512/RestEssentials.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Source/*.swift'

  s.requires_arc = true
end
