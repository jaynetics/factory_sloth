module FactorySloth::DoneTracker
  extend self

  def done?(path)
    done.include?(normalize(path))
  end

  def mark_as_done(path)
    normalized_path = normalize(path)
    return if done?(normalized_path)

    done << normalized_path
    File.open(file, 'a') { |f| f.puts(normalized_path) }
  end

  def reset
    File.unlink(file) if File.exist?(file)
    done.clear
  end

  def file
    './.factory_sloth_done'
  end

  private

  def normalize(path)
    path.start_with?('./') || path.start_with?('/') ? path : "./#{path}"
  end

  def done
    @done ||= File.exist?(file) ? File.readlines(file, chomp: true) : []
  end
end
