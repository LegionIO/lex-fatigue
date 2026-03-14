# frozen_string_literal: true

module Legion
  module Extensions
    module Fatigue
      module Runners
        module Fatigue
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def update_fatigue(tick_results: {}, **)
            result = fatigue_store.update(tick_results: tick_results)
            recommendation = fatigue_store.recommend_action

            Legion::Logging.debug "[fatigue] tick: energy=#{result[:energy]} level=#{result[:fatigue_level]} " \
                                  "perf=#{result[:performance_factor]} rec=#{recommendation}"

            {
              energy:             result[:energy],
              fatigue_level:      result[:fatigue_level],
              performance_factor: result[:performance_factor],
              recommendation:     recommendation,
              needs_rest:         result[:needs_rest],
              burnout:            result[:burnout]
            }
          end

          def energy_status(**)
            model = fatigue_store.model
            Legion::Logging.debug "[fatigue] status: energy=#{model.energy.round(3)} level=#{model.fatigue_level}"

            {
              energy:              model.energy.round(4),
              fatigue_level:       model.fatigue_level,
              performance_factor:  model.performance_factor,
              needs_rest:          model.needs_rest?,
              critically_fatigued: model.critically_fatigued?,
              burnout:             model.burnout?,
              recovery_mode:       model.recovery_mode,
              trend:               model.trend
            }
          end

          def enter_rest(mode: :full_rest, **)
            return { success: false, error: "unknown recovery mode: #{mode}" } unless Helpers::Constants::RECOVERY_MODES.include?(mode)

            fatigue_store.model.enter_recovery(mode)
            Legion::Logging.info "[fatigue] entered recovery mode=#{mode}"
            { success: true, mode: mode, energy: fatigue_store.model.energy.round(4) }
          end

          def exit_rest(**)
            fatigue_store.model.exit_recovery
            Legion::Logging.info '[fatigue] exited recovery mode'
            { success: true, energy: fatigue_store.model.energy.round(4), fatigue_level: fatigue_store.model.fatigue_level }
          end

          def energy_forecast(ticks: 50, **)
            Legion::Logging.debug "[fatigue] forecasting #{ticks} ticks"
            fatigue_store.energy_forecast(ticks: ticks)
          end

          def fatigue_stats(**)
            stats  = fatigue_store.session_stats
            model  = fatigue_store.model
            Legion::Logging.debug "[fatigue] stats: ticks=#{stats[:total_ticks]} burnout=#{stats[:burnout]}"

            {
              session:  stats,
              history:  model.history.last(10),
              trend:    model.trend,
              schedule: fatigue_store.optimal_rest_schedule
            }
          end

          private

          def fatigue_store
            @fatigue_store ||= Helpers::FatigueStore.new
          end
        end
      end
    end
  end
end
