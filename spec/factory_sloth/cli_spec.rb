describe FactorySloth::CLI, '::call' do
  let(:result_stub) { FactorySloth::CodeMod.new('a/path', 'dummy_code') }
  before { allow(result_stub).to receive(:create_calls).and_return([])}
  before { allow(result_stub).to receive(:changed_create_calls).and_return([])}

  it 'takes paths as arguments' do
    input = fixture('build_ok')
    temp_path = "#{Dir.tmpdir}/build_ok"
    File.write(temp_path, input)

    expect { FactorySloth::CLI.call([temp_path]) }.to output(Regexp.new([
      /Processing .*build_ok.*/,
      /- create in line 3 can be replaced with build.*/,
      /.* 1 create calls found, 1 replaced.*/,
      /Scanned 1 files, found 1 unnecessary create calls across 1 files/,
    ].join("\n+"))).to_stdout
    result = File.read(temp_path)
    expect(result).not_to eq input
    expect(result).to include 'build(:optional_create)'
  ensure
    File.unlink(temp_path) if File.exist?(temp_path)
  end

  it 'forces processing when given individual files, even if done previously' do
    expect(FactorySloth::FileProcessor).to receive(:process)
      .and_return(result_stub)
    expect { FactorySloth::CLI.call([__FILE__]) }
      .to output(/Scanned 1 files.* found 0 unnecessary create calls/).to_stdout

    expect(FactorySloth::FileProcessor).to receive(:process)
      .and_return(result_stub)
    expect { FactorySloth::CLI.call([__FILE__]) }
      .to output(/Scanned 1 files.* found 0 unnecessary create calls/).to_stdout
  end

  it 'can force processing with the --force option' do
    n = Dir["#{__dir__}/**/*_spec.rb"].count
    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
      .and_return(result_stub)
    expect { FactorySloth::CLI.call([__dir__]) }
      .to output(/Scanned #{n} files/).to_stdout

    expect(FactorySloth::DoneTracker.done?(__FILE__)).to eq true

    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
      .and_return(result_stub)
    expect { FactorySloth::CLI.call([__dir__, '--force']) }
      .to output(/Scanned #{n} files/).to_stdout
  end

  it 'can lint with the --lint option' do
    FactorySloth::CLI.call([__FILE__, '--lint'])

    expect { FactorySloth::CLI.call(["#{__dir__}/../fixtures/build_ok.rb", '--lint']) }
      .to raise_error(SystemExit)
  end

  it 'can output help and version' do
    expect { FactorySloth::CLI.call(%w[-h]) }
      .to output.to_stdout.and raise_error(SystemExit)
    expect { FactorySloth::CLI.call(%w[-v]) }
      .to output.to_stdout.and raise_error(SystemExit)
  end
end
