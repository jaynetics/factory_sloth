require 'tempfile'

module FactorySloth::SpecRunner
  def self.call(spec_code, line: nil)
    tempfile = Tempfile.new
    tempfile.write(spec_code)
    tempfile.close
    path = [tempfile.path, line].compact.map(&:to_s).join(':')
    result = !!system("bundle exec rspec #{path} --fail-fast 1>/dev/null 2>&1")
    tempfile.unlink
    result
  end
end
