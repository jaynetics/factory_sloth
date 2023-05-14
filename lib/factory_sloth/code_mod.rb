require 'tempfile'

class FactorySloth::CodeMod
  attr_reader :change_count, :create_count, :ok, :original_code, :patched_code
  alias_method :ok?, :ok

  def self.call(code)
    new(code).tap(&:call)
  end

  def initialize(code)
    self.change_count = 0
    self.original_code = code
    self.patched_code = code
  end

  def call
    create_calls = FactorySloth::CreateCallFinder.call(code: original_code)

    # Performance note: it might be faster to write ALL possible patches for a
    # given spec file to tempfiles first, and then run them all in a single
    # rspec call. However, this would make it impossible to use `--fail-fast`,
    # and might make examples fail that are not as idempotent as they should be.
    create_calls.sort_by { |line, col| [-line, -col] }.each do |line, col|
      try_patch(line, col, 'build') || try_patch(line, col, 'build_stubbed')
    end

    # validate whole spec after changes, e.g. to detect side-effects
    self.ok = spec_code_passes?(patched_code)
    self.change_count = 0 unless ok?
    self.patched_code = original_code unless ok?
    self.create_count = create_calls.count
  end

  def changed?
    change_count > 0
  end

  private

  attr_writer :change_count, :create_count, :ok, :original_code, :patched_code

  def try_patch(line, col, variant)
    new_patched_code =
      patched_code.sub(/\A(?:.*\n){#{line - 1}}.{#{col}}\Kcreate/, variant)
    if spec_code_passes?(new_patched_code, line: line)
      puts "- create in line #{line} can be replaced with #{variant}"
      self.patched_code = new_patched_code
      self.change_count += 1
    end
  end

  def spec_code_passes?(spec_code, line: nil)
    tempfile = Tempfile.new
    tempfile.write(spec_code)
    tempfile.close
    path = [tempfile.path, line].compact.map(&:to_s).join(':')
    result = !!system("bundle exec rspec #{path} --fail-fast 1>/dev/null 2>&1")
    tempfile.unlink
    result
  end
end
