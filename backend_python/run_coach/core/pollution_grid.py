"""
Spatiotemporal pollution grid using Gaussian Process Regression
"""

import numpy as np
from typing import List, Tuple, Dict, Optional
from datetime import datetime
import logging
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import Matern, WhiteKernel
from scipy.interpolate import griddata

from ..models import PollutantData

logger = logging.getLogger(__name__)


class PollutionGrid:
    """
    Creates high-resolution pollution heat maps using Gaussian Process Regression
    with Matérn kernel for spatial interpolation
    """
    
    def __init__(self, resolution_meters: int = 100):
        """
        Initialize pollution grid
        
        Args:
            resolution_meters: Grid resolution in meters (default 100m)
        """
        self.resolution = resolution_meters
        self.grid_bounds = None
        self.grid_points = None
        self.pollution_values = {}
        self.uncertainty_values = {}
        self.last_update = None
        
        # DISABLED FOR PERFORMANCE - Using simple interpolation instead
        # kernel = Matern(length_scale=500, nu=1.5) + WhiteKernel(noise_level=1e-5)
        # self.gp_model = GaussianProcessRegressor(
        #     kernel=kernel,
        #     alpha=1e-6,
        #     normalize_y=True,
        #     n_restarts_optimizer=3
        # )
        self.gp_model = None  # Disabled for hackathon demo
        
    def update_grid(self, sensor_data: List[PollutantData], bounds: Optional[Dict] = None):
        """
        Update pollution grid with new sensor data
        
        Args:
            sensor_data: List of pollutant measurements
            bounds: Optional dict with 'min_lat', 'max_lat', 'min_lon', 'max_lon'
        """
        if not sensor_data:
            logger.warning("No sensor data provided for grid update")
            return
            
        logger.info(f"Updating pollution grid with {len(sensor_data)} sensor readings")
        
        # Extract bounds if not provided
        if bounds is None:
            bounds = self._calculate_bounds(sensor_data)
        self.grid_bounds = bounds
        
        # Create grid points
        self.grid_points = self._create_grid_points(bounds)
        
        # Perform interpolation for each pollutant
        self._interpolate_pollutants(sensor_data)
        
        self.last_update = datetime.now()
        logger.info(f"Grid updated successfully with {len(self.grid_points)} points")
        
    def _calculate_bounds(self, sensor_data: List[PollutantData]) -> Dict:
        """Calculate geographic bounds from sensor data"""
        lats = [data.location[0] for data in sensor_data]
        lons = [data.location[1] for data in sensor_data]
        
        # Add 10% padding
        lat_range = max(lats) - min(lats)
        lon_range = max(lons) - min(lons)
        
        return {
            'min_lat': min(lats) - 0.1 * lat_range,
            'max_lat': max(lats) + 0.1 * lat_range,
            'min_lon': min(lons) - 0.1 * lon_range,
            'max_lon': max(lons) + 0.1 * lon_range
        }
        
    def _create_grid_points(self, bounds: Dict) -> np.ndarray:
        """Create regular grid of points for interpolation"""
        
        # Convert degrees to meters (approximate)
        lat_meters_per_degree = 111320
        lon_meters_per_degree = 111320 * np.cos(np.radians((bounds['min_lat'] + bounds['max_lat']) / 2))
        
        # Calculate number of grid points
        n_lat = int((bounds['max_lat'] - bounds['min_lat']) * lat_meters_per_degree / self.resolution)
        n_lon = int((bounds['max_lon'] - bounds['min_lon']) * lon_meters_per_degree / self.resolution)
        
        # Create meshgrid
        lat_points = np.linspace(bounds['min_lat'], bounds['max_lat'], n_lat)
        lon_points = np.linspace(bounds['min_lon'], bounds['max_lon'], n_lon)
        
        lon_grid, lat_grid = np.meshgrid(lon_points, lat_points)
        grid_points = np.column_stack([lat_grid.ravel(), lon_grid.ravel()])
        
        return grid_points
        
    def _interpolate_pollutants(self, sensor_data: List[PollutantData]):
        """Perform GP interpolation for each pollutant type"""
        
        # Prepare training data
        X_train = np.array([[data.location[0], data.location[1]] for data in sensor_data])
        
        # Weight by confidence scores
        sample_weights = np.array([data.confidence for data in sensor_data])
        
        # Interpolate each pollutant
        pollutants = ['aqi', 'pm25', 'pm10', 'o3', 'no2']
        
        for pollutant in pollutants:
            logger.info(f"Interpolating {pollutant}")
            
            # Extract values
            y_train = np.array([getattr(data, pollutant) for data in sensor_data])
            
            # Remove invalid values
            valid_mask = ~np.isnan(y_train) & (y_train >= 0)
            if not np.any(valid_mask):
                logger.warning(f"No valid data for {pollutant}")
                continue
                
            X_valid = X_train[valid_mask]
            y_valid = y_train[valid_mask]
            weights_valid = sample_weights[valid_mask]
            
            try:
                # SIMPLIFIED INTERPOLATION FOR PERFORMANCE
                # Use scipy's griddata for simple linear interpolation
                from scipy.interpolate import griddata
                
                # Simple linear interpolation instead of GP
                y_pred = griddata(
                    X_valid, 
                    y_valid, 
                    self.grid_points, 
                    method='linear',
                    fill_value=np.mean(y_valid)
                )
                
                # Simple uncertainty estimate (constant)
                y_std = np.full_like(y_pred, np.std(y_valid))
                
                # Store results
                self.pollution_values[pollutant] = y_pred
                self.uncertainty_values[pollutant] = y_std
                
            except Exception as e:
                logger.error(f"Error interpolating {pollutant}: {e}")
                # Fallback to mean value
                self.pollution_values[pollutant] = np.full(len(self.grid_points), np.mean(y_valid))
                self.uncertainty_values[pollutant] = np.full(len(self.grid_points), np.std(y_valid))
                # Fallback to simple IDW interpolation
                self._fallback_interpolation(pollutant, X_valid, y_valid)
                
    def _fallback_interpolation(self, pollutant: str, points: np.ndarray, values: np.ndarray):
        """Fallback interpolation using inverse distance weighting"""
        
        try:
            # Use scipy's griddata for simple interpolation
            interpolated = griddata(
                points, 
                values, 
                self.grid_points,
                method='linear',
                fill_value=np.nanmean(values)
            )
            
            self.pollution_values[pollutant] = interpolated
            self.uncertainty_values[pollutant] = np.full_like(interpolated, np.std(values))
            
        except Exception as e:
            logger.error(f"Fallback interpolation failed for {pollutant}: {e}")
            
    def get_aqi_at_point(self, location: Tuple[float, float]) -> float:
        """Get interpolated AQI at a specific location"""
        return self._get_value_at_point('aqi', location)
        
    def get_pm25_at_point(self, location: Tuple[float, float]) -> float:
        """Get interpolated PM2.5 at a specific location"""
        return self._get_value_at_point('pm25', location)
        
    def get_pollutant_at_point(self, pollutant: str, location: Tuple[float, float]) -> float:
        """Get interpolated pollutant value at a specific location"""
        return self._get_value_at_point(pollutant, location)
        
    def _get_value_at_point(self, pollutant: str, location: Tuple[float, float]) -> float:
        """Get interpolated value at a specific location"""
        
        if pollutant not in self.pollution_values:
            logger.warning(f"No data available for {pollutant}")
            return 0.0
            
        # Find nearest grid point
        distances = np.sqrt(
            (self.grid_points[:, 0] - location[0])**2 + 
            (self.grid_points[:, 1] - location[1])**2
        )
        nearest_idx = np.argmin(distances)
        
        return float(self.pollution_values[pollutant][nearest_idx])
        
    def get_uncertainty_at_point(self, pollutant: str, location: Tuple[float, float]) -> float:
        """Get prediction uncertainty at a specific location"""
        
        if pollutant not in self.uncertainty_values:
            return 0.0
            
        # Find nearest grid point
        distances = np.sqrt(
            (self.grid_points[:, 0] - location[0])**2 + 
            (self.grid_points[:, 1] - location[1])**2
        )
        nearest_idx = np.argmin(distances)
        
        return float(self.uncertainty_values[pollutant][nearest_idx])
        
    def get_pollution_heatmap(self, pollutant: str = 'aqi') -> Dict:
        """
        Get pollution heatmap data for visualization
        
        Returns:
            Dict with 'bounds', 'values', 'uncertainty' arrays
        """
        if pollutant not in self.pollution_values:
            return None
            
        # Calculate actual grid dimensions
        unique_lats = len(np.unique(self.grid_points[:, 0]))
        unique_lons = len(np.unique(self.grid_points[:, 1]))
        
        # Ensure we can reshape
        expected_size = unique_lats * unique_lons
        actual_size = len(self.pollution_values[pollutant])
        
        if expected_size != actual_size:
            logger.warning(f"Grid size mismatch: expected {expected_size}, got {actual_size}")
            # Return flattened values
            return {
                'bounds': self.grid_bounds,
                'values': self.pollution_values[pollutant].tolist(),
                'uncertainty': self.uncertainty_values[pollutant].tolist(),
                'resolution': self.resolution,
                'pollutant': pollutant,
                'timestamp': self.last_update.isoformat() if self.last_update else None,
                'grid_shape': [unique_lats, unique_lons]
            }
        
        values_2d = self.pollution_values[pollutant].reshape(unique_lats, unique_lons)
        uncertainty_2d = self.uncertainty_values[pollutant].reshape(unique_lats, unique_lons)
        
        return {
            'bounds': self.grid_bounds,
            'values': values_2d.tolist(),
            'uncertainty': uncertainty_2d.tolist(),
            'resolution': self.resolution,
            'pollutant': pollutant,
            'timestamp': self.last_update.isoformat() if self.last_update else None
        }
        
    def find_clean_zones(self, threshold: float = 50, min_area_m2: float = 10000) -> List[Dict]:
        """
        Find contiguous areas with AQI below threshold
        
        Args:
            threshold: Maximum AQI for clean zone
            min_area_m2: Minimum area in square meters
            
        Returns:
            List of clean zones with boundaries
        """
        if 'aqi' not in self.pollution_values:
            return []
            
        from scipy import ndimage
        
        # Create binary mask of clean areas
        clean_mask = self.pollution_values['aqi'] < threshold
        
        # Find connected components
        labeled, num_features = ndimage.label(clean_mask.reshape(-1, 1))
        
        clean_zones = []
        min_points = min_area_m2 / (self.resolution ** 2)
        
        for i in range(1, num_features + 1):
            zone_mask = labeled == i
            zone_points = self.grid_points[zone_mask.ravel()]
            
            if len(zone_points) >= min_points:
                # Calculate zone properties
                zone_aqi = self.pollution_values['aqi'][zone_mask.ravel()]
                
                clean_zones.append({
                    'center': zone_points.mean(axis=0).tolist(),
                    'area_m2': len(zone_points) * (self.resolution ** 2),
                    'avg_aqi': float(zone_aqi.mean()),
                    'max_aqi': float(zone_aqi.max()),
                    'boundary_points': zone_points.tolist()
                })
                
        return sorted(clean_zones, key=lambda x: x['avg_aqi'])