require 'optparse'

module FactorySloth
  module CLI
    extend self

    def call(argv = ARGV)
      args = option_parser.parse!(argv)
      specs = SpecPicker.call(paths: args)
      forced_files = @force ? specs : args
      results = FileProcessor.call(files: specs, forced_files: forced_files, dry_run: @lint)
      print_summary(results)
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

    def print_summary(results)
      unnecessary_call_count = results.values.sum { |v| v[:changed_create_calls].count }
      changed_specs = results.keys.select { |path| results[path][:changed_create_calls].any? }
      broken_specs = results.keys.select { |path| !results[path][:ok] }
      stats = "Scanned #{results.count} files, found #{unnecessary_call_count}"\
              " unnecessary create calls across #{changed_specs.count} files"\
              "#{" and #{broken_specs.count} broken specs" if broken_specs.any?}"

      if @lint && unnecessary_call_count > 0
        warn "#{stats}:\n#{(changed_specs + broken_specs).join("\n")}"
        exit 1
      else
        puts stats
      end
    end
  end
end
