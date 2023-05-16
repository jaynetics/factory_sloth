class FactorySloth::CodeMod
  attr_reader :create_calls, :changed_create_calls, :original_code, :patched_code

  def self.call(code)
    new(code).tap(&:call)
  end

  def initialize(code)
    self.original_code = code
    self.patched_code = code
  end

  def call
    self.create_calls = FactorySloth::CreateCallFinder.call(code: original_code)

    # Performance note: it might be faster to write ALL possible patches for a
    # given spec file to tempfiles first, and then run them all in a single
    # rspec call. However, this would make it impossible to use `--fail-fast`,
    # and might make examples fail that are not as idempotent as they should be.
    self.changed_create_calls =
      create_calls.sort_by { |line, col| [-line, -col] }.select do |line, col|
        try_patch(line, col, 'build') || try_patch(line, col, 'build_stubbed')
      end.sort

    # validate whole spec after changes, e.g. to detect side-effects
    self.ok = FactorySloth::SpecRunner.call(patched_code)
    self.changed_create_calls.clear unless ok?
    self.patched_code = original_code unless ok?
  end

  def ok?
    @ok
  end

  def changed?
    change_count > 0
  end

  def create_count
    create_calls.count
  end

  def change_count
    changed_create_calls.count
  end

  private

  attr_writer :create_calls, :changed_create_calls, :ok, :original_code, :patched_code

  def try_patch(line, col, variant)
    new_patched_code =
      patched_code.sub(/\A(?:.*\n){#{line - 1}}.{#{col}}\Kcreate/, variant)
    if FactorySloth::SpecRunner.call(new_patched_code, line: line)
      puts "- create in line #{line} can be replaced with #{variant}"
      self.patched_code = new_patched_code
    end
  end
end
