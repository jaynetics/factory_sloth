module FactorySloth
  singleton_class.attr_accessor :dry_run, :force, :lint, :verbose
end

require_relative 'factory_sloth/cli'
require_relative 'factory_sloth/code_mod'
require_relative 'factory_sloth/color'
require_relative 'factory_sloth/create_call'
require_relative 'factory_sloth/create_call_finder'
require_relative 'factory_sloth/done_tracker'
require_relative 'factory_sloth/execution_check'
require_relative 'factory_sloth/file_processor'
require_relative 'factory_sloth/spec_picker'
require_relative 'factory_sloth/spec_runner'
require_relative 'factory_sloth/version'
