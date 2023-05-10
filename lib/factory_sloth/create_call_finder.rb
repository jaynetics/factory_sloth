require 'ripper'

class FactorySloth::CreateCallFinder < Ripper
  attr_reader :locations

  def self.call(code:)
    new(code).tap(&:parse).locations
  end

  def initialize(...)
    super
    @locations = []
  end
  private_class_method :new

  def on_ident(name, *)
    [lineno, column] if %w[create create_list create_pair].include?(name)
  end

  def on_call(mod, _, loc, *)
    @locations << loc if loc.instance_of?(Array) && mod == 'FactoryBot'
  end

  def on_command_call(mod, _, loc, *)
    @locations << loc if loc.instance_of?(Array) && mod == 'FactoryBot'
  end

  def on_fcall(loc, *)
    @locations << loc if loc.instance_of?(Array)
  end

  def on_vcall(loc, *)
    @locations << loc if loc.instance_of?(Array)
  end
end
