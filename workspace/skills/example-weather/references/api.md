# OpenWeatherMap API Reference

## Endpoints

### Current Weather
```
GET https://api.openweathermap.org/data/2.5/weather
```

Parameters:
- `q` - City name (required)
- `appid` - API key (required)
- `units` - metric/imperial (optional, default: metric)
- `lang` - Language code (optional)

### 5-Day Forecast
```
GET https://api.openweathermap.org/data/2.5/forecast
```

Same parameters as current weather.

## Response Format

```json
{
  "coord": {"lon": 13.41, "lat": 52.52},
  "weather": [{"main": "Clear", "description": "clear sky"}],
  "main": {
    "temp": 22.5,
    "feels_like": 21.8,
    "temp_min": 20.1,
    "temp_max": 24.2,
    "pressure": 1015,
    "humidity": 45
  },
  "wind": {"speed": 3.5, "deg": 120},
  "clouds": {"all": 0},
  "name": "Berlin"
}
```

## Rate Limits

- Free tier: 60 calls/minute
- Paid tiers: Higher limits available

## Error Codes

- 401: Invalid API key
- 404: City not found
- 429: Rate limit exceeded
