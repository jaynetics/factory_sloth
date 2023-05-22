module FactorySloth
  module FileProcessor
    extend self

    def call(files:, forced_files: [])
      files.each_with_object({}) do |path, acc|
        if DoneTracker.done?(path) &&
           !(FactorySloth.force || forced_files.include?(path))
          puts "🔵 #{path}: skipped (marked as done in #{DoneTracker.file})", ''
          next
        end

        result = process(path)
        acc[path] = { ok: result.ok?, change_count: result.change_count }
        DoneTracker.mark_as_done(path)
      end
    end

    private

    def process(path)
      code = File.read(path)
      result = CodeMod.call(path, code)
      unless FactorySloth.dry_run
        File.write(path, result.patched_code) if result.changed?
      end
      puts result.message, ''
      result
    end
  end
end
