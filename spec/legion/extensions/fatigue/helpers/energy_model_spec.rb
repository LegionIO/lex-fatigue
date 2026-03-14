# frozen_string_literal: true

RSpec.describe Legion::Extensions::Fatigue::Helpers::EnergyModel do
  subject(:model) { described_class.new }

  let(:constants) { Legion::Extensions::Fatigue::Helpers::Constants }

  describe '#initialize' do
    it 'starts at MAX_ENERGY' do
      expect(model.energy).to eq(constants::MAX_ENERGY)
    end

    it 'starts as :fresh' do
      expect(model.fatigue_level).to eq(:fresh)
    end

    it 'starts with zero ticks' do
      expect(model.ticks_active).to eq(0)
      expect(model.ticks_resting).to eq(0)
    end

    it 'starts without burnout' do
      expect(model.burnout).to eq(false)
    end

    it 'starts with no recovery mode' do
      expect(model.recovery_mode).to be_nil
    end

    it 'starts with empty history' do
      expect(model.history).to be_empty
    end

    it 'sets peak_energy to MAX_ENERGY' do
      expect(model.peak_energy).to eq(constants::MAX_ENERGY)
    end
  end

  describe '#tick (active)' do
    it 'reduces energy on an active tick' do
      initial = model.energy
      model.tick(cognitive_load: 0.5, emotional_arousal: 0.5, is_resting: false)
      expect(model.energy).to be < initial
    end

    it 'increments ticks_active' do
      model.tick(is_resting: false)
      expect(model.ticks_active).to eq(1)
    end

    it 'does not increment ticks_resting on active tick' do
      model.tick(is_resting: false)
      expect(model.ticks_resting).to eq(0)
    end

    it 'drains more with high cognitive load' do
      m1 = described_class.new
      m2 = described_class.new
      m1.tick(cognitive_load: 0.1, emotional_arousal: 0.5, is_resting: false)
      m2.tick(cognitive_load: 0.9, emotional_arousal: 0.5, is_resting: false)
      expect(m2.energy).to be < m1.energy
    end

    it 'drains more with high emotional arousal' do
      m1 = described_class.new
      m2 = described_class.new
      m1.tick(cognitive_load: 0.5, emotional_arousal: 0.1, is_resting: false)
      m2.tick(cognitive_load: 0.5, emotional_arousal: 0.9, is_resting: false)
      expect(m2.energy).to be < m1.energy
    end

    it 'records a history snapshot' do
      model.tick
      expect(model.history.size).to eq(1)
    end

    it 'returns a hash with energy and fatigue_level' do
      result = model.tick
      expect(result).to include(:energy, :fatigue_level, :performance_factor)
    end
  end

  describe '#tick (resting)' do
    before do
      # Drain some energy first
      20.times { model.tick(cognitive_load: 0.8, emotional_arousal: 0.8, is_resting: false) }
    end

    it 'recovers energy on a rest tick' do
      drained = model.energy
      model.tick(is_resting: true)
      expect(model.energy).to be > drained
    end

    it 'increments ticks_resting' do
      model.tick(is_resting: true)
      expect(model.ticks_resting).to be >= 1
    end

    it 'resets consecutive_low_ticks when resting' do
      model.tick(is_resting: true)
      expect(model.consecutive_low_ticks).to eq(0)
    end
  end

  describe '#fatigue_level classification' do
    it 'returns :fresh when energy is high' do
      expect(model.fatigue_level).to eq(:fresh)
    end

    it 'returns :depleted when energy is very low' do
      model.instance_variable_set(:@energy, 0.05)
      model.send(:classify_fatigue)
      expect(model.fatigue_level).to eq(:depleted)
    end

    it 'returns :alert when energy is between alert and fresh thresholds' do
      # Drain to alert range (0.6-0.8)
      model.instance_variable_set(:@energy, 0.7)
      model.send(:classify_fatigue)
      expect(model.fatigue_level).to eq(:alert)
    end

    it 'returns :tired when energy is in tired range' do
      model.instance_variable_set(:@energy, 0.5)
      model.send(:classify_fatigue)
      expect(model.fatigue_level).to eq(:tired)
    end

    it 'returns :exhausted when energy is in exhausted range' do
      model.instance_variable_set(:@energy, 0.3)
      model.send(:classify_fatigue)
      expect(model.fatigue_level).to eq(:exhausted)
    end
  end

  describe '#performance_factor' do
    it 'returns 1.0 when fresh' do
      expect(model.performance_factor).to eq(1.0)
    end

    it 'returns degraded performance when tired' do
      model.instance_variable_set(:@energy, 0.5)
      model.send(:classify_fatigue)
      expect(model.performance_factor).to be < 1.0
    end
  end

  describe '#needs_rest?' do
    it 'returns false when energy is high' do
      expect(model.needs_rest?).to eq(false)
    end

    it 'returns true when energy is below REST_THRESHOLD' do
      model.instance_variable_set(:@energy, constants::REST_THRESHOLD - 0.01)
      expect(model.needs_rest?).to eq(true)
    end
  end

  describe '#critically_fatigued?' do
    it 'returns false when energy is normal' do
      expect(model.critically_fatigued?).to eq(false)
    end

    it 'returns true when energy is below CRITICAL_THRESHOLD' do
      model.instance_variable_set(:@energy, constants::CRITICAL_THRESHOLD - 0.01)
      expect(model.critically_fatigued?).to eq(true)
    end
  end

  describe '#burnout?' do
    it 'returns false initially' do
      expect(model.burnout?).to eq(false)
    end

    it 'returns true after BURNOUT_THRESHOLD consecutive low-energy ticks' do
      model.instance_variable_set(:@energy, 0.1)
      model.instance_variable_set(:@consecutive_low_ticks, constants::BURNOUT_THRESHOLD + 1)
      model.send(:check_burnout)
      expect(model.burnout?).to eq(true)
    end
  end

  describe '#enter_recovery' do
    it 'sets recovery mode to a valid mode' do
      model.enter_recovery(:full_rest)
      expect(model.recovery_mode).to eq(:full_rest)
    end

    it 'rejects invalid recovery modes' do
      model.enter_recovery(:turbo_nap)
      expect(model.recovery_mode).to be_nil
    end

    it 'accepts all defined recovery modes' do
      constants::RECOVERY_MODES.each do |mode|
        m = described_class.new
        m.enter_recovery(mode)
        expect(m.recovery_mode).to eq(mode)
      end
    end
  end

  describe '#exit_recovery' do
    it 'clears the recovery mode' do
      model.enter_recovery(:sleep)
      model.exit_recovery
      expect(model.recovery_mode).to be_nil
    end
  end

  describe '#time_to_rest_threshold' do
    it 'returns 0 when already needs rest' do
      model.instance_variable_set(:@energy, 0.1)
      expect(model.time_to_rest_threshold).to eq(0)
    end

    it 'returns a positive integer when energy is above REST_THRESHOLD' do
      expect(model.time_to_rest_threshold).to be > 0
    end
  end

  describe '#time_to_full_recovery' do
    it 'returns 0 when already at MAX_ENERGY' do
      expect(model.time_to_full_recovery).to eq(0)
    end

    it 'returns a positive integer when below MAX_ENERGY' do
      model.instance_variable_set(:@energy, 0.5)
      expect(model.time_to_full_recovery).to be > 0
    end

    it 'recovers faster with sleep mode' do
      m1 = described_class.new
      m2 = described_class.new
      m1.instance_variable_set(:@energy, 0.5)
      m2.instance_variable_set(:@energy, 0.5)
      m1.enter_recovery(:active_rest)
      m2.enter_recovery(:sleep)
      expect(m2.time_to_full_recovery).to be < m1.time_to_full_recovery
    end
  end

  describe '#trend' do
    it 'returns :stable with less than 5 history entries' do
      3.times { model.tick }
      expect(model.trend).to eq(:stable)
    end

    it 'returns :draining after continuous active ticks' do
      # Ensure 5+ history entries with declining energy
      10.times { model.tick(cognitive_load: 0.9, emotional_arousal: 0.9, is_resting: false) }
      expect(model.trend).to eq(:draining)
    end

    it 'returns :recovering after rest ticks from low energy' do
      model.instance_variable_set(:@energy, 0.2)
      10.times { model.tick(is_resting: true) }
      expect(model.trend).to eq(:recovering)
    end
  end

  describe 'history capping' do
    it 'does not exceed MAX_HISTORY entries' do
      (constants::MAX_HISTORY + 20).times { model.tick }
      expect(model.history.size).to eq(constants::MAX_HISTORY)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      result = model.to_h
      expect(result).to include(
        :energy, :fatigue_level, :performance_factor,
        :needs_rest, :critically_fatigued, :burnout,
        :recovery_mode, :peak_energy, :ticks_active,
        :ticks_resting, :trend, :history_size
      )
    end
  end
end
