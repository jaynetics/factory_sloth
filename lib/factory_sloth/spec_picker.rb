module FactorySloth::SpecPicker
  extend self

  def call(paths:)
    paths = ['.'] if paths.empty?

    paths.each_with_object([]) do |path, acc|
      if File.directory?(path)
        acc.concat(Dir["#{path.chomp('/')}/**/*_spec.rb"])
      elsif File.exist?(path)
        acc << path
      else
        raise ArgumentError, "no such file: #{path}"
      end
    end
  end
end
