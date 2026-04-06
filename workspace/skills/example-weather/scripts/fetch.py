#!/usr/bin/env python3
"""
Fetch weather data from OpenWeatherMap API
"""
import argparse
import json
import os
import sys

def main():
    parser = argparse.ArgumentParser(description='Fetch weather data')
    parser.add_argument('--city', '-c', required=True, help='City name')
    parser.add_argument('--forecast', '-f', action='store_true', help='Get 5-day forecast')
    parser.add_argument('--units', '-u', default='metric', choices=['metric', 'imperial'], 
                       help='Temperature units')
    parser.add_argument('--output', '-o', help='Output file (default: stdout)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Get API key
    api_key = os.getenv('WEATHER_API_KEY')
    if not api_key:
        print("Error: WEATHER_API_KEY not set", file=sys.stderr)
        print("Get one at: https://openweathermap.org/api", file=sys.stderr)
        sys.exit(1)
    
    if args.verbose:
        print(f"Fetching weather for: {args.city}")
        print(f"Forecast: {args.forecast}")
        print(f"Units: {args.units}")
    
    # Simulated API call (replace with real implementation)
    result = {
        "city": args.city,
        "temperature": 22 if args.units == 'metric' else 72,
        "condition": "Sunny",
        "humidity": 45,
        "wind_speed": 12,
        "forecast": args.forecast,
        "units": args.units
    }
    
    # Output
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Result saved to {args.output}")
    else:
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
