describe FactorySloth::FileProcessor, '::call' do
  let(:files) { [__FILE__] }
  let(:result_stub) { FactorySloth::CodeMod.new('a/path', 'dummy_code') }

  it 'processes files only once by default' do
    expect(result_stub).to receive(:change_count)
    expect(described_class).to receive(:process).and_return(result_stub)
    expect { described_class.call(files: files) }.not_to output(/Skip/).to_stdout

    expect(result_stub).not_to receive(:change_count)
    expect(described_class).not_to receive(:process)
    expect { described_class.call(files: files) }
      .to output(/#{__FILE__}: skipped/).to_stdout
  end
end
