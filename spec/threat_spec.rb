RSpec.describe Threat do
  before(:each) do
    Threat::configure
  end

  it "has a version number" do
    expect(Threat::VERSION).not_to be nil
  end

  it "can queue requests" do
    Threat::request(:get, "https://github.com/hawkins/threat")
    expect(Threat::inbox.size).to eq(1)
  end

  it "schedules and executes requests" do
    Threat::request(:get, "https://github.com/hawkins/threat")
    sleep(3)
    expect(Threat::inbox.size).to eq(0)
    expect(Threat::outbox.size).to eq(1)
  end
end
