dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/../helper/spec_helper")

context "An output filter" do
  setup do
    @output_filter = GemInstaller::OutputFilter.new
    @mock_output_proxy = mock("Mock OutputProxy")
    @output_filter.output_proxy = @mock_output_proxy
    @options = {}
    @output_filter.options = @options
    @message = "message"
    @expected_rubygems_stdout_message = "[RubyGems:stdout] #{@message}"
    @expected_rubygems_stderr_message = "[RubyGems:stderr] #{@message}"
  end

  specify "should pass formatted rubygems stdout message to output proxy if 'stdout' rubygems_output option is set" do
    @options[:rubygems_output] = [:stdout]
    @mock_output_proxy.should_receive(:sysout).with(@expected_rubygems_stdout_message)
    @output_filter.rubygems_output(:stdout, @message)
  end

  specify "should pass formatted rubygems stdout and stderr message to output proxy if 'all' rubygems_output option is set" do
    @options[:rubygems_output] = [:all]
    @mock_output_proxy.should_receive(:sysout).with(@expected_rubygems_stdout_message)
    @mock_output_proxy.should_receive(:sysout).with(@expected_rubygems_stderr_message)
    @output_filter.rubygems_output(:stdout, @message)
    @output_filter.rubygems_output(:stderr, @message)
  end

  specify "should not pass rubygems stdout message to output proxy if 'stdout' rubygems_output option is not set" do
    @options[:rubygems_output] = [:stderr]
    @output_filter.rubygems_output(:stdout, @message)
  end

  specify "should pass geminstaller stdout message to output proxy if 'stdout' geminstaller_output option is set" do
    @options[:geminstaller_output] = [:stdout]
    @mock_output_proxy.should_receive(:sysout).with(@message)
    @output_filter.geminstaller_output(:stdout, @message)
  end


end