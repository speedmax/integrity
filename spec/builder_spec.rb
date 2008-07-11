require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    Integrity.stub!(:scm_export_directory).and_return('/var/integrity/exports')
  end

  describe 'When initializing' do
    it "should creates a new SCM object using the scheme of the given URI's and given options" do
      Integrity::SCM.should_receive(:new).with('git', 'production')
      Integrity::Builder.new(@uri, 'production', 'rake')
    end
  end

  describe 'When building a project' do
    before(:each) do
      @scm = mock('SCM', :checkout => true)
      @build = mock('build model', :output= => true,
        :error= => true, :result= => true)
      @result = mock('SCM::Result', :output => 'blargh',
        :error => 'err', :success? => true, :failure? => false)
      Integrity::SCM.stub!(:new).and_return(@scm)
      Integrity::Build.stub!(:new).and_return(@build)
      @scm.stub!(:checkout).and_return(@result)
      @builder = Integrity::Builder.new(@uri, 'master', 'rake')
      Kernel.stub!(:system)
    end

    it 'should tell the scm to checkout the project into the export directory' do
      Dir.stub!(:chdir)
      @scm.should_receive(:checkout).with('/var/integrity/exports/foca-integrity').
        and_return(@result)
      @builder.build
    end

    it 'should instantiate a new Build model' do
      Dir.stub!(:chdir)
      Integrity::Build.should_receive(:new).and_return(@build)
      @builder.build
    end

    it "should set build's output from SCM's output" do
      Dir.stub!(:chdir)
      @build.should_receive(:output=).with('blargh')
      @builder.build
    end

    it "should set build's error from SCM's errors" do
      Dir.stub!(:chdir)
      @build.should_receive(:error=).with('err')
      @builder.build
    end

    it "should set build's status from SCM's status" do
      Dir.stub!(:chdir)
      @build.should_receive(:result=).with(true)
      @builder.build
    end

    it "should stop furter processing and return false if repository's checkout failed" do
      Dir.stub!(:chdir)
      @result.stub!(:failure?).and_return(true)
      @builder.build.should be_false
    end

    it 'should change directory to the one where the repository is checked out' do
      Dir.should_receive(:chdir).with('/var/integrity/exports/foca-integrity')
      @builder.build
    end

    it 'should run the command' do
      @builder.stub!(:export_directory).and_return(File.dirname(__FILE__))
      Kernel.should_receive(:system).with('rake')
      @builder.build
    end
  end
end