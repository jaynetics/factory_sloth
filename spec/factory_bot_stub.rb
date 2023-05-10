module FactoryBotStub
  extend self

  %w[build build_stubbed create].each do |variant|
    define_method(variant) { |*| true }
    define_method("#{variant}_list") { |_name, n, *| n.times.map { true } }
  end
end

FactoryBot = FactoryBotStub
include FactoryBotStub
