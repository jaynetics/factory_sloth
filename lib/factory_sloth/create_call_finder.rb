require 'ripper'

class FactorySloth::CreateCallFinder < Ripper
  attr_reader :calls

  def self.call(code:)
    new(code).tap(&:parse).calls
  end

  def initialize(code, ...)
    super
    @code = code
    @disabled = false
    @calls = []
  end
  private_class_method :new

  def store_call(obj)
    @calls << obj if obj.is_a?(FactorySloth::CreateCall) && !@disabled
    obj
  end

  def on_ident(name, *)
    return name unless %w[create create_list create_pair].include?(name)

    FactorySloth::CreateCall.new(name: name, line: lineno, column: column)
  end

  def on_assign(left, right)
    if left.to_s.match?(/\A_/) &&
       !FactorySloth.check_underscore_vars &&
       [right, Array(right).last].any? { |v| v.is_a?(FactorySloth::CreateCall) }
      @calls.pop
    end
    [left, right]
  end

  def on_call(mod, op, method, *args)
    store_call(method) if mod == 'FactoryBot'
    [mod, op, method, *args]
  end

  def on_command_call(mod, op, method, *args)
    store_call(method) if mod == 'FactoryBot'
    [mod, op, method, *args]
  end

  def on_comment(text, *)
    return unless /sloth:(?<directive>disable|enable)/ =~ text

    directive == 'disable' &&
      @calls.reject! { |obj| obj[1] == lineno } ||
      (@lines ||= @code.lines)[lineno - 1].match?(/^\s*#/) &&
      (@disabled = directive != 'enable')
  end

  def on_fcall(loc, *)
    store_call(loc)
  end

  def on_vcall(loc, *)
    store_call(loc)
  end
end
