require 'ripper'

class FactorySloth::CreateCallFinder < Ripper
  attr_reader :locations

  def self.call(code:)
    new(code).tap(&:parse).locations
  end

  def initialize(code, ...)
    super
    @code = code
    @disabled = false
    @locations = []
  end
  private_class_method :new

  def store_location(loc)
    @locations << loc if loc.instance_of?(Array) && !@disabled
  end

  def on_ident(name, *)
    [lineno, column] if %w[create create_list create_pair].include?(name)
  end

  def on_call(mod, _, loc, *)
    store_location(loc) if mod == 'FactoryBot'
  end

  def on_command_call(mod, _, loc, *)
    store_location(loc) if mod == 'FactoryBot'
  end

  def on_comment(text, *)
    return unless /sloth:(?<directive>disable|enable)/ =~ text

    directive == 'disable' &&
      @locations.reject! { |loc| loc.first == lineno } ||
      (@lines ||= @code.lines)[lineno - 1].match?(/^\s*#/) &&
      (@disabled = directive != 'enable')
  end

  def on_fcall(loc, *)
    store_location(loc)
  end

  def on_vcall(loc, *)
    store_location(loc)
  end
end
