Gem::Specification.new do |s|
  s.name        = 'make_index'
  s.version     = '0.1.0'
  s.date        = '2015-09-12'
  s.summary     = "Use to add an index of terms to an Asciidoc file!"
  s.description = "See ..."
  s.authors     = ["James Carlson"]
  s.email       = 'jxxcarlson@mac.com'
  # s.files       = ["lib/make_index/text_index.rb", "lib/make_index.rb"]
  s.homepage    =
    'http://rubygems.org/gems/make_index'
  s.license       = 'MIT'

  begin
    s.files       = `git ls-files -z -- */* {CHANGELOG,LICENSE,manual,Rakefile,README}*`.split "\0"
  rescue
    s.files       = Dir['**/*']
  end
  s.executables   = s.files.grep(/^bin\//) { |f| File.basename(f) }
  # s.test_files    = s.files.grep(/^(test|spec|features)\//)
  s.require_paths = ['lib']

end
