describe FactorySloth::CodeMod, '::call' do
  before { allow_any_instance_of(Kernel).to receive(:puts) }

  it 'can replace create calls with build' do
    input = fixture('build_ok')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 1
    expect(result.change_count).to eq 1
    expect(result.patched_code).not_to eq input
    expect(result.patched_code).to include 'build(:optional_create)'
  end

  it 'can replace create calls with build_stubbed' do
    input = fixture('build_stubbed_ok')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 1
    expect(result.change_count).to eq 1
    expect(result.patched_code).not_to eq input
    expect(result.patched_code).to include 'build_stubbed(:must_create_or_stub)'
  end

  it 'can keep individual create calls' do
    input = fixture('one_create_needed')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 2
    expect(result.change_count).to eq 1
    expect(result.patched_code).not_to eq input
    expect(result.patched_code).to include 'build(:optional_create)'
    expect(result.patched_code).to include 'create(:required_create)'
  end

  it 'works with create_list' do
    input = fixture('create_list')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 1
    expect(result.change_count).to eq 1
    expect(result.patched_code).not_to eq input
    expect(result.patched_code).to include 'build_list(:foo, 3)'
  end

  it 'works with FactoryBot.* calls' do
    input = fixture('via_module')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 2
    expect(result.change_count).to eq 2
    expect(result.patched_code).not_to eq input
    expect(result.patched_code).to include 'build(:foo)'
    expect(result.patched_code).to include 'build_list(:bar, 3)'
  end

  it 'does nothing for specs that break when individually ok changes are combined' do
    input = fixture('conflict')
    result = described_class.call('a/path', input)
    expect(result).not_to be_ok
    expect(result.patched_code).to eq input
  end

  it 'does nothing for create calls that are never executed' do
    input = fixture('skipped_calls')

    # should abort after trying build and not waste time with trying build_stubbed
    expect_any_instance_of(described_class).to receive(:try_patch)
      .exactly(4).times.with(anything, 'build').and_call_original

    result = described_class.call('a/path', input)

    expect(result).to be_ok
    expect(result.create_count).to eq 4
    expect(result.change_count).to eq 0
    expect(result.patched_code).to eq input
  end

  it 'does nothing for create calls where the record is persisted later' do
    input = fixture('persisted_later')

    # should abort after trying build and not waste time with trying build_stubbed
    expect_any_instance_of(described_class).to receive(:try_patch)
      .once.with(anything, 'build').and_call_original

    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 1
    expect(result.change_count).to eq 0
    expect(result.patched_code).to eq input
  end

  it 'does nothing for lines with multiple create calls' do
    # see comment in ExecutionCheck
    input = fixture('inlined_creates')

    # should not try to build
    expect_any_instance_of(described_class).not_to receive(:try_patch)

    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 3
    expect(result.change_count).to eq 0
    expect(result.patched_code).to eq input
  end

  it 'does nothing for files without create calls' do
    input = fixture('zero_create_calls')
    result = described_class.call('a/path', input)
    expect(result).to be_ok
    expect(result.create_count).to eq 0
    expect(result.change_count).to eq 0
    expect(result.patched_code).to eq input
  end
end

describe FactorySloth::CodeMod, '#message' do
  it 'can render a message for all result permutations' do
    [true, false].product([0, 1, 2], [0, 1, 2]) do |(ok, changes, creates)|
      codemod = described_class.new('foo', 'bar')
      allow(codemod).to receive(:create_calls).and_return([[0, 0]] * creates)
      allow(codemod).to receive(:changed_create_calls).and_return([[0, 0]] * changes)
      allow(codemod).to receive(:ok?).and_return(ok)
      expect(codemod.message).to match(ok ? /\d create calls found/ : /conflict/)
    end
  end
end
