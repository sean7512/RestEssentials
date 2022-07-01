Pod::Spec.new do |s|
  s.name = 'RestEssentials'
  s.version = '6.0.1'
  s.license = 'MIT'
  s.summary = 'RestEssentials is a lightweight REST and JSON library for Swift.'
  s.homepage = 'https://github.com/sean7512/RestEssentials'
  s.authors = 'sean7512'
  s.source = { :git => 'https://github.com/sean7512/RestEssentials.git', :tag => s.version }
  s.swift_versions = ['5.5', '5.6']

  s.platforms = { :ios => "15.0", :tvos => "15.0", :watchos => "8.0", :osx => "12.0" }

  s.source_files = 'Sources/RestEssentials/*.swift'

  s.requires_arc = true
end

