require 'optparse'

module FactorySloth
  module CLI
    extend self

    def call(argv = ARGV)
      args = option_parser.parse!(argv)
      specs = SpecPicker.call(paths: args)
      forced_files = @force ? specs : args
      bad_specs = FileProcessor.call(files: specs, forced_files: forced_files, dry_run: @lint)

      if @lint && bad_specs.any?
        warn "Found unnecessary create calls in:\n#{bad_specs.join("\n")}"
        exit 1
      end
    end

    private

    def option_parser
      OptionParser.new do |opts|
        opts.banner = <<~SH
          Usage: factory_sloth [path1, path2, ...] [options]

          Examples:
            factory_sloth # run for all specs
            factory_sloth ./spec/models
            factory_sloth ./spec/foo_spec.rb ./spec/bar_spec.rb

        SH

        opts.separator 'Options:'

        opts.on('-f', '--force', "Ignore #{DoneTracker.file}") do
          @force = true
        end

        opts.on('-l', '--lint', 'Dont fix, just list bad create calls') do
          @lint = true
        end

        opts.on('-v', '--version', 'Show gem version') do
          puts "factory_sloth #{FactorySloth::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Show this help') do
          puts opts
          exit
        end
      end
    end
  end
end
