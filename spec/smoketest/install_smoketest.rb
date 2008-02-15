# This is a quick smoke test, using smoketest-geminstaller.yml and smoketest-geminstaller-override.yml.

# It verifies that geminstaller works as expected in a production-like environment, using 
# real gems against the real rubyforge.org.  For now, it purposely relies on visual inspection,
# rather than trying to capture and interpret stdout. 

# It's not part of the real test suite because I don't want to include dependencies on rubyforge or real gems
# in the test suite.  It's mostly to find bugs that I can then expose with targeted specs in the real suite

# It obviously requires that you have a network connection. It will uninstall some gems 
# and then reinstall them via geminstaller.  If you actually need one of these gems it will probably screw them
# up, forcing you to manually fix them.  If you don't want that to happen, don't run it

# Run this file as sudo if that is required in order for you to successfully install gems
# (or change the ownership/permissions of your gems installation to the current user)
dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/../helper/spec_utils")

module GemInstaller
  class SmokeTest
    include GemInstaller::SpecUtils::ClassMethods

    def run
      dir = File.dirname(__FILE__)
      # heckle -> hoe -> rubyforge show a three-level dependency
      test_gems = ['ruby-doom', 'rutils', 'x10-cm17a', 'heckle', 'hoe', 'rubyforge']
      expected_versions = {
        'ruby-doom' => ['0.8'],
        'rutils' => ['0.1.3','0.1.9'],
        'x10-cm17a' => ['1.0.1']
      }

      is_windows = RUBY_PLATFORM =~ /mswin/ ? true : false

      print "Here's the versions you currently have installed (if any), just in case this fails and you have to reinstall them manually:\n\n"
      IO.popen("#{gem_cmd} list #{test_gems.join(' ')}")

      use_sudo = false
      sudo = ''
      unless is_windows
        print "Enter your sudo password (if required),\n"
        sudo_init = IO.popen("sudo ruby --version")
        sudo_init.gets
        use_sudo = true
        sudo = "sudo"
      end
      test_gems.each do |gem|
        print "Uninstalling all versions of #{gem}.  This will give an error if it's not already installed.\n"
        IO.popen("#{sudo} #{gem_cmd} uninstall --all --ignore-dependencies --executables #{gem}") do |process| 
          process.readlines.each do |line| 
            print line
          end
        end
      end

      # verify gems are actually uninstalled before attempting to install them with GemInstaller
      test_gems.each do |gem|
        IO.popen("#{gem_cmd} list #{gem}") do |process| 
          process.readlines.each do |line|
            raise RuntimeError.new("FAILURE: Test setup failed, #{gem} should not still be installed.") if line.index(gem)
          end
        end
      end

      print "\n\n"
      path_to_app = File.expand_path("#{dir}/../../bin/geminstaller")
      sudo_flag = '--sudo' if use_sudo
      geminstaller_cmd = "#{ruby_cmd} -I #{dir}/../../lib #{path_to_app} #{sudo_flag} --config=#{File.join(dir,'smoketest-geminstaller.yml')},#{File.join(dir,'smoketest-geminstaller-override.yml')}"
      print "Running geminstaller: #{geminstaller_cmd}\n"
      print "This should print a message for each of the gems which are installed.\n"
      print "Please be patient, it may take a bit, or may not work at all if rubyforge or your network connection is down, or you don't have proper permissions, or if there's a bug in geminstaller :)\n\n"
      IO.popen(geminstaller_cmd) {|process| process.readlines.each {|line| print line}}
      print "\n\n"

      print "Geminstaller command complete.  Now we'll run gem list to check that the gems listed above were actually installed locally.\n"
      success = true
      missing_gems = ''
      test_gems.each do |gem|
        print "\nRunning gem list for #{gem}, verify that it contains the expected version(s)"
        gem_found = false
        all_list_output = ''
        IO.popen("#{gem_cmd} list #{gem}") do |process| 
          process.readlines.each do |line|
            print line
            all_list_output += " #{line}"
            gem_found = true if line.index(gem)
          end
        end
        unless gem_found
          success = false
          print "ERROR: #{gem} was not installed."
          missing_gems += "#{gem} "
        end
        if expected_versions[gem]
          expected_versions[gem].each do |version|
            unless all_list_output.index(version)
              success = false
              print "ERROR: Version #{version} was not installed for #{gem}"
              missing_gems += "#{gem} (#{version})"
            end
          end
        end
      end

      print "\n\n"
      if success
        print "SUCCESS! FANFARE! All gems were successfully installed!\n\n"
      else
        raise RuntimeError.new("\n\nFAILURE: The following gems were not installed: #{missing_gems}\n\n")
      end

      geminstaller_cmd = "ruby #{path_to_app} #{sudo_flag} --silent --config=#{File.join(dir,'smoketest-geminstaller-reinstall.yml')}"
      print "Now (re)installing the latest version of the test gems, in a minimal attempt not to leave your system in a screwed-up state if you already had them installed.\n"
      print "Running geminstaller: #{geminstaller_cmd}\n"
      IO.popen(geminstaller_cmd) {|process| process.readlines.each {|line| print line}}
      print "\n\n"
      return success
    end
  end
end

require 'test/unit'

module GemInstaller
  class InstallSmokeTest < Test::Unit::TestCase
    def test_install
      assert(GemInstaller::SmokeTest.new.run, "FAILURE, install smoketest failed.") 
    end
  end
end