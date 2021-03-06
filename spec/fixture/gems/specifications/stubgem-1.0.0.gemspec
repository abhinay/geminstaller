Gem::Specification.new do |s|
  s.name = %q{stubgem}
  s.version = "1.0.0"
  s.date = %q{2006-11-25}
  s.summary = %q{Stub gem for testing geminstaller}
  s.email = %q{stubgem@geminstaller.rubyforge.org}
  s.homepage = %q{http://geminstaller.rubyforge.org}
  s.rubyforge_project = %q{stubgem}
  s.description = %q{== FEATURES/PROBLEMS:  * This stub gem is embedded in the geminstaller project to allow testing without manually starting a local gem server.   == SYNOPSYS:  Allows geminstaller tests to install/uninstall gems without running a local gem server or depending on real gems..  == REQUIREMENTS:}
  s.has_rdoc = true
  s.authors = ["Chad Woolley"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/stubgem.rb", "test/test_stubgem.rb"]
end
