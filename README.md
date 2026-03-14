# lex-fatigue

Cognitive fatigue modeling for LegionIO brain-modeled agentic AI.

Models how processing capacity degrades over sustained effort and recovers through rest. Provides energy management, performance degradation tracking, burnout detection, and recovery scheduling.

## Installation

Add to your Gemfile:

```ruby
gem 'lex-fatigue'
```

## Usage

```ruby
client = Legion::Extensions::Fatigue::Client.new

# Update per tick
result = client.update_fatigue(tick_results: { cognitive_load: 0.7, emotional_arousal: 0.4 })
# => { energy: 0.99, fatigue_level: :fresh, performance_factor: 1.0, recommendation: :continue, ... }

# Check current status
status = client.energy_status
# => { energy: 0.72, fatigue_level: :alert, performance_factor: 0.95, needs_rest: false, ... }

# Enter recovery mode
client.enter_rest(mode: :full_rest)

# Get forecast
forecast = client.energy_forecast(ticks: 50)

# Session statistics
stats = client.fatigue_stats
```

## License

MIT
