# frozen_string_literal: true

module Legion
  module Extensions
    module Fatigue
      module Helpers
        class EnergyModel
          include Constants

          attr_reader :energy, :fatigue_level, :ticks_active, :ticks_resting,
                      :consecutive_low_ticks, :burnout, :recovery_mode,
                      :peak_energy, :history

          def initialize
            @energy                 = Constants::MAX_ENERGY
            @fatigue_level          = :fresh
            @ticks_active           = 0
            @ticks_resting          = 0
            @consecutive_low_ticks  = 0
            @burnout                = false
            @recovery_mode          = nil
            @peak_energy            = Constants::MAX_ENERGY
            @history                = []
          end

          def tick(cognitive_load: 0.5, emotional_arousal: 0.5, is_resting: false)
            if is_resting
              recover
              @ticks_resting += 1
              @consecutive_low_ticks = 0
            else
              drain(cognitive_load, emotional_arousal)
              @ticks_active += 1
              check_second_wind
            end

            @energy = @energy.clamp(Constants::MIN_ENERGY, Constants::MAX_ENERGY)
            @peak_energy = @energy if @energy > @peak_energy
            classify_fatigue
            track_low_ticks
            check_burnout
            record_snapshot

            to_h
          end

          def performance_factor
            Constants::PERFORMANCE_DEGRADATION[@fatigue_level]
          end

          def needs_rest?
            @energy < Constants::REST_THRESHOLD
          end

          def critically_fatigued?
            @energy < Constants::CRITICAL_THRESHOLD
          end

          def burnout?
            @burnout
          end

          def enter_recovery(mode)
            return unless Constants::RECOVERY_MODES.include?(mode)

            @recovery_mode = mode
          end

          def exit_recovery
            @recovery_mode = nil
          end

          def time_to_rest_threshold
            return 0 if needs_rest?

            current_drain = effective_drain(0.5, 0.5)
            return Float::INFINITY if current_drain <= 0.0

            ((@energy - Constants::REST_THRESHOLD) / current_drain).ceil
          end

          def time_to_full_recovery
            rate = @recovery_mode ? Constants::RECOVERY_RATES[@recovery_mode] : Constants::RESTING_RECOVERY_RATE
            return 0 if @energy >= Constants::MAX_ENERGY
            return Float::INFINITY if rate <= 0.0

            ((Constants::MAX_ENERGY - @energy) / rate).ceil
          end

          def trend
            return :stable if @history.size < 5

            recent = @history.last(5).map { |s| s[:energy] }
            delta = recent.last - recent.first
            if delta > 0.01
              :recovering
            elsif delta < -0.01
              :draining
            else
              :stable
            end
          end

          def to_h
            {
              energy:                @energy.round(4),
              fatigue_level:         @fatigue_level,
              performance_factor:    performance_factor,
              needs_rest:            needs_rest?,
              critically_fatigued:   critically_fatigued?,
              burnout:               @burnout,
              recovery_mode:         @recovery_mode,
              peak_energy:           @peak_energy.round(4),
              ticks_active:          @ticks_active,
              ticks_resting:         @ticks_resting,
              consecutive_low_ticks: @consecutive_low_ticks,
              trend:                 trend,
              history_size:          @history.size
            }
          end

          private

          def effective_drain(cognitive_load, emotional_arousal)
            cognitive_factor  = 1.0 + ((cognitive_load - 0.5) * Constants::COGNITIVE_DRAIN_MULTIPLIER)
            emotional_factor  = 1.0 + ([0.0, emotional_arousal - 0.5].max * Constants::EMOTIONAL_DRAIN_MULTIPLIER)
            Constants::ACTIVE_DRAIN_RATE * cognitive_factor * emotional_factor
          end

          def drain(cognitive_load, emotional_arousal)
            @energy -= effective_drain(cognitive_load, emotional_arousal)
          end

          def recover
            rate = @recovery_mode ? Constants::RECOVERY_RATES[@recovery_mode] : Constants::RESTING_RECOVERY_RATE
            @energy += rate
          end

          def classify_fatigue
            @fatigue_level = Constants::FATIGUE_LEVELS.each_key.find do |level|
              @energy >= Constants::FATIGUE_LEVELS[level]
            end || :depleted
          end

          def track_low_ticks
            if needs_rest?
              @consecutive_low_ticks += 1
            else
              @consecutive_low_ticks = 0
            end
          end

          def check_second_wind
            return unless @fatigue_level == :tired
            return unless rand < Constants::SECOND_WIND_CHANCE

            @energy = [@energy + 0.1, Constants::MAX_ENERGY].min
          end

          def check_burnout
            @burnout = true if @consecutive_low_ticks > Constants::BURNOUT_THRESHOLD
          end

          def record_snapshot
            @history << {
              energy:        @energy.round(4),
              fatigue_level: @fatigue_level,
              performance:   performance_factor,
              at:            Time.now.utc
            }
            @history.shift if @history.size > Constants::MAX_HISTORY
          end
        end
      end
    end
  end
end
