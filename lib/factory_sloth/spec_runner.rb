require 'open3'
require 'tmpdir'

module FactorySloth::SpecRunner
  def self.call(spec_path, spec_code, line: nil)
    path = File.join(tmpdir, spec_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, spec_code)
    path_arg = [path, line].compact.map(&:to_s).join(':')
    command = "bundle exec rspec #{path_arg} --fail-fast --order defined 2>&1"
    output, process_status = Open3.capture2(command)
    Result.new(output: output, process_status: process_status)
  end

  Result = Struct.new(:output, :process_status, keyword_init: true) do
    require 'forwardable'
    extend Forwardable
    def_delegators :process_status, :exitstatus, :success?
  end

  def self.tmpdir
    @tmpdir ||= begin
      dir = Dir.mktmpdir('factory_sloth-')
      at_exit { FileUtils.remove_entry(dir) if File.exist?(dir) }
      dir
    end
  end
end
