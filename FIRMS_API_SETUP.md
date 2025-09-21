# NASA FIRMS API Setup

The wildfire service now uses the updated NASA FIRMS API v4, which requires a free MAP_KEY for access.

## Getting Your FIRMS MAP_KEY

1. Visit: https://firms.modaps.eosdis.nasa.gov/api/
2. Click "Get MAP_KEY" 
3. Fill out the simple registration form (name, email, intended use)
4. You'll receive your MAP_KEY via email instantly

## Configuration

Add your MAP_KEY to your environment variables:

```bash
# In your .env file or environment
FIRMS_MAP_KEY=your_map_key_here
```

## API Details

- **Base URL**: `https://firms.modaps.eosdis.nasa.gov/api/area/csv`
- **Format**: `/api/area/csv/[MAP_KEY]/[SOURCE]/[AREA_COORDINATES]/[DAY_RANGE]`
- **Data Sources**: 
  - `VIIRS_SNPP_NRT` (primary - better coverage)
  - `MODIS_NRT` (fallback)
  - `VIIRS_NOAA20_NRT` (alternative)

## Fallback Behavior

If no MAP_KEY is configured, the service will:
1. Log a warning about missing MAP_KEY
2. Fall back to USGS wildfire data automatically
3. Continue to provide wildfire information (with potentially less coverage)

## Rate Limits

- Free MAP_KEY includes generous rate limits
- Perfect for development and production use
- No cost for standard usage

## Data Coverage

- **VIIRS**: Higher resolution, more frequent updates
- **MODIS**: Broader coverage, well-established
- **USGS**: Alternative source for US wildfires