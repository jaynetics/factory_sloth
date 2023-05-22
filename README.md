# FactorySloth 🦥

[![Gem Version](https://badge.fury.io/rb/factory_sloth.svg)](http://badge.fury.io/rb/factory_sloth)
[![Build Status](https://github.com/jaynetics/factory_sloth/actions/workflows/tests.yml/badge.svg)](https://github.com/jaynetics/factory_sloth/actions)
[![Coverage](https://codecov.io/gh/jaynetics/factory_sloth/branch/main/graph/badge.svg?token=W6UJA0F8WO)](https://codecov.io/gh/jaynetics/factory_sloth)

`factory_sloth` is too lazy to write to the database.

It finds unnecessary [factory_bot](https://github.com/thoughtbot/factory_bot) `create` calls and replaces them with less laborious `build` or `build_stubbed` calls to speed up your test suite.

## Installation

`bundle add factory_sloth` or `gem install factory_sloth`.

## Usage

Output of `factory_sloth --help`:

```
Usage: factory_sloth [path1, path2, ...] [options]

Examples:
  factory_sloth # run for all specs
  factory_sloth spec/models
  factory_sloth spec/foo_spec.rb spec/bar_spec.rb

Options:
    -f, --force                      Ignore ./.factory_sloth_done
    -l, --lint                       Dont fix, just list bad create calls
    -V, --verbose                    Verbose output, useful for debugging
    -v, --version                    Show gem version
    -h, --help                       Show this help
```

`factory_sloth` runs the changed specs to see if they still work. This takes a while for all possible changes - usually multiple times as long as the specs would normally take to run! For this reason, the gem creates a `.factory_sloth_done` file. This is a list of specs that have already been processed. It makes it possible to interrupt the program and continue later. You can delete this file to start over or ignore it with `-f`.

While running, `factory_sloth` produces output like this:

```
🟡 spec/features/sign_up_spec.rb: 2 create calls found, 0 replaced

⚪️ spec/lib/string_ext_spec.rb: 0 create calls found, 0 replaced

spec/models/user_spec.rb:3:2: create replaced with build
  expect(create(:user)).not_to be_nil
         ^^^^^^

spec/models/user_spec.rb:4:2: create_list replaced with build_list
  expect(create_list(:user, 2).count).to eq 2
          ^^^^^^^^^^^

🟢 spec/models/user_spec.rb: 3 create calls found, 2 replaced

spec/weird_dir/crazy_spec.rb:8:4: create replaced with build_stubbed
  expect(create(:user)).not_to be_nil
         ^^^^^^

🔴 spec/weird_dir/crazy_spec.rb: 33 create calls found, 0 replaced (conflict)

Scanned 4 files, found 2 unnecessary create calls across 1 files and 1 broken specs
```

The `conflict` case is rare. It only happens if individual examples were green after changing them, but at least one example failed when evaluating the whole file after all changes. This probably means that some other example was red even before making changes, or that something else is wrong with this spec file, e.g. some examples depend on other examples' side effects.

## Limitations / known issues

`factory_sloth` only works with RSpec so far. It also works best with unit tests such as model specs. It generates **false positives** in cases where create calls are done but only the *absence* of any effect is tested, e.g.:

```ruby
user = create(:user)
User.delete_all
expect(User.count).to eq 0
```

This test will still pass if `user` is never inserted into the database in the first place, leading `factory_sloth` to believe that `build` suffices here. However, this change makes the test no longer assert the same thing and reduces coverage. Magic comments can be used to prevent `factory_sloth` from making such changes. `factory_sloth` will not touch lines with inline `# sloth:disable` comments, or sections framed in `# sloth:disable` / `# sloth:enable` comments. Another option is to write the test in a different (and arguably more assertive) way, e.g.:

```ruby
expect { User.delete_all }.to change { User.count }.from(1).to(0)
```

If you have a good idea about how to detect such cases automatically, let me know :)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaynetics/factory_sloth.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Similar projects

- [factory_trace](https://github.com/djezzzl/factory_trace) finds unused factories
- [rspectre](https://github.com/dgollahon/rspectre) finds unused test setup
- [rubocop-factory_bot](https://github.com/rubocop/rubocop-factory_bot) provides rubocop linters for factories
