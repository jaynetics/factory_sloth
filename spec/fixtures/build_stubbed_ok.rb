describe FactorySloth do
  it 'uses build_stubbed where sufficient' do
    create(:must_create_or_stub)
    expect(File.read(__FILE__)).to match /(?:create|build_stubbed)\(:/
  end
end
