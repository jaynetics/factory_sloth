# This adds code that makes a spec run fail and thus prevents changes if:
# a) the patched factory in the given line is never called
# b) the built record was persisted later anyway
# The rationale behind a) is that things like skipped examples should not
# be broken. The rationale behind b) is that not much DB work would be saved,
# but diff noise would be increased and ease of editing the example reduced.
#
# Note: the caller column is only available in a roundabout way in Ruby >= 3.1,
# https://bugs.ruby-lang.org/issues/17930, 19452, so multiple replacements
# in one line would not be validated correctly iff they had mixed validity.

module FactorySloth::ExecutionCheck
  FACTORY_UNUSED_CODE          = 77
  FACTORY_PERSISTED_LATER_CODE = 78

  def self.for(line, variant)
    <<~RUBY
      ; defined?(FactoryBot) && defined?(RSpec) && RSpec.configure do |config|
        records_by_line = {} # track records initialized through factories per line

        FactoryBot::Syntax::Methods.class_eval do
          original_variant = instance_method("#{variant}") # e.g. build

          define_method("#{variant}") do |*args, **kwargs, &blk|
            result = original_variant.bind_call(self, *args, **kwargs, &blk)
            list = records_by_line[caller_locations(1, 1)&.first&.lineno] ||= []
            list.concat([result].flatten) # to work with single, list, and pair
            result
          end
        end

        config.after(:suite) do
          records = records_by_line[#{line}]
          records&.any? || exit!(#{FACTORY_UNUSED_CODE})
          unless "#{variant}".include?('stub') # factory_bot stub stubs persisted? as true
            records.any? { |r| r.respond_to?(:persisted?) && r.persisted? } &&
              exit!(#{FACTORY_PERSISTED_LATER_CODE})
          end
        end
      end
    RUBY
  end
end
