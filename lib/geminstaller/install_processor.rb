module GemInstaller
  class InstallProcessor
    attr_writer :gem_list_checker, :gem_command_manager, :gem_spec_manager, :missing_dependency_finder, :options, :output_filter
    def process(gems)
      gems.each do |gem|
        install_gem(gem)
      end
    end
    
    def install_gem(gem)
      already_specified = false
      if gem.check_for_upgrade
        @gem_list_checker.verify_and_specify_remote_gem!(gem)
        already_specified = true
      end
      gem_is_installed = @gem_spec_manager.is_gem_installed?(gem)
      if gem_is_installed 
        @output_filter.geminstaller_output(:debug,"Gem #{gem.name}, version #{gem.version} is already installed.\n")
      else
        @gem_list_checker.verify_and_specify_remote_gem!(gem) unless already_specified
        @output_filter.geminstaller_output(:install,"Invoking gem install for #{gem.name}, version #{gem.version}.\n")
        output_lines = @gem_command_manager.install_gem(gem)
        print_dependency_install_messages(gem, output_lines) unless @options[:silent]
      end
      if gem.fix_dependencies
        fix_dependencies(gem)
      end
    end
    
    def print_dependency_install_messages(gem, output_lines)
      output_lines.each do |line|
        line =~ /Successfully installed /
        match = $'
        next unless match
        next if match =~ /#{gem.name}-/
        @output_filter.geminstaller_output(:install,"Rubygems automatically installed dependency gem #{match}\n")
      end
    end

    def fix_dependencies(gem)
      missing_dependencies = @missing_dependency_finder.find(gem)
      while (missing_dependencies.size > 0)
        missing_dependencies.each do |missing_dependency|
          @output_filter.geminstaller_output(:install,"Installing #{missing_dependency.name} (#{missing_dependency.version})\n")
          # recursively call install_gem to install the missing dependency.  Since fix_dependencies
          # should never be set on an auto-created missing dependency gem, there is no risk of an 
          # endless loop or stack overflow.
          install_gem(missing_dependency)
        end
        # continue to look for and install missing dependencies until none are found
        missing_dependencies = @missing_dependency_finder.find(gem)
      end
    end
    
  end
end