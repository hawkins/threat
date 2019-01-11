RSpec.describe Threat do
  it "has a version number" do
    expect(Threat::VERSION).not_to be nil
  end

  it "can queue requests" do
    Threat::request(:get, "https://github.com/hawkins/threat")
    expect(Threat::inbox.size).to eq(1)
  end
end
