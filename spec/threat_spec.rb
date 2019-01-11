RSpec.describe Threat do
  URL = "https://github.com/hawkins/threat"

  before(:each) do
    Threat::configure
  end

  it "has a version number" do
    expect(Threat::VERSION).not_to be nil
  end

  it "can queue requests" do
    Threat::request(:get, URL)
    expect(Threat::inbox.size).to eq(1)
  end

  it "schedules and executes requests" do
    Threat::request(:get, URL)
    sleep(3)
    expect(Threat::inbox.size).to eq(0)
    expect(Threat::outbox.size).to eq(1)
  end

  it "can invoke common HTTP requests by name" do
    Threat::get(URL)
    Threat::put(URL)
    Threat::post(URL)
    Threat::patch(URL)
    Threat::delete(URL)
    Threat::head(URL)
    sleep(3)
    expect(Threat::inbox.size).to eq(0)
    expect(Threat::outbox.size).to eq(6)
  end
end
