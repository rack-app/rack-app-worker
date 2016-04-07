require 'spec_helper'

describe Rack::App::Worker do
  it 'has a version number' do
    expect(Rack::App::Worker::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
