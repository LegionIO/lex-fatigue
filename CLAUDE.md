# lex-fatigue

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Cognitive fatigue modeling for the LegionIO cognitive architecture. Models how sustained cognitive effort degrades processing capacity over time and how rest restores it. Tracks energy level, computes a performance degradation factor, detects burnout risk, and generates rest recommendations. Integrates tick-by-tick cognitive load and emotional arousal to compute fatigue accumulation.

## Gem Info

- **Gem name**: `lex-fatigue`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Fatigue`
- **Location**: `extensions-agentic/lex-fatigue/`

## File Structure

```
lib/legion/extensions/fatigue/
  fatigue.rb                    # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # FATIGUE_LEVELS, REST_MODES, DECAY_RATES, performance thresholds
    fatigue_model.rb            # FatigueModel: energy tracking, degradation, recovery
  runners/
    fatigue.rb                  # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `BASE_ENERGY_DECAY` | 0.01 | Energy lost per tick at baseline |
| `COGNITIVE_LOAD_MULTIPLIER` | 0.05 | Additional energy decay per unit of cognitive load |
| `AROUSAL_MULTIPLIER` | 0.03 | Additional energy decay per unit of emotional arousal |
| `FULL_REST_RECOVERY` | 0.15 | Energy recovered per tick during full rest |
| `MICRO_REST_RECOVERY` | 0.05 | Energy recovered per tick during micro rest |
| `BURNOUT_THRESHOLD` | 0.15 | Energy below this is burnout risk |
| `REST_RECOMMENDATION_THRESHOLD` | 0.35 | Energy below which rest is recommended |
| `MAX_TICK_HISTORY` | 500 | Rolling tick result history cap |
| `FATIGUE_LEVELS` | range hash | `fresh / alert / tired / exhausted / burnout` based on energy |
| `REST_MODES` | `[:full_rest, :micro_rest, :active_recovery]` | Recovery modes |

## Runners

All methods in `Legion::Extensions::Fatigue::Runners::Fatigue`.

| Method | Key Args | Returns |
|---|---|---|
| `update_fatigue` | `tick_results: {}` | `{ success:, energy:, fatigue_level:, performance_factor:, recommendation:, burnout_risk: }` |
| `energy_status` | — | `{ success:, energy:, fatigue_level:, performance_factor:, needs_rest:, burnout_risk: }` |
| `enter_rest` | `mode: :micro_rest` | `{ success:, mode:, energy_before:, energy_after:, recovered: }` |
| `energy_forecast` | `ticks: 10` | `{ success:, forecast: [{ tick:, projected_energy:, fatigue_level: }], ...] }` |
| `performance_assessment` | — | `{ success:, performance_factor:, degradation:, fatigue_impact: }` |
| `burnout_risk_assessment` | — | `{ success:, at_risk:, energy:, ticks_until_burnout:, recommendation: }` |
| `fatigue_stats` | — | Full stats hash including session duration, peak/trough energy |

## Helpers

### `FatigueModel`
Central energy state. Attributes: `@energy` (float 0–1), `@rest_mode` (boolean), `@tick_history` (array). Key methods:
- `update(tick_results:)`: computes decay = `BASE_ENERGY_DECAY + cognitive_load * COGNITIVE_LOAD_MULTIPLIER + arousal * AROUSAL_MULTIPLIER`, deducts from energy, determines fatigue level and recommendation
- `rest(mode:)`: applies recovery based on REST_MODES rates, sets `@rest_mode`
- `performance_factor`: `1.0` when energy > 0.5, degrades linearly to 0.5 at energy = 0.0
- `forecast(ticks:)`: projects future energy trajectory from current state using current decay rate
- `fatigue_level`: maps energy to `FATIGUE_LEVELS` range
- `needs_rest?`: energy < `REST_RECOMMENDATION_THRESHOLD`
- `burnout_risk?`: energy < `BURNOUT_THRESHOLD`

## Integration Points

- `update_fatigue` called at the end of each lex-tick with the tick's cognitive_load and emotional_arousal
- `performance_factor` scales lex-tick's timing budget (fatigued agent gets longer tick window per phase)
- `energy_status[:needs_rest]` triggers lex-tick's mode transition to `:dormant` or `:dormant_active`
- `burnout_risk_assessment` feeds lex-emotion as a strong negative valence signal
- `energy_forecast` informs lex-prediction's capacity planning for scheduled tasks
- `fatigue_level` contributes to lex-executive-function's cognitive load computation

## Development Notes

- Energy is bounded [0, 1]; decay floors at 0.0 but never goes negative
- Performance factor degrades linearly below 0.5 energy — not a cliff
- `FATIGUE_LEVELS` range: `0.8–1.0 = :fresh`, `0.6–0.8 = :alert`, `0.4–0.6 = :tired`, `0.2–0.4 = :exhausted`, `0.0–0.2 = :burnout`
- Recovery modes do not cancel accumulated fatigue effects — they add positive energy increments each tick
- `energy_forecast` uses current tick's decay rate for projection — does not model varying future loads
