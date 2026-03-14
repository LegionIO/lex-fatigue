# frozen_string_literal: true

RSpec.describe Legion::Extensions::Fatigue::Helpers::FatigueStore do
  subject(:store) { described_class.new }

  let(:constants) { Legion::Extensions::Fatigue::Helpers::Constants }

  describe '#initialize' do
    it 'creates a default EnergyModel' do
      expect(store.model).to be_a(Legion::Extensions::Fatigue::Helpers::EnergyModel)
    end

    it 'accepts an injected model' do
      custom_model = Legion::Extensions::Fatigue::Helpers::EnergyModel.new
      s = described_class.new(model: custom_model)
      expect(s.model).to be(custom_model)
    end

    it 'records session start time' do
      expect(store.session_start).to be_a(Time)
    end

    it 'starts with zero ticks' do
      expect(store.total_active_ticks).to eq(0)
      expect(store.total_rest_ticks).to eq(0)
    end
  end

  describe '#update' do
    it 'calls model.tick and returns results' do
      result = store.update(tick_results: { cognitive_load: 0.5, emotional_arousal: 0.5 })
      expect(result).to include(:energy, :fatigue_level)
    end

    it 'increments total_active_ticks on active update' do
      store.update(tick_results: { cognitive_load: 0.5 })
      expect(store.total_active_ticks).to eq(1)
    end

    it 'increments total_rest_ticks when mode is :resting' do
      store.update(tick_results: { mode: :resting })
      expect(store.total_rest_ticks).to eq(1)
    end

    it 'uses default cognitive_load and emotional_arousal when not provided' do
      expect { store.update(tick_results: {}) }.not_to raise_error
    end

    it 'increments rest ticks when recovery_mode is set on model' do
      store.model.enter_recovery(:full_rest)
      store.update(tick_results: {})
      expect(store.total_rest_ticks).to be >= 1
    end
  end

  describe '#recommend_action' do
    it 'returns :continue when energy is high' do
      expect(store.recommend_action).to eq(:continue)
    end

    it 'returns :reduce_load when tired' do
      store.model.instance_variable_set(:@energy, 0.5)
      store.model.instance_variable_set(:@fatigue_level, :tired)
      expect(store.recommend_action).to eq(:reduce_load)
    end

    it 'returns :take_break when needs_rest' do
      store.model.instance_variable_set(:@energy, constants::REST_THRESHOLD - 0.01)
      expect(store.recommend_action).to eq(:take_break)
    end

    it 'returns :enter_rest when critically fatigued' do
      store.model.instance_variable_set(:@energy, constants::CRITICAL_THRESHOLD - 0.01)
      expect(store.recommend_action).to eq(:enter_rest)
    end

    it 'returns :emergency_shutdown when burnout' do
      store.model.instance_variable_set(:@burnout, true)
      expect(store.recommend_action).to eq(:emergency_shutdown)
    end

    it 'returns :emergency_shutdown when critically fatigued with burnout' do
      store.model.instance_variable_set(:@energy, 0.01)
      store.model.instance_variable_set(:@burnout, true)
      expect(store.recommend_action).to eq(:emergency_shutdown)
    end
  end

  describe '#session_stats' do
    it 'returns a hash with expected keys' do
      result = store.session_stats
      expect(result).to include(
        :duration_seconds, :total_ticks, :active_ticks, :rest_ticks,
        :active_ratio, :current_energy, :fatigue_level, :burnout
      )
    end

    it 'reflects updated tick counts' do
      3.times { store.update(tick_results: {}) }
      stats = store.session_stats
      expect(stats[:active_ticks]).to eq(3)
      expect(stats[:total_ticks]).to eq(3)
    end

    it 'reports active_ratio of 0.0 before any ticks' do
      expect(store.session_stats[:active_ratio]).to eq(0.0)
    end
  end

  describe '#energy_forecast' do
    it 'returns forecast for requested number of ticks' do
      result = store.energy_forecast(ticks: 10)
      expect(result[:forecast].size).to eq(10)
    end

    it 'includes current_energy and ticks_to_rest' do
      result = store.energy_forecast(ticks: 5)
      expect(result).to include(:current_energy, :ticks_to_rest, :forecast)
    end

    it 'energy in forecast is non-increasing (draining scenario)' do
      result = store.energy_forecast(ticks: 5)
      energies = result[:forecast].map { |f| f[:energy] }
      energies.each_cons(2) do |a, b|
        expect(b).to be <= a
      end
    end

    it 'each forecast entry includes tick, energy, and fatigue_level' do
      result = store.energy_forecast(ticks: 3)
      result[:forecast].each do |entry|
        expect(entry).to include(:tick, :energy, :fatigue_level)
      end
    end
  end

  describe '#optimal_rest_schedule' do
    it 'returns schedule hash with expected keys' do
      result = store.optimal_rest_schedule
      expect(result).to include(
        :recommend_rest_in, :full_recovery_ticks, :current_energy,
        :recommended_mode, :trend
      )
    end

    it 'recommends sleep mode for critically low energy' do
      store.model.instance_variable_set(:@energy, constants::CRITICAL_THRESHOLD - 0.01)
      result = store.optimal_rest_schedule
      expect(result[:recommended_mode]).to eq(:sleep)
    end

    it 'recommends active_rest when energy is normal' do
      result = store.optimal_rest_schedule
      expect(result[:recommended_mode]).to eq(:active_rest)
    end
  end
end
