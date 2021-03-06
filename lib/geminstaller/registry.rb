module GemInstaller
  class Registry
    attr_accessor :file_reader, :yaml_loader, :output_proxy, :config_builder, :gem_source_index, :gem_runner_proxy
    attr_accessor :gem_runner, :gem_command_manager, :gem_list_checker, :app, :arg_parser, :options
    attr_accessor :install_processor, :missing_dependency_finder, :valid_platform_selector
    attr_accessor :output_listener, :outs_output_observer, :errs_output_observer, :output_filter, :autogem, :rogue_gem_finder
    attr_accessor :gem_spec_manager, :source_index_search_adapter, :bundler_exporter
    
    if GemInstaller::RubyGemsVersionChecker.matches?('<=0.9.4')
      attr_accessor :gem_interaction_handler, :noninteractive_chooser
    end

    def initialize
      @options = {}
      @arg_parser = GemInstaller::ArgParser.new
      @arg_parser.options = @options
      
      @file_reader = GemInstaller::FileReader.new
      @yaml_loader = GemInstaller::YamlLoader.new
      @gem_arg_processor = GemInstaller::GemArgProcessor.new
      @version_specifier = GemInstaller::VersionSpecifier.new
      @output_proxy = GemInstaller::OutputProxy.new
      @output_proxy.options = @options
      @output_filter = GemInstaller::OutputFilter.new
      @output_filter.options = @options
      @output_filter.output_proxy = @output_proxy
      

      @output_listener = GemInstaller::OutputListener.new
      @output_listener.output_filter = @output_filter

      @valid_platform_selector = GemInstaller::ValidPlatformSelector.new
      @valid_platform_selector.output_filter = @output_filter
      @valid_platform_selector.options = @options

      @config_builder = GemInstaller::ConfigBuilder.new
      @config_builder.file_reader = @file_reader
      @config_builder.yaml_loader = @yaml_loader
      @config_builder.output_filter = @output_filter
      
      @bundler_exporter = GemInstaller::BundlerExporter.new
      @bundler_exporter.output_proxy = @output_proxy

      @gem_source_index = Gem::SourceIndex.from_installed_gems
      @gem_source_index_proxy = GemInstaller::GemSourceIndexProxy.new
      @gem_source_index_proxy.gem_source_index = @gem_source_index

      @source_index_search_adapter = GemInstaller::SourceIndexSearchAdapter.new
      @source_index_search_adapter.gem_source_index_proxy = @gem_source_index_proxy

      @outs_output_observer = GemInstaller::OutputObserver.new
      @outs_output_observer.stream = :stdout
      @outs_output_observer.register(@output_listener)
      @errs_output_observer = GemInstaller::OutputObserver.new
      @errs_output_observer.stream = :stderr
      @errs_output_observer.register(@output_listener)
      
      @enhanced_stream_ui = GemInstaller::EnhancedStreamUI.new
      @enhanced_stream_ui.outs = @outs_output_observer
      @enhanced_stream_ui.errs = @errs_output_observer

      @gem_runner_class = Gem::GemRunner
      @gem_cmd_manager_class = Gem::CommandManager
      @exact_match_list_command = GemInstaller::ExactMatchListCommand.new
      @gem_runner_proxy = GemInstaller::GemRunnerProxy.new
      @gem_runner_proxy.gem_runner_class = @gem_runner_class
      @gem_runner_proxy.gem_cmd_manager_class = @gem_cmd_manager_class
      @gem_runner_proxy.output_listener = @output_listener
      @gem_runner_proxy.enhanced_stream_ui = @enhanced_stream_ui
      @gem_runner_proxy.options = @options
      @gem_runner_proxy.output_filter = @output_filter
      @gem_runner_proxy.exact_match_list_command = @exact_match_list_command
  
      @gem_spec_manager = GemInstaller::GemSpecManager.new
      @gem_spec_manager.valid_platform_selector = @valid_platform_selector
      @gem_spec_manager.source_index_search_adapter = @source_index_search_adapter
      @gem_spec_manager.output_filter = @output_filter
        
      @gem_command_manager = GemInstaller::GemCommandManager.new
      @gem_command_manager.gem_spec_manager = @gem_spec_manager
      @gem_command_manager.gem_runner_proxy = @gem_runner_proxy
        
      @rogue_gem_finder = GemInstaller::RogueGemFinder.new
      @rogue_gem_finder.gem_command_manager = @gem_command_manager
      @rogue_gem_finder.gem_spec_manager = @gem_spec_manager
      @rogue_gem_finder.output_proxy = @output_proxy
      
      @autogem = GemInstaller::Autogem.new
      @autogem.gem_command_manager = @gem_command_manager
      @autogem.gem_source_index_proxy = @gem_source_index_proxy

      @gem_list_checker = GemInstaller::GemListChecker.new
      @gem_list_checker.gem_command_manager = @gem_command_manager
      @gem_list_checker.gem_arg_processor = @gem_arg_processor
      @gem_list_checker.version_specifier = @version_specifier

      @missing_dependency_finder = GemInstaller::MissingDependencyFinder.new
      @missing_dependency_finder.gem_command_manager = @gem_command_manager
      @missing_dependency_finder.gem_spec_manager = @gem_spec_manager
      @missing_dependency_finder.gem_arg_processor = @gem_arg_processor
      @missing_dependency_finder.output_filter = @output_filter

      @install_processor = GemInstaller::InstallProcessor.new
      @install_processor.options = @options
      @install_processor.gem_list_checker = @gem_list_checker
      @install_processor.gem_command_manager = @gem_command_manager
      @install_processor.gem_spec_manager = @gem_spec_manager
      @install_processor.missing_dependency_finder = @missing_dependency_finder
      @install_processor.output_filter = @output_filter
      
      if GemInstaller::RubyGemsVersionChecker.matches?('<=0.9.4')
        @gem_interaction_handler = GemInstaller::GemInteractionHandler.new
        @noninteractive_chooser_class = GemInstaller::NoninteractiveChooser
        @gem_interaction_handler.noninteractive_chooser_class = @noninteractive_chooser_class
        @gem_interaction_handler.valid_platform_selector = @valid_platform_selector
        @gem_command_manager.gem_interaction_handler = @gem_interaction_handler
        @enhanced_stream_ui.gem_interaction_handler = @gem_interaction_handler
      end

      @app = GemInstaller::Application.new
      @app.autogem = @autogem
      @app.rogue_gem_finder = @rogue_gem_finder
      @app.bundler_exporter = @bundler_exporter
      @app.options = @options
      @app.arg_parser = @arg_parser
      @app.config_builder = @config_builder
      @app.install_processor = @install_processor
      @app.output_filter = @output_filter
    end
  end
end
