dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/../helper/spec_helper")

describe "An EnhancedStreamUI instance with an OutputProxy injected for outs and errs" do
  
  before(:each) do
    # Can't use an rspec mock here, because you can't mock the 'puts' method
    stub_in_stream = StringIO.new("1")
    stub_out_stream = StringIO.new("","w")
    @enhanced_stream_ui = GemInstaller::EnhancedStreamUI.new
    @outs_output_observer = GemInstaller::OutputObserver.new
    @errs_output_observer = GemInstaller::OutputObserver.new
    @enhanced_stream_ui.outs = @outs_output_observer
    @outs_output_observer.stream = :stdout
    @enhanced_stream_ui.errs = @errs_output_observer
    @errs_output_observer.stream = :stderr

    @mock_outs_listener = mock('mock_outs_listener')
    @outs_output_observer.register(@mock_outs_listener)

    @mock_errs_listener = mock('mock_errs_listener')
    @errs_output_observer.register(@mock_errs_listener)
  end

  it "will throw unexpected prompt error for ask" do
    question = 'question'
    lambda{ @enhanced_stream_ui.ask(question) }.should raise_error(GemInstaller::UnexpectedPromptError)
  end

  it "will throw unexpected prompt error for ask_yes_no if question is not a dependency prompt" do
    mock_gem_interaction_handler = mock("Mock GemInteractionHandler")
    if GemInstaller::RubyGemsVersionChecker.matches?('<=0.9.4')
      # special handling for dependency prompts in ask_yes_no is not used for RubyGems >= 0.9.5,
      # all prompts are considered unexpected
      mock_gem_interaction_handler.should_receive(:handle_ask_yes_no)
      @enhanced_stream_ui.gem_interaction_handler = mock_gem_interaction_handler
    end
    question = 'question'
    lambda{ @enhanced_stream_ui.ask_yes_no(question) }.should raise_error(GemInstaller::UnexpectedPromptError)
  end

  it "will force throw of GemInstaller::UnauthorizedDependencyPromptError or RubyGemsExit if intercepted by alert_error" do
    begin
      raise GemInstaller::UnauthorizedDependencyPromptError.new
    rescue StandardError => error
      lambda{ @enhanced_stream_ui.alert_error('statement') }.should raise_error(GemInstaller::UnauthorizedDependencyPromptError)
    end

    begin
      raise GemInstaller::RubyGemsExit.new
    rescue StandardError => error
      lambda{ @enhanced_stream_ui.alert_error('statement') }.should raise_error(GemInstaller::RubyGemsExit)
    end
  end

  it "can listen to error stream" do
    statement = 'statement'
    @mock_errs_listener.should_receive(:notify).once.with('ERROR:  ' + statement + "\n", :stderr)
    @enhanced_stream_ui.alert_error(statement)
  end
  
  it "will stop listening to streams if listeners are unregistered" do
    statement = 'statement'
    @mock_errs_listener.should_receive(:notify).once.with('ERROR:  ' + statement + "\n", :stderr)
    @mock_outs_listener.should_receive(:notify).once.with(statement + "\n", :stdout)
    # listeners should receive messages when they are registered
    @enhanced_stream_ui.alert_error(statement)
    @enhanced_stream_ui.say(statement)

    # listeners should no longer receive messages when they are unregistered
    @outs_output_observer.unregister(@mock_outs_listener)
    @errs_output_observer.unregister(@mock_errs_listener)
    @enhanced_stream_ui.alert_error(statement)
    @enhanced_stream_ui.say(statement)
    
  end
  
  if GemInstaller::RubyGemsVersionChecker.matches?('<=1.0.1')
  # no more special handling of terminate_interaction required after 1.0.1
  it "will raise exception on terminate_interaction! (instead of exiting)" do
    lambda{ @enhanced_stream_ui.terminate_interaction!(0) }.should raise_error(GemInstaller::GemInstallerError)
  end

  it "will raise RubyGemsExit on terminate_interaction and status == 0 (instead of exiting)" do
    lambda{ @enhanced_stream_ui.terminate_interaction(0) }.should raise_error(GemInstaller::RubyGemsExit)
  end

  it "will raise exception on terminate_interaction and status != 0 (instead of exiting)" do
    lambda{ @enhanced_stream_ui.terminate_interaction(1) }.should raise_error(GemInstaller::GemInstallerError)
  end
  end
  
  it "will call gem_interaction_handler when ask_yes_no is called" do
    mock_gem_interaction_handler = mock("mock_gem_interaction_handler")
    if GemInstaller::RubyGemsVersionChecker.matches?('<=0.9.4')
      @enhanced_stream_ui.gem_interaction_handler = mock_gem_interaction_handler
      # special handling for dependency prompts in ask_yes_no is not used for RubyGems >= 0.9.5,
      # all prompts are considered unexpected
      question = 'question'
      @mock_outs_listener.should_receive(:notify).once.with(question, :stdout)
      error = GemInstaller::UnauthorizedDependencyPromptError
      mock_gem_interaction_handler.should_receive(:handle_ask_yes_no).with(question).and_raise(error)
    else
      error = GemInstaller::UnexpectedPromptError
    end
    lambda{ @enhanced_stream_ui.ask_yes_no(question) }.should raise_error(error)
  end


end
