# JuliaGrid Web Interface 🌐

An intuitive web-based user interface for JuliaGrid.jl that makes power system analysis accessible through your browser.

## ✨ Features

- **Modern Web Interface**: Clean, responsive design built with Bootstrap
- **Example Systems**: Pre-configured IEEE and 4-bus test systems
- **Power Flow Analysis**: AC and DC power flow with Newton-Raphson solver
- **Real-time Results**: Interactive tables and status displays
- **Easy to Use**: No complex setup - just run and open in browser
- **RESTful API**: Backend API for programmatic access

## 🚀 Quick Start

### Option 1: Using the Launcher Script
```bash
# Navigate to JuliaGrid directory
cd JuliaGrid.jl/

# Start the web interface
julia ui.jl

# Open your browser to http://127.0.0.1:8080
```

### Option 2: Programmatic Start
```julia
using JuliaGrid

# Start on default port (8080)
start_ui()

# Or specify custom port and host
start_ui(3000, "0.0.0.0")
```

## 📱 Using the Interface

1. **Load a System**: Select an example system from the sidebar dropdown
2. **Run Analysis**: Click "AC Power Flow" or "DC Power Flow" buttons  
3. **View Results**: Analysis results appear in the main panel with tables
4. **Switch Systems**: Load different systems and compare results

## 🔧 Available Systems

- **Simple 4-bus System**: Basic demonstration system with 4 buses and 4 branches
- **IEEE System**: Simplified IEEE-based system with 8 buses and 6 branches

## 📊 Analysis Types

- **AC Power Flow**: Full AC analysis using Newton-Raphson method
- **DC Power Flow**: Linear DC approximation for quick analysis
- **State Estimation**: Coming soon

## 🛠️ Technical Details

- **Backend**: HTTP.jl server with JSON API
- **Frontend**: Bootstrap 5 with vanilla JavaScript
- **Data Format**: JSON for all API communications
- **Port**: Default 8080 (configurable)

## 📋 API Endpoints

- `GET /` - Main web interface
- `POST /api/system/example/{name}` - Load example system
- `POST /api/analysis/powerflow` - Run power flow analysis
- `GET /api/system/status` - Get current system status

## 🧪 Testing

Run the comprehensive demo to test all features:
```bash
julia demo_ui.jl
```

This will automatically test:
- Web interface accessibility
- System loading functionality  
- AC and DC power flow analysis
- API response validation

## 🔒 Security Note

The web interface is designed for local use and development. For production deployment, consider adding authentication and security measures.

## 📄 License

Same as JuliaGrid.jl - MIT License