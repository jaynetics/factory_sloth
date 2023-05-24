module FactorySloth
  class CodeMod
    attr_reader :create_calls, :changed_create_calls, :path, :original_code, :patched_code

    require 'forwardable'
    extend Forwardable

    def_delegator :changed_create_calls, :any?, :changed?
    def_delegator :changed_create_calls, :count, :change_count
    def_delegator :create_calls, :count, :create_count

    def self.call(path, code)
      new(path, code).tap(&:call)
    end

    def initialize(path, code)
      self.path = path
      self.original_code = code
      self.patched_code = code
    end

    def call
      self.create_calls = CreateCallFinder.call(code: original_code)

      self.changed_create_calls = find_changeable_create_calls

      # validate whole spec after changes, e.g. to detect side-effects
      self.ok = changed_create_calls.none? || begin
        FactorySloth.verbose && puts("Checking whole file after changes")
        run(patched_code).success?
      end
      ok? || changed_create_calls.clear && patched_code.replace(original_code)
    end

    def ok?
      @ok
    end

    def message
      stats = "#{path}: #{create_count} create calls found, #{change_count} "\
              "#{FactorySloth.dry_run ? 'replaceable' : 'replaced'}"

      return "🔴 #{stats} (conflict)" unless ok?

      if create_count == 0
        "⚪️ #{stats}"
      elsif change_count == 0
        "🟡 #{stats}"
      else
        "🟢 #{stats}"
      end
    end

    private

    attr_writer :create_calls, :changed_create_calls, :ok, :path, :original_code, :patched_code

    # Performance note: it might be faster to write ALL possible patches for a
    # given spec file to tempfiles first, and then run them all in a single
    # rspec call. However, this would make it impossible to use `--fail-fast`,
    # and might make examples fail that are not as idempotent as they should be.
    def find_changeable_create_calls
      lines = create_calls.map(&:line)

      self.changed_create_calls =
        create_calls.sort_by { |call| [-call.line, -call.column] }.select do |call|
          if lines.count(call.line) > 1
            print_call_info(call, 'multiple create calls per line are unsupported, skipping')
            next
          end

          build_result = try_patch(call, 'build')
          next if build_result == ABORT

          build_result == SUCCESS || try_patch(call, 'build_stubbed') == SUCCESS
        end
    end

    def try_patch(call, base_variant)
      variant = call.name.sub('create', base_variant)
      FactorySloth.verbose && puts("#{link_to_call(call)}: trying #{variant} ...")

      new_patched_code = patched_code.sub(
        /\A(?:.*\R){#{call.line - 1}}.{#{call.column}}\K#{call.name}/,
        variant
      )
      checked_patched_code = new_patched_code + ExecutionCheck.for(call.line, variant)

      result = run(checked_patched_code, line: call.line)

      if result.success?
        info = FactorySloth.dry_run ? 'can be replaced' : 'replaced'
        print_call_info(call, "#{info} with #{variant}")
        self.patched_code = new_patched_code
        SUCCESS
      elsif result.exitstatus == ExecutionCheck::FACTORY_UNUSED_CODE
        print_call_info(call, "is never executed, skipping")
        ABORT
      elsif result.exitstatus == ExecutionCheck::FACTORY_PERSISTED_LATER_CODE
        FactorySloth.verbose && print_call_info("record is persisted later, skipping")
        ABORT
      end
    end

    def run(code, line: nil)
      result = SpecRunner.call(path, code, line: line)
      FactorySloth.verbose && puts('  RSpec output:', result.output.gsub(/^/, '    '))
      result
    end

    ABORT = :ABORT # returned if there is no need to try other variants
    SUCCESS = :SUCCESS

    def print_call_info(call, message)
      line_content = original_code[/\A(?:.*\R){#{call.line - 1}}\K.*/]
      indentation = line_content[/^\s*/]
      underline = Color.yellow('^' * call.name.size)

      puts(
        "#{link_to_call(call)}: #{call.name} #{message}",
        "  #{line_content.delete_prefix(indentation)}",
        "  #{' ' * (call.column - indentation.size)}#{underline}",
        "",
      )
    end

    def link_to_call(call)
      # note: column from Ripper is 0-indexed, editors expect 1-indexed columns
      Color.light_blue("#{path}:#{call.line}:#{call.column + 1}")
    end
  end
end
