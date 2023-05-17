describe FactorySloth::CLI, '::call' do
  let(:result_stub) { FactorySloth::CodeMod.new('a/path', 'dummy_code') }
  before { allow(result_stub).to receive(:create_calls).and_return([])}
  before { allow(result_stub).to receive(:changed_create_calls).and_return([])}

  it 'takes paths as arguments' do
    puts 1, Time.now.to_i
    input = fixture('build_ok')
    puts 2, Time.now.to_i
    temp_path = "#{Dir.tmpdir}/build_ok"
    File.write(temp_path, input)

    puts 3, Time.now.to_i
    expect { FactorySloth::CLI.call([temp_path]) }.to output(Regexp.new([
      /Processing .*build_ok.*/,
      /- create in line 3 can be replaced with build.*/,
      /.* 1 create calls found, 1 replaced.*/,
      /Scanned 1 files, found 1 unnecessary create calls across 1 files/,
    ].join("\n+"))).to_stdout
    puts 4, Time.now.to_i

    result = File.read(temp_path)
    puts 5, Time.now.to_i

    expect(result).not_to eq input
    expect(result).to include 'build(:optional_create)'
  ensure
    File.unlink(temp_path) if File.exist?(temp_path)
    puts 6, Time.now.to_i

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
    puts 1, Time.now.to_i
    n = Dir["#{__dir__}/**/*_spec.rb"].count
    puts 2, Time.now.to_i
    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
    .and_return(result_stub)
    puts 3, Time.now.to_i
    expect { FactorySloth::CLI.call([__dir__]) }
      .to output(/Scanned #{n} files/).to_stdout
puts 4, Time.now.to_i
    expect(FactorySloth::DoneTracker.done?(__FILE__)).to eq true
puts 5, Time.now.to_i
    expect(FactorySloth::FileProcessor).to receive(:process).exactly(n).times
      .and_return(result_stub)
    puts 6, Time.now.to_i
    expect { FactorySloth::CLI.call([__dir__, '--force']) }
      .to output(/Scanned #{n} files/).to_stdout
      puts 7, Time.now.to_i
  end

end
