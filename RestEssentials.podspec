Pod::Spec.new do |s|
  s.name = 'RestEssentials'
  s.version = '5.0.0'
  s.license = 'MIT'
  s.summary = 'RestEssentials is a lightweight REST and JSON library for Swift.'
  s.homepage = 'https://github.com/sean7512/RestEssentials'
  s.authors = 'sean7512'
  s.source = { :git => 'https://github.com/sean7512/RestEssentials.git', :tag => s.version }
  s.swift_version = '5.0'

  s.platforms = { :ios => "8.0", :tvos => "9.0", :watchos => "2.0" }

  s.source_files = 'Sources/RestEssentials/*.swift'

  s.requires_arc = true
end
