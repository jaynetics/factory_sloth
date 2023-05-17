class FactorySloth::CodeMod
  attr_reader :create_calls, :changed_create_calls, :path, :original_code, :patched_code

  def self.call(path, code)
    new(path, code).tap(&:call)
  end

  def initialize(path, code)
    self.path = path
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
      create_calls
      .sort_by { |call| [-call.line, -call.column] }
      .select { |call| try_patch(call, 'build') || try_patch(call, 'build_stubbed') }

    # validate whole spec after changes, e.g. to detect side-effects
    self.ok = changed_create_calls.none? ||
      FactorySloth::SpecRunner.call(path, patched_code)
    changed_create_calls.clear unless ok?
    patched_code.replace(original_code) unless ok?
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

  attr_writer :create_calls, :changed_create_calls, :ok, :path, :original_code, :patched_code

  def try_patch(call, base_variant)
    variant = call.name.sub('create', base_variant)
    new_patched_code = patched_code.sub(
      /\A(?:.*\n){#{call.line - 1}}.{#{call.column}}\K#{call.name}/,
      variant
    )
    checked_patched_code = with_execution_check(new_patched_code, call.line, variant)
    if FactorySloth::SpecRunner.call(path, checked_patched_code, line: call.line)
      puts "- #{call.name} in line #{call.line} can be replaced with #{variant}"
      self.patched_code = new_patched_code
    end
  end

  def with_execution_check(spec_code, line, variant)
    spec_code + <<~RUBY
      ; defined?(FactoryBot) && defined?(RSpec) && RSpec.configure do |config|
        executed_lines = []

        FactoryBot::Syntax::Methods.class_eval do
          alias ___original_#{variant} #{variant}

          define_method("#{variant}") do |*args, **kwargs, &blk|
            executed_lines << caller_locations(1, 1)&.first&.lineno
            ___original_#{variant}(*args, **kwargs, &blk)
          end
        end

        config.after(:suite) do
          executed_lines.include?(#{line}) ||
            fail("unused factory in line #{line} - will not be modified")
        end
      end
    RUBY
  end
end
