module FactoryBot
  module Syntax
    module Methods
      %w[build build_stubbed create].each do |variant|
        define_method(variant) { |name, *| Record.new(variant: variant, name: name) }
        define_method("#{variant}_list") { |name, n, *| (1..n).map { send(variant, name) } }
        define_method("#{variant}_pair") { |name, *| (1..2).map { send(variant, name) } }
      end
    end
  end
  extend Syntax::Methods
end

include FactoryBot::Syntax::Methods

Record = Struct.new(:name, :variant, keyword_init: true) do
  def save!
    raise 'stubbed, cant save!' if variant =~ /stub/
    @persisted = true
  end

  def persisted?
    !!@persisted
  end
end
