module FactorySloth
  module FileProcessor
    extend self

    def call(files:, forced_files: [], dry_run: false)
      files.each_with_object({}) do |path, acc|
        puts "Processing #{path} ..."

        if DoneTracker.done?(path) && !forced_files.include?(path)
          puts "🔵 Skipped (marked as done in #{DoneTracker.file})", ''
          next
        end

        result = process(path, dry_run: dry_run)
        acc[path] = { ok: result.ok?, changed_create_calls: result.changed_create_calls }
        DoneTracker.mark_as_done(path)
      end
    end

    private

    def process(path, dry_run:)
      code = File.read(path)
      result = CodeMod.call(path, code)
      unless dry_run
        File.write(path, result.patched_code) if result.changed?
      end
      puts result_message(result, dry_run), ''
      result
    end

    def result_message(result, dry_run)
      stats = "#{result.create_count} create calls found, "\
              "#{result.change_count} #{dry_run ? 'replaceable' : 'replaced'}"

      return "🔴 #{stats} (conflict)" unless result.ok?

      if result.create_count == 0
        "⚪️ #{stats}"
      elsif result.change_count == 0
        "🟡 #{stats}"
      else
        "🟢 #{stats}"
      end
    end
  end
end
