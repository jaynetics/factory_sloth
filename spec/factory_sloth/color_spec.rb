describe FactorySloth::Color do
  it 'works' do
    expect(FactorySloth::Color).to receive(:tty?).and_return true
    expect(FactorySloth::Color.yellow('foo')).to eq "\e[33mfoo\e[0m"
  end
end
