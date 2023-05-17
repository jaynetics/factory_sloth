module FactoryBot
  module Syntax
    module Methods
      %w[build build_stubbed create].each do |variant|
        define_method(variant) { |*| true }
        define_method("#{variant}_list") { |_name, n, *| n.times.map { true } }
        define_method("#{variant}_pair") { |_name, n, *| [true, true] }
      end
    end
  end
  extend Syntax::Methods
end

include FactoryBot::Syntax::Methods
