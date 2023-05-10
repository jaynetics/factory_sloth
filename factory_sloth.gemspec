require_relative "lib/factory_sloth/version"

Gem::Specification.new do |spec|
  spec.name = "factory_sloth"
  spec.version = FactorySloth::VERSION
  spec.authors = ["Janosch Müller"]
  spec.email = ["janosch84@gmail.com"]

  spec.summary = "Find and replace unnecessary factory_bot create calls."
  spec.homepage = "https://github.com/jaynetics/factory_sloth"
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|spec)/|\.git)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
