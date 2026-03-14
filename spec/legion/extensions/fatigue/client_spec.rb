# frozen_string_literal: true

require 'legion/extensions/fatigue/client'

RSpec.describe Legion::Extensions::Fatigue::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a default fatigue_store' do
      expect(client.fatigue_store).to be_a(Legion::Extensions::Fatigue::Helpers::FatigueStore)
    end

    it 'accepts an injected fatigue_store' do
      custom_store = Legion::Extensions::Fatigue::Helpers::FatigueStore.new
      c = described_class.new(fatigue_store: custom_store)
      expect(c.fatigue_store).to be(custom_store)
    end
  end

  describe 'runner methods' do
    it 'responds to update_fatigue' do
      expect(client).to respond_to(:update_fatigue)
    end

    it 'responds to energy_status' do
      expect(client).to respond_to(:energy_status)
    end

    it 'responds to enter_rest' do
      expect(client).to respond_to(:enter_rest)
    end

    it 'responds to exit_rest' do
      expect(client).to respond_to(:exit_rest)
    end

    it 'responds to energy_forecast' do
      expect(client).to respond_to(:energy_forecast)
    end

    it 'responds to fatigue_stats' do
      expect(client).to respond_to(:fatigue_stats)
    end
  end

  describe 'state persistence' do
    it 'maintains state across multiple update calls' do
      5.times { client.update_fatigue(tick_results: { cognitive_load: 0.8, emotional_arousal: 0.8 }) }
      stats = client.fatigue_stats
      expect(stats[:session][:active_ticks]).to eq(5)
    end

    it 'reflects state after entering rest' do
      client.enter_rest(mode: :sleep)
      status = client.energy_status
      expect(status[:recovery_mode]).to eq(:sleep)
    end

    it 'clears recovery mode after exit_rest' do
      client.enter_rest(mode: :sleep)
      client.exit_rest
      status = client.energy_status
      expect(status[:recovery_mode]).to be_nil
    end
  end
end
