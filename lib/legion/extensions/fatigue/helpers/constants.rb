# frozen_string_literal: true

module Legion
  module Extensions
    module Fatigue
      module Helpers
        module Constants
          MAX_ENERGY = 1.0
          MIN_ENERGY = 0.0

          RESTING_RECOVERY_RATE       = 0.02
          ACTIVE_DRAIN_RATE           = 0.01
          COGNITIVE_DRAIN_MULTIPLIER  = 1.5
          EMOTIONAL_DRAIN_MULTIPLIER  = 1.3

          FATIGUE_LEVELS = {
            fresh:     0.8,
            alert:     0.6,
            tired:     0.4,
            exhausted: 0.2,
            depleted:  0.0
          }.freeze

          PERFORMANCE_DEGRADATION = {
            fresh:     1.0,
            alert:     0.95,
            tired:     0.8,
            exhausted: 0.6,
            depleted:  0.3
          }.freeze

          RECOVERY_MODES = %i[active_rest light_duty full_rest sleep].freeze

          RECOVERY_RATES = {
            active_rest: 0.005,
            light_duty:  0.01,
            full_rest:   0.02,
            sleep:       0.05
          }.freeze

          REST_THRESHOLD      = 0.3
          CRITICAL_THRESHOLD  = 0.15
          SECOND_WIND_CHANCE  = 0.05
          BURNOUT_THRESHOLD   = 50
          MAX_HISTORY         = 100
        end
      end
    end
  end
end
