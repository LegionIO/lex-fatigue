# frozen_string_literal: true

RSpec.describe Legion::Extensions::Fatigue::Runners::Fatigue do
  let(:client) { Legion::Extensions::Fatigue::Client.new }

  describe '#update_fatigue' do
    it 'returns energy, fatigue_level, performance_factor, and recommendation' do
      result = client.update_fatigue(tick_results: { cognitive_load: 0.5, emotional_arousal: 0.5 })
      expect(result).to include(:energy, :fatigue_level, :performance_factor, :recommendation)
    end

    it 'accepts empty tick_results' do
      expect { client.update_fatigue(tick_results: {}) }.not_to raise_error
    end

    it 'accepts no arguments' do
      expect { client.update_fatigue }.not_to raise_error
    end

    it 'returns a valid fatigue level symbol' do
      result = client.update_fatigue
      expected_levels = Legion::Extensions::Fatigue::Helpers::Constants::FATIGUE_LEVELS.keys
      expect(expected_levels).to include(result[:fatigue_level])
    end

    it 'returns a valid recommendation symbol' do
      result = client.update_fatigue
      valid_recs = %i[continue reduce_load take_break enter_rest emergency_shutdown]
      expect(valid_recs).to include(result[:recommendation])
    end

    it 'includes needs_rest and burnout in result' do
      result = client.update_fatigue
      expect(result).to include(:needs_rest, :burnout)
    end
  end

  describe '#energy_status' do
    it 'returns current energy state' do
      result = client.energy_status
      expect(result).to include(
        :energy, :fatigue_level, :performance_factor,
        :needs_rest, :critically_fatigued, :burnout, :recovery_mode, :trend
      )
    end

    it 'starts fresh' do
      result = client.energy_status
      expect(result[:fatigue_level]).to eq(:fresh)
      expect(result[:burnout]).to eq(false)
    end
  end

  describe '#enter_rest' do
    it 'sets recovery mode on the model' do
      result = client.enter_rest(mode: :full_rest)
      expect(result[:success]).to eq(true)
      expect(result[:mode]).to eq(:full_rest)
    end

    it 'defaults to :full_rest mode' do
      result = client.enter_rest
      expect(result[:mode]).to eq(:full_rest)
    end

    it 'returns error for unknown mode' do
      result = client.enter_rest(mode: :hyper_sleep)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to include('hyper_sleep')
    end

    it 'accepts all valid recovery modes' do
      Legion::Extensions::Fatigue::Helpers::Constants::RECOVERY_MODES.each do |mode|
        c = Legion::Extensions::Fatigue::Client.new
        result = c.enter_rest(mode: mode)
        expect(result[:success]).to eq(true)
      end
    end
  end

  describe '#exit_rest' do
    it 'clears recovery mode' do
      client.enter_rest(mode: :sleep)
      result = client.exit_rest
      expect(result[:success]).to eq(true)
    end

    it 'returns current energy and fatigue_level' do
      result = client.exit_rest
      expect(result).to include(:energy, :fatigue_level)
    end
  end

  describe '#energy_forecast' do
    it 'returns forecast for default ticks' do
      result = client.energy_forecast
      expect(result[:forecast]).not_to be_empty
    end

    it 'returns forecast for specified ticks' do
      result = client.energy_forecast(ticks: 20)
      expect(result[:forecast].size).to eq(20)
    end

    it 'includes current_energy and ticks_to_rest' do
      result = client.energy_forecast(ticks: 10)
      expect(result).to include(:current_energy, :ticks_to_rest, :forecast)
    end
  end

  describe '#fatigue_stats' do
    it 'returns session, history, trend, and schedule' do
      result = client.fatigue_stats
      expect(result).to include(:session, :history, :trend, :schedule)
    end

    it 'session includes expected keys' do
      result = client.fatigue_stats
      expect(result[:session]).to include(:total_ticks, :current_energy, :fatigue_level, :burnout)
    end

    it 'trend is a symbol' do
      result = client.fatigue_stats
      expect(result[:trend]).to be_a(Symbol)
    end
  end
end
