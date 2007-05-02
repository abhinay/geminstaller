dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/geminstaller/requires.rb")

module GemInstaller
  def self.run(args = [])
    app = create_application(args)
    app.run
  end 
  
  def self.autogem(config_paths=nil)
    config_paths_string = parse_config_paths(config_paths)
    args = []
    args = ["--config=#{config_paths_string}"] if config_paths_string
    app = create_application(args)
    app.autogem
  end

  def self.version
    "0.0.1"
  end

  def self.create_application(args = [], registry = nil)
    registry ||= create_registry
    app = registry.app
    app.args = args
    app
  end
  
  def self.create_registry
    dependency_injector = GemInstaller::DependencyInjector.new
    dependency_injector.registry
  end
  
  def self.parse_config_paths(config_paths)
    return nil unless config_paths
    return config_paths unless config_paths.respond_to? :join
    return config_paths.join(',')
  end
  
  def self.run_from_app(args = "", use_sudo = true, abort_on_error = true)
    if RUBY_PLATFORM =~ /mswin/ or !use_sudo
      # GemInstaller can be invoked from Ruby if you DON'T require root access to install gems
      begin
        args_array = args.split(' ')
        GemInstaller.run(args_array)
      rescue Exception => e
        # Abort App startup if GemInstaller failed (optional)
        raise e if abort_on_error
      end
    else
      # GemInstaller must be invoked via the executable if you DO require root access to install gems
      command = "geminstaller --sudo #{args}"
      result = system(command)
      # Abort App startup if GemInstaller failed (optional)
      if abort_on_error
        raise "GemInstaller failed, return code = #{$?}, command = #{command}" unless result and $? == 0
      end
    end
  end
end