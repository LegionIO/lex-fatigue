# frozen_string_literal: true

RSpec.describe Legion::Extensions::Fatigue::Helpers::Constants do
  describe 'energy limits' do
    it 'defines MAX_ENERGY as 1.0' do
      expect(described_class::MAX_ENERGY).to eq(1.0)
    end

    it 'defines MIN_ENERGY as 0.0' do
      expect(described_class::MIN_ENERGY).to eq(0.0)
    end

    it 'MAX_ENERGY is greater than MIN_ENERGY' do
      expect(described_class::MAX_ENERGY).to be > described_class::MIN_ENERGY
    end
  end

  describe 'drain and recovery rates' do
    it 'defines ACTIVE_DRAIN_RATE as a positive float' do
      expect(described_class::ACTIVE_DRAIN_RATE).to be > 0.0
    end

    it 'defines RESTING_RECOVERY_RATE as a positive float' do
      expect(described_class::RESTING_RECOVERY_RATE).to be > 0.0
    end

    it 'defines COGNITIVE_DRAIN_MULTIPLIER greater than 1.0' do
      expect(described_class::COGNITIVE_DRAIN_MULTIPLIER).to be > 1.0
    end

    it 'defines EMOTIONAL_DRAIN_MULTIPLIER greater than 1.0' do
      expect(described_class::EMOTIONAL_DRAIN_MULTIPLIER).to be > 1.0
    end
  end

  describe 'FATIGUE_LEVELS' do
    subject(:levels) { described_class::FATIGUE_LEVELS }

    it 'contains exactly 5 levels' do
      expect(levels.size).to eq(5)
    end

    it 'includes fresh, alert, tired, exhausted, depleted' do
      expect(levels).to include(:fresh, :alert, :tired, :exhausted, :depleted)
    end

    it 'has thresholds in descending order' do
      values = levels.values
      expect(values).to eq(values.sort.reverse)
    end

    it 'fresh threshold is the highest' do
      expect(levels[:fresh]).to be > levels[:alert]
    end

    it 'depleted threshold is 0.0' do
      expect(levels[:depleted]).to eq(0.0)
    end
  end

  describe 'PERFORMANCE_DEGRADATION' do
    subject(:degradation) { described_class::PERFORMANCE_DEGRADATION }

    it 'contains exactly 5 levels matching FATIGUE_LEVELS' do
      expect(degradation.keys).to match_array(described_class::FATIGUE_LEVELS.keys)
    end

    it 'fresh performance is 1.0' do
      expect(degradation[:fresh]).to eq(1.0)
    end

    it 'depleted performance is lowest' do
      expect(degradation[:depleted]).to be < degradation[:exhausted]
    end

    it 'all values are between 0 and 1' do
      degradation.each_value do |v|
        expect(v).to be_between(0.0, 1.0)
      end
    end
  end

  describe 'RECOVERY_MODES' do
    it 'includes expected recovery modes' do
      expect(described_class::RECOVERY_MODES).to include(:active_rest, :light_duty, :full_rest, :sleep)
    end

    it 'has exactly 4 modes' do
      expect(described_class::RECOVERY_MODES.size).to eq(4)
    end
  end

  describe 'RECOVERY_RATES' do
    subject(:rates) { described_class::RECOVERY_RATES }

    it 'has a rate for each recovery mode' do
      described_class::RECOVERY_MODES.each do |mode|
        expect(rates).to include(mode)
      end
    end

    it 'sleep has the highest recovery rate' do
      expect(rates[:sleep]).to be > rates[:full_rest]
      expect(rates[:full_rest]).to be > rates[:light_duty]
      expect(rates[:light_duty]).to be > rates[:active_rest]
    end
  end

  describe 'thresholds' do
    it 'REST_THRESHOLD is between 0 and 1' do
      expect(described_class::REST_THRESHOLD).to be_between(0.0, 1.0)
    end

    it 'CRITICAL_THRESHOLD is below REST_THRESHOLD' do
      expect(described_class::CRITICAL_THRESHOLD).to be < described_class::REST_THRESHOLD
    end

    it 'SECOND_WIND_CHANCE is a small probability' do
      expect(described_class::SECOND_WIND_CHANCE).to be_between(0.0, 0.1)
    end

    it 'BURNOUT_THRESHOLD is a positive integer' do
      expect(described_class::BURNOUT_THRESHOLD).to be > 0
    end

    it 'MAX_HISTORY is a positive integer' do
      expect(described_class::MAX_HISTORY).to be > 0
    end
  end
end
