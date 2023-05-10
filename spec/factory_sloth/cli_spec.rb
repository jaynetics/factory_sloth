describe FactorySloth::CLI, '::call' do
  it 'takes paths as arguments' do
    input = fixture('build_ok')
    temp_path = "#{Dir.tmpdir}/build_ok"
    File.write(temp_path, input)

    expect { FactorySloth::CLI.call([temp_path]) }.to output(
      /Processing .*build_ok.*- create in line 3.* 1 create calls found, 1 replaced/m
    ).to_stdout
    result = File.read(temp_path)
    expect(result).not_to eq input
    expect(result).to include 'build(:optional_create)'
  ensure
    File.unlink(temp_path) if File.exist?(temp_path)
  end

  it 'forces processing when given individual files, even if done previously' do
    expect(FactorySloth::FileProcessor).to receive(:process)
    expect { FactorySloth::CLI.call([__FILE__]) }.to output.to_stdout

    expect(FactorySloth::FileProcessor).to receive(:process)
    expect { FactorySloth::CLI.call([__FILE__]) }.to output.to_stdout
  end

  it 'can force processing with the --force option' do
    n = Dir["#{__dir__}/**/*_spec.rb"].count
    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
    expect { FactorySloth::CLI.call([__dir__]) }.to output.to_stdout

    expect(FactorySloth::DoneTracker.done?(__FILE__)).to eq true

    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
    expect { FactorySloth::CLI.call([__dir__, '--force']) }.to output.to_stdout
  end

  it 'can lint with the --lint option' do
    expect { FactorySloth::CLI.call([__FILE__, '--lint']) }
      .to output(/0 create calls found, 0 replaceable/).to_stdout

    expect { FactorySloth::CLI.call(["#{__dir__}/../fixtures/build_ok.rb", '--lint']) }
      .to raise_error(SystemExit)
      .and output(/1 create calls found, 1 replaceable/).to_stdout
      .and output(/build_ok\.rb/).to_stderr
  end

  it 'can output help and version' do
    expect { FactorySloth::CLI.call(%w[-h]) }
      .to output.to_stdout.and raise_error(SystemExit)
    expect { FactorySloth::CLI.call(%w[-v]) }
      .to output.to_stdout.and raise_error(SystemExit)
  end
end
