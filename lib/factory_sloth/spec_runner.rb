require 'tmpdir'

module FactorySloth::SpecRunner
  def self.call(spec_path, spec_code, line: nil)
    puts 'spec_path', spec_path
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, File.expand_path(spec_path))
      puts 'File.dirname(path)', File.dirname(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, spec_code)
      path_arg = [path, line].compact.map(&:to_s).join(':')
      !!system("bundle exec rspec #{path_arg} --fail-fast 1>/dev/null 2>&1")
    end
  end
end
