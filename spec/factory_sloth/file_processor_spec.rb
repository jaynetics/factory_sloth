describe FactorySloth::FileProcessor, '::call' do
  let(:files) { [__FILE__] }
  let(:result_stub) { FactorySloth::CodeMod.new('dummy_code') }

  it 'processes files only once by default' do
    expect(described_class).to receive(:process).and_return(result_stub)
    expect { described_class.call(files: files) }.not_to output(/Skip/).to_stdout

    expect(described_class).not_to receive(:process)
    expect { described_class.call(files: files) }.to output(/Skip/).to_stdout
  end

  it 'can render a message for all codemod result permutations' do
    [true, false].product([0, 1, 2], [0, 1, 2]) do |(ok, changes, creates)|
      allow(result_stub).to receive(:create_calls).and_return([[0, 0]] * creates)
      allow(result_stub).to receive(:changed_create_calls).and_return([[0, 0]] * changes)
      allow(result_stub).to receive(:ok?).and_return(ok)
      expect(File).to receive(:read).and_return :foo
      expect(FactorySloth::CodeMod).to receive(:call).with(:foo).and_return(result_stub)
      expect do
        described_class.call(files: ['x'], forced_files: ['x'], dry_run: true)
      end.to output(ok ? /\d create calls found/ : /conflict/).to_stdout
    end
  end
end
