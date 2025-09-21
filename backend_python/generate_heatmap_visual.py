#!/usr/bin/env python3
"""Generate visual pollution heatmap for Houston area"""

import requests
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import folium
from folium import plugins
import json
import os

# Rice University location
CENTER_LAT = 29.7174
CENTER_LON = -95.4018

def fetch_heatmap_data():
    """Fetch pollution heatmap data from API"""
    params = {
        "lat": CENTER_LAT,
        "lon": CENTER_LON,
        "radius_km": 5,
        "pollutant": "aqi"
    }
    
    response = requests.get(
        "http://localhost:5001/api/run-coach/pollution-heatmap",
        params=params
    )
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to fetch data: {response.status_code}")

def create_matplotlib_heatmap(data):
    """Create a static heatmap using matplotlib and seaborn"""
    
    values = np.array(data['values'])
    
    # Create figure with better size for presentation
    plt.figure(figsize=(12, 10))
    
    # Create heatmap with custom colormap
    # Green (good) -> Yellow (moderate) -> Orange (unhealthy) -> Red (very unhealthy)
    cmap = plt.cm.RdYlGn_r  # Reversed Red-Yellow-Green colormap
    
    # Create the heatmap
    ax = sns.heatmap(
        values,
        cmap=cmap,
        vmin=0,
        vmax=150,
        cbar_kws={
            'label': 'Air Quality Index (AQI)',
            'orientation': 'vertical',
            'pad': 0.02
        },
        square=True,
        xticklabels=False,
        yticklabels=False
    )
    
    # Add title and labels
    plt.title('Air Quality Heatmap - Houston Area\n(Rice University Hackathon Demo)', 
              fontsize=16, fontweight='bold', pad=20)
    
    # Add bounds information
    bounds = data['bounds']
    plt.xlabel(f"Longitude: {bounds['min_lon']:.3f}° to {bounds['max_lon']:.3f}°", fontsize=12)
    plt.ylabel(f"Latitude: {bounds['min_lat']:.3f}° to {bounds['max_lat']:.3f}°", fontsize=12)
    
    # Add AQI level annotations
    textstr = '\n'.join([
        'AQI Levels:',
        '0-50: Good (Green)',
        '51-100: Moderate (Yellow)',
        '101-150: Unhealthy for Sensitive (Orange)',
        '>150: Unhealthy (Red)'
    ])
    props = dict(boxstyle='round', facecolor='wheat', alpha=0.8)
    ax.text(0.02, 0.98, textstr, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', bbox=props)
    
    # Add Rice University marker
    # Calculate position in grid coordinates
    rice_y = int((CENTER_LAT - bounds['min_lat']) / (bounds['max_lat'] - bounds['min_lat']) * len(values))
    rice_x = int((CENTER_LON - bounds['min_lon']) / (bounds['max_lon'] - bounds['min_lon']) * len(values[0]))
    
    # Add marker for Rice University
    ax.scatter(rice_x, rice_y, marker='*', s=500, color='blue', edgecolor='white', linewidth=2)
    ax.text(rice_x + 5, rice_y - 5, 'Rice University', fontsize=12, fontweight='bold', color='blue')
    
    plt.tight_layout()
    plt.savefig('pollution_heatmap_static.png', dpi=300, bbox_inches='tight')
    print("✅ Static heatmap saved as: pollution_heatmap_static.png")
    
    return values, bounds

def create_interactive_folium_map(data, values):
    """Create an interactive map using Folium"""
    
    bounds = data['bounds']
    
    # Create base map centered on Rice University
    m = folium.Map(
        location=[CENTER_LAT, CENTER_LON],
        zoom_start=13,
        tiles='OpenStreetMap'
    )
    
    # Prepare heat data points
    heat_data = []
    
    # Sample the grid to create heat points (sampling to avoid too many points)
    sample_rate = 3  # Take every 3rd point
    for i in range(0, len(values), sample_rate):
        for j in range(0, len(values[0]), sample_rate):
            lat = bounds['min_lat'] + (i / len(values)) * (bounds['max_lat'] - bounds['min_lat'])
            lon = bounds['min_lon'] + (j / len(values[0])) * (bounds['max_lon'] - bounds['min_lon'])
            # Normalize AQI to 0-1 for heatmap intensity
            intensity = min(values[i][j] / 150, 1.0)
            heat_data.append([lat, lon, intensity])
    
    # Add heatmap layer
    plugins.HeatMap(
        heat_data,
        min_opacity=0.3,
        max_zoom=18,
        radius=25,
        blur=15,
        gradient={
            0.0: 'green',
            0.3: 'yellow',
            0.6: 'orange',
            0.8: 'red',
            1.0: 'darkred'
        }
    ).add_to(m)
    
    # Add markers for key locations
    # Rice University
    folium.Marker(
        [CENTER_LAT, CENTER_LON],
        popup="Rice University",
        tooltip="Rice University - Clean Air Zone",
        icon=folium.Icon(color='green', icon='graduation-cap', prefix='fa')
    ).add_to(m)
    
    # Add markers for high pollution zones
    pollution_zones = [
        {"name": "I-610 West", "loc": [29.7304, -95.4248], "color": "red"},
        {"name": "US-59", "loc": [29.7404, -95.3648], "color": "orange"},
        {"name": "Industrial Area", "loc": [29.6904, -95.4148], "color": "red"},
        {"name": "Hermann Park", "loc": [29.7274, -95.3918], "color": "green"},
    ]
    
    for zone in pollution_zones:
        folium.Marker(
            zone["loc"],
            popup=zone["name"],
            tooltip=f"{zone['name']} - {'High' if zone['color'] == 'red' else 'Moderate' if zone['color'] == 'orange' else 'Clean'} AQI",
            icon=folium.Icon(color=zone["color"], icon='info-sign')
        ).add_to(m)
    
    # Add legend
    legend_html = '''
    <div style="position: fixed; 
                top: 10px; right: 10px; width: 200px; height: 180px; 
                background-color: white; z-index: 9999; font-size: 14px;
                border: 2px solid grey; border-radius: 5px; padding: 10px">
        <p style="margin: 0; font-weight: bold;">Air Quality Index (AQI)</p>
        <p style="margin: 5px 0;"><span style="color: green;">●</span> 0-50: Good</p>
        <p style="margin: 5px 0;"><span style="color: gold;">●</span> 51-100: Moderate</p>
        <p style="margin: 5px 0;"><span style="color: orange;">●</span> 101-150: Unhealthy for Sensitive</p>
        <p style="margin: 5px 0;"><span style="color: red;">●</span> >150: Unhealthy</p>
        <hr style="margin: 10px 0;">
        <p style="margin: 0; font-size: 12px;"><i>HealthMap AI Run Coach</i></p>
    </div>
    '''
    m.get_root().html.add_child(folium.Element(legend_html))
    
    # Save map
    m.save('pollution_heatmap_interactive.html')
    print("✅ Interactive map saved as: pollution_heatmap_interactive.html")
    
    return m

def create_3d_surface_plot(values, bounds):
    """Create a 3D surface plot of pollution levels"""
    try:
        import plotly.graph_objects as go
        
        # Create coordinate grids
        lat_range = np.linspace(bounds['min_lat'], bounds['max_lat'], len(values))
        lon_range = np.linspace(bounds['min_lon'], bounds['max_lon'], len(values[0]))
        
        # Create 3D surface plot
        fig = go.Figure(data=[go.Surface(
            z=values,
            x=lon_range,
            y=lat_range,
            colorscale='RdYlGn_r',
            cmin=0,
            cmax=150,
            colorbar=dict(title="AQI", tickmode="linear", tick0=0, dtick=25),
            name='AQI'
        )])
        
        # Update layout
        fig.update_layout(
            title={
                'text': 'Houston Air Quality 3D Visualization<br><sub>HealthMap AI Run Coach Demo</sub>',
                'x': 0.5,
                'xanchor': 'center',
                'font': {'size': 20}
            },
            autosize=True,
            width=1000,
            height=800,
            scene=dict(
                xaxis_title='Longitude',
                yaxis_title='Latitude',
                zaxis_title='Air Quality Index',
                camera=dict(
                    eye=dict(x=1.5, y=1.5, z=1.5)
                )
            )
        )
        
        # Add annotation for Rice University
        fig.add_trace(go.Scatter3d(
            x=[CENTER_LON],
            y=[CENTER_LAT],
            z=[150],  # Place marker above surface
            mode='markers+text',
            marker=dict(size=10, color='blue'),
            text=['Rice University'],
            textposition='top center',
            name='Rice University'
        ))
        
        fig.write_html('pollution_heatmap_3d.html')
        print("✅ 3D visualization saved as: pollution_heatmap_3d.html")
        
    except ImportError:
        print("⚠️  Plotly not installed. Skipping 3D visualization.")

def main():
    print("🌡️  Generating Air Quality Visualizations for Houston...\n")
    
    try:
        # Fetch data
        print("Fetching pollution data...")
        data = fetch_heatmap_data()
        
        # Create static heatmap
        print("\nCreating static heatmap with matplotlib...")
        values, bounds = create_matplotlib_heatmap(data)
        
        # Create interactive map
        print("\nCreating interactive map with Folium...")
        create_interactive_folium_map(data, values)
        
        # Create 3D visualization
        print("\nCreating 3D surface plot with Plotly...")
        create_3d_surface_plot(values, bounds)
        
        print("\n🎉 All visualizations created successfully!")
        print("\nGenerated files:")
        print("  📊 pollution_heatmap_static.png - High-resolution static heatmap")
        print("  🗺️  pollution_heatmap_interactive.html - Interactive map with markers")
        print("  📈 pollution_heatmap_3d.html - 3D surface visualization")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()