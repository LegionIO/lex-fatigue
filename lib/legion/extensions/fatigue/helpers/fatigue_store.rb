# frozen_string_literal: true

module Legion
  module Extensions
    module Fatigue
      module Helpers
        class FatigueStore
          include Constants

          attr_reader :model, :session_start, :peak_performance_streak,
                      :total_rest_ticks, :total_active_ticks

          def initialize(model: nil)
            @model                  = model || EnergyModel.new
            @session_start          = Time.now.utc
            @peak_performance_streak = 0
            @total_rest_ticks       = 0
            @total_active_ticks     = 0
            @current_streak         = 0
          end

          def update(tick_results: {})
            cognitive_load    = tick_results[:cognitive_load] || 0.5
            emotional_arousal = tick_results[:emotional_arousal] || 0.5
            is_resting        = tick_results[:mode] == :resting || !@model.recovery_mode.nil?

            result = @model.tick(
              cognitive_load:    cognitive_load,
              emotional_arousal: emotional_arousal,
              is_resting:        is_resting
            )

            if is_resting
              @total_rest_ticks += 1
            else
              @total_active_ticks += 1
            end

            update_streak(result[:performance_factor])
            result
          end

          def recommend_action
            energy = @model.energy

            if @model.burnout?
              :emergency_shutdown
            elsif energy < Constants::CRITICAL_THRESHOLD
              :enter_rest
            elsif @model.needs_rest?
              :take_break
            elsif @model.fatigue_level == :tired
              :reduce_load
            else
              :continue
            end
          end

          def session_stats
            total_ticks = @total_active_ticks + @total_rest_ticks
            duration = Time.now.utc - @session_start

            {
              duration_seconds:        duration.round(2),
              total_ticks:             total_ticks,
              active_ticks:            @total_active_ticks,
              rest_ticks:              @total_rest_ticks,
              active_ratio:            total_ticks.positive? ? (@total_active_ticks.to_f / total_ticks).round(4) : 0.0,
              current_energy:          @model.energy.round(4),
              fatigue_level:           @model.fatigue_level,
              burnout:                 @model.burnout?,
              peak_performance_streak: @peak_performance_streak
            }
          end

          def energy_forecast(ticks:)
            current    = @model.energy
            drain_rate = Constants::ACTIVE_DRAIN_RATE
            projected  = []

            ticks.times do |i|
              projected_energy = (current - (drain_rate * (i + 1))).clamp(Constants::MIN_ENERGY, Constants::MAX_ENERGY)
              level = classify_level(projected_energy)
              projected << {
                tick:          i + 1,
                energy:        projected_energy.round(4),
                fatigue_level: level
              }
            end

            {
              current_energy: current.round(4),
              forecast:       projected,
              ticks_to_rest:  @model.time_to_rest_threshold
            }
          end

          def optimal_rest_schedule
            ticks_until_rest = @model.time_to_rest_threshold
            ticks_to_recover = @model.time_to_full_recovery

            {
              recommend_rest_in:   ticks_until_rest,
              full_recovery_ticks: ticks_to_recover,
              current_energy:      @model.energy.round(4),
              recommended_mode:    suggest_recovery_mode,
              trend:               @model.trend
            }
          end

          private

          def classify_level(energy)
            Constants::FATIGUE_LEVELS.each_key.find do |level|
              energy >= Constants::FATIGUE_LEVELS[level]
            end || :depleted
          end

          def update_streak(performance_factor)
            if performance_factor >= Constants::PERFORMANCE_DEGRADATION[:fresh]
              @current_streak += 1
              @peak_performance_streak = @current_streak if @current_streak > @peak_performance_streak
            else
              @current_streak = 0
            end
          end

          def suggest_recovery_mode
            energy = @model.energy
            if energy < Constants::CRITICAL_THRESHOLD
              :sleep
            elsif energy < Constants::REST_THRESHOLD
              :full_rest
            else
              :active_rest
            end
          end
        end
      end
    end
  end
end
