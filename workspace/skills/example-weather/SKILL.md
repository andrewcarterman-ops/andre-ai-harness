---
name: example-weather
description: Fetch weather data from external APIs. Use when: (1) checking current weather, (2) getting weather forecasts, (3) comparing weather across locations.
---

# Example Weather Tool

A demonstration tool showing how to use Mission Control templates.

## Usage

### Current Weather

```bash
python scripts/fetch.py --city "Berlin"
```

### 5-Day Forecast

```bash
python scripts/fetch.py --city "Berlin" --forecast
```

### Multiple Cities

```bash
python scripts/batch.py --cities "Berlin,London,Paris"
```

## Configuration

Set your OpenWeatherMap API key:

```bash
export WEATHER_API_KEY="your-api-key"
```

Or create a `.env` file:
```
WEATHER_API_KEY=your-api-key
```

## Example Output

```json
{
  "city": "Berlin",
  "temperature": 22,
  "condition": "Sunny",
  "humidity": 45,
  "wind_speed": 12
}
```

## References

- `references/api.md` - OpenWeatherMap API documentation
- `references/examples.md` - More usage examples
- `references/config.md` - Configuration options
