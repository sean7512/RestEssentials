Pod::Spec.new do |s|
  s.name = 'RestEssentials'
  s.version = '5.2.0'
  s.license = 'MIT'
  s.summary = 'RestEssentials is a lightweight REST and JSON library for Swift.'
  s.homepage = 'https://github.com/sean7512/RestEssentials'
  s.authors = 'sean7512'
  s.source = { :git => 'https://github.com/sean7512/RestEssentials.git', :tag => s.version }
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3']

  s.platforms = { :ios => "11.0", :tvos => "11.0", :watchos => "4.0", :osx => "10.13" }

  s.source_files = 'Sources/RestEssentials/*.swift'

  s.requires_arc = true
end

