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
      create_calls.sort_by { |call| [-call.line, -call.column] }.select do |call|
        build_result = try_patch(call, 'build')
        next if build_result == ABORT

        build_result == SUCCESS || try_patch(call, 'build_stubbed') == SUCCESS
      end

    # validate whole spec after changes, e.g. to detect side-effects
    self.ok = changed_create_calls.none? ||
      FactorySloth::SpecRunner.call(path, patched_code).success?
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
    checked_patched_code = new_patched_code + checks(call.line, variant)

    result = FactorySloth::SpecRunner.call(path, checked_patched_code, line: call.line)
    if result.success?
      puts "- #{call.name} in line #{call.line} can be replaced with #{variant}"
      self.patched_code = new_patched_code
      SUCCESS
    elsif result.exitstatus == FACTORY_UNUSED_CODE
      puts "- #{call.name} in line #{call.line} is never executed, skipping"
      ABORT
    elsif result.exitstatus == FACTORY_PERSISTED_LATER_CODE
      ABORT
    end
  end

  ABORT = :ABORT # returned if there is no need to try other variants
  SUCCESS = :SUCCESS

  FACTORY_UNUSED_CODE          = 77
  FACTORY_PERSISTED_LATER_CODE = 78

  # This adds code that makes a spec run fail and thus prevents changes if:
  # a) the patched factory in the given line is never called
  # b) the built record was persisted later anyway
  # The rationale behind a) is that things like skipped examples should not
  # be broken. The rationale behind b) is that not much DB work would be saved,
  # but diff noise would be increased and ease of editing the example reduced.
  def checks(line, variant)
    <<~RUBY
      ; defined?(FactoryBot) && defined?(RSpec) && RSpec.configure do |config|
        records_by_line = {} # track records initialized through factories per line

        FactoryBot::Syntax::Methods.class_eval do
          alias ___original_#{variant} #{variant} # e.g. ___original_build build

          define_method("#{variant}") do |*args, **kwargs, &blk| # e.g. build
            result = ___original_#{variant}(*args, **kwargs, &blk)
            list = records_by_line[caller_locations(1, 1)&.first&.lineno] ||= []
            list.concat([result].flatten) # to work with single, list, and pair
            result
          end
        end

        config.after(:suite) do
          records = records_by_line[#{line}]
          records&.any? || exit!(#{FACTORY_UNUSED_CODE})
          unless "#{variant}".include?('stub') # factory_bot stub stubs persisted? as true
            records.any? { |r| r.respond_to?(:persisted?) && r.persisted? } &&
              exit!(#{FACTORY_PERSISTED_LATER_CODE})
          end
        end
      end
    RUBY
  end
end
