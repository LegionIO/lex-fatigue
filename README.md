# lex-fatigue

Cognitive fatigue modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models how sustained cognitive effort degrades processing capacity over time and how rest restores it. Tracks energy level as a continuous float (0–1), computes a performance degradation factor that scales with fatigue, detects burnout risk, and generates rest recommendations. Energy decays faster under high cognitive load and emotional arousal, and recovers during rest periods.

## Usage

```ruby
client = Legion::Extensions::Fatigue::Client.new

# Update per tick with the tick's load metrics
client.update_fatigue(tick_results: { cognitive_load: 0.7, emotional_arousal: 0.4 })
# => { energy: 0.96, fatigue_level: :fresh, performance_factor: 1.0,
#      recommendation: :continue, burnout_risk: false }

# Check current status
client.energy_status
# => { energy: 0.72, fatigue_level: :alert, performance_factor: 1.0, needs_rest: false }

# Enter recovery mode
client.enter_rest(mode: :full_rest)
# => { mode: :full_rest, energy_before: 0.35, energy_after: 0.5, recovered: 0.15 }

# Project future energy
client.energy_forecast(ticks: 50)
# => { forecast: [{ tick: 10, projected_energy: 0.62, fatigue_level: :alert }, ...] }

# Burnout risk check
client.burnout_risk_assessment
# => { at_risk: false, energy: 0.72, ticks_until_burnout: 180 }

# Session statistics
client.fatigue_stats
```

## Fatigue Levels

| Energy | Level |
|---|---|
| 0.8 – 1.0 | `:fresh` |
| 0.6 – 0.8 | `:alert` |
| 0.4 – 0.6 | `:tired` |
| 0.2 – 0.4 | `:exhausted` |
| 0.0 – 0.2 | `:burnout` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
