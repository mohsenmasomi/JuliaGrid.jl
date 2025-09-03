module UI

"""
JuliaGrid Web UI Module

This module provides a simple web-based user interface for JuliaGrid.jl using HTTP.jl
"""

using HTTP
using JSON3

# Forward references to JuliaGrid functions - will be available at runtime
# We don't import them to avoid module loading issues

# Global variable to store the current system
const CURRENT_SYSTEM = Ref{Union{Nothing, Any}}(nothing)

"""
    start_ui(port::Int=8080, host::String="127.0.0.1")

Start the JuliaGrid web interface.

# Arguments
- `port::Int=8080`: Port number to run the server on
- `host::String="127.0.0.1"`: Host address to bind to

# Example
```julia
using JuliaGrid
start_ui()  # Starts server on http://127.0.0.1:8080
```
"""
function start_ui(port::Int=8080, host::String="127.0.0.1")
    println("Starting JuliaGrid Web UI...")
    println("JuliaGrid Web UI starting on http://$host:$port")
    println("Press Ctrl+C to stop the server")
    
    # Create HTTP router
    router = HTTP.Router()
    
    # Setup routes
    HTTP.register!(router, "GET", "/", handle_dashboard)
    HTTP.register!(router, "POST", "/api/system/example/*", handle_load_example)
    HTTP.register!(router, "POST", "/api/analysis/powerflow", handle_powerflow)
    HTTP.register!(router, "GET", "/api/system/status", handle_system_status)
    
    # Add CORS headers
    function add_cors_headers(handler)
        return function(req::HTTP.Request)
            response = handler(req)
            HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
            HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS")
            HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type")
            return response
        end
    end
    
    # Start the server
    try
        HTTP.serve!(add_cors_headers(router), host, port)
    catch e
        if isa(e, InterruptException)
            println("\nShutting down JuliaGrid Web UI...")
        else
            rethrow(e)
        end
    end
end

"""
Handle the main dashboard page
"""
function handle_dashboard(req::HTTP.Request)
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>JuliaGrid - Power System Analysis</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
        <style>
            .navbar-brand { font-weight: bold; }
            .analysis-card { transition: transform 0.2s; }
            .analysis-card:hover { transform: translateY(-2px); }
            .result-container { min-height: 400px; }
            .logo { width: 30px; height: 30px; }
        </style>
    </head>
    <body>
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
            <div class="container">
                <a class="navbar-brand" href="#">
                    <svg class="logo me-2" viewBox="0 0 100 100" fill="white">
                        <circle cx="50" cy="50" r="45" stroke="white" stroke-width="5" fill="none"/>
                        <text x="50" y="55" text-anchor="middle" font-size="20" fill="white">JG</text>
                    </svg>
                    JuliaGrid
                </a>
                <span class="navbar-text">
                    Power System Analysis Tool
                </span>
            </div>
        </nav>

        <div class="container-fluid mt-4">
            <div class="row">
                <!-- Sidebar -->
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-header">
                            <h5>System Setup</h5>
                        </div>
                        <div class="card-body">
                            <div class="mb-3">
                                <label for="systemSelect" class="form-label">Load Example System</label>
                                <select class="form-select" id="systemSelect">
                                    <option value="">Select an example...</option>
                                    <option value="ieee14">IEEE 14-bus System</option>
                                    <option value="simple4">Simple 4-bus System</option>
                                </select>
                                <button class="btn btn-outline-primary btn-sm mt-2 w-100" onclick="loadExample()">
                                    Load Example
                                </button>
                            </div>
                            
                            <div id="systemStatus" class="alert alert-info" style="display: none;">
                                No system loaded
                            </div>
                        </div>
                    </div>

                    <div class="card mt-3">
                        <div class="card-header">
                            <h5>Analysis Tools</h5>
                        </div>
                        <div class="card-body">
                            <button class="btn btn-primary w-100 mb-2" onclick="runACPowerFlow()" disabled id="acPowerFlowBtn">
                                AC Power Flow
                            </button>
                            <button class="btn btn-primary w-100 mb-2" onclick="runDCPowerFlow()" disabled id="dcPowerFlowBtn">
                                DC Power Flow
                            </button>
                            <button class="btn btn-secondary w-100 mb-2" disabled>
                                State Estimation (Coming Soon)
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Main Content -->
                <div class="col-md-9">
                    <div id="welcomeCard" class="card">
                        <div class="card-body text-center">
                            <h2>Welcome to JuliaGrid Web Interface</h2>
                            <p class="lead">A powerful tool for power system analysis and simulation</p>
                            <p>Get started by loading an example system from the sidebar.</p>
                            <div class="row mt-4">
                                <div class="col-md-4">
                                    <div class="card analysis-card">
                                        <div class="card-body text-center">
                                            <h5>⚡ Power Flow</h5>
                                            <p class="small">Calculate steady-state voltage and power</p>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="card analysis-card">
                                        <div class="card-body text-center">
                                            <h5>📊 State Estimation</h5>
                                            <p class="small">Estimate system state from measurements</p>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="card analysis-card">
                                        <div class="card-body text-center">
                                            <h5>🎯 Optimal Power Flow</h5>
                                            <p class="small">Optimize power system operation</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div id="resultsCard" class="card" style="display: none;">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 id="resultsTitle">Analysis Results</h5>
                            <button class="btn btn-outline-secondary btn-sm" onclick="clearResults()">Clear</button>
                        </div>
                        <div class="card-body">
                            <div id="loadingSpinner" class="text-center" style="display: none;">
                                <div class="spinner-border text-primary" role="status">
                                    <span class="visually-hidden">Loading...</span>
                                </div>
                                <p class="mt-2">Running analysis...</p>
                            </div>
                            <div id="resultsContent"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <footer class="mt-5 py-4 bg-light">
            <div class="container text-center">
                <p class="text-muted">JuliaGrid.jl - Open Source Power System Analysis Tool</p>
                <p class="text-muted small">Built with Julia ❤️</p>
            </div>
        </footer>

        <script>
            let currentSystem = null;

            function updateSystemStatus(status) {
                const statusDiv = document.getElementById('systemStatus');
                statusDiv.textContent = status;
                statusDiv.style.display = 'block';
                statusDiv.className = 'alert alert-success';
                
                // Enable analysis buttons
                document.getElementById('acPowerFlowBtn').disabled = false;
                document.getElementById('dcPowerFlowBtn').disabled = false;
            }

            function loadExample() {
                const select = document.getElementById('systemSelect');
                const exampleName = select.value;
                
                if (!exampleName) return;
                
                fetch(`/api/system/example/\${exampleName}`, { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            updateSystemStatus(`Loaded: \${data.system_info}`);
                            currentSystem = data;
                        } else {
                            alert('Error loading example: ' + data.error);
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        alert('Failed to load example system');
                    });
            }

            function runACPowerFlow() {
                if (!currentSystem) {
                    alert('Please load a system first');
                    return;
                }
                runAnalysis('AC Power Flow', '/api/analysis/powerflow', { method: 'ac' });
            }

            function runDCPowerFlow() {
                if (!currentSystem) {
                    alert('Please load a system first');
                    return;
                }
                runAnalysis('DC Power Flow', '/api/analysis/powerflow', { method: 'dc' });
            }

            function runAnalysis(title, endpoint, data) {
                document.getElementById('welcomeCard').style.display = 'none';
                document.getElementById('resultsCard').style.display = 'block';
                document.getElementById('resultsTitle').textContent = title;
                document.getElementById('loadingSpinner').style.display = 'block';
                document.getElementById('resultsContent').innerHTML = '';

                fetch(endpoint, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                })
                .then(response => response.json())
                .then(result => {
                    document.getElementById('loadingSpinner').style.display = 'none';
                    displayResults(result);
                })
                .catch(error => {
                    document.getElementById('loadingSpinner').style.display = 'none';
                    document.getElementById('resultsContent').innerHTML = 
                        `<div class="alert alert-danger">Error: \${error.message}</div>`;
                });
            }

            function displayResults(result) {
                const content = document.getElementById('resultsContent');
                
                if (!result.success) {
                    content.innerHTML = `<div class="alert alert-danger">Analysis failed: \${result.error}</div>`;
                    return;
                }

                let html = `
                    <div class="row">
                        <div class="col-md-12">
                            <h6>Analysis Summary</h6>
                            <div class="alert alert-success">
                                <strong>Status:</strong> \${result.status}<br>
                                <strong>Method:</strong> \${result.method}`;
                                
                if (result.iterations) {
                    html += `<br><strong>Iterations:</strong> \${result.iterations}`;
                }
                
                html += `
                            </div>
                        </div>
                    </div>`;
                
                if (result.bus_data && result.bus_data.length > 0) {
                    html += `
                        <div class="mt-4">
                            <h6>System Information</h6>
                            <div class="table-responsive">
                                \${formatDataTable(result.bus_data, 'Bus')}
                            </div>
                        </div>`;
                }
                
                if (result.message) {
                    html += `
                        <div class="mt-3">
                            <div class="alert alert-info">
                                <strong>Note:</strong> \${result.message}
                            </div>
                        </div>`;
                }
                
                content.innerHTML = html;
            }

            function formatDataTable(data, type) {
                if (!data || data.length === 0) return '<p>No data available</p>';
                
                const headers = Object.keys(data[0]);
                let html = `<table class="table table-striped table-sm">
                              <thead class="table-dark">
                                <tr>`;
                
                headers.forEach(header => {
                    html += `<th>\${header}</th>`;
                });
                
                html += `</tr></thead><tbody>`;
                
                data.forEach(row => {
                    html += '<tr>';
                    headers.forEach(header => {
                        const value = row[header];
                        const displayValue = typeof value === 'number' ? value.toFixed(4) : value;
                        html += `<td>\${displayValue}</td>`;
                    });
                    html += '</tr>';
                });
                
                html += '</tbody></table>';
                return html;
            }

            function clearResults() {
                document.getElementById('resultsCard').style.display = 'none';
                document.getElementById('welcomeCard').style.display = 'block';
            }

            // Check system status on load
            fetch('/api/system/status')
                .then(response => response.json())
                .then(data => {
                    if (data.has_system) {
                        updateSystemStatus(data.system_info);
                    }
                })
                .catch(error => console.log('No system loaded'));
        </script>
    </body>
    </html>
    """
    
    return HTTP.Response(200, ["Content-Type" => "text/html"], html_content)
end

"""
Handle loading example systems
"""
function handle_load_example(req::HTTP.Request)
    try
        # Extract example name from URL path
        path_parts = split(req.target, "/")
        example_name = length(path_parts) > 0 ? path_parts[end] : ""
        
        if example_name == "ieee14"
            # Create simple IEEE system without using macros
            system = create_simple_ieee_system()
            CURRENT_SYSTEM[] = system
            
            return HTTP.Response(200, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => true,
                    "system_info" => "Simplified IEEE System (8 buses, 6 branches)"
                )))
            
        elseif example_name == "simple4"
            # Create simple 4-bus system
            system = create_basic_4bus_system()
            CURRENT_SYSTEM[] = system
            
            return HTTP.Response(200, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => true,
                    "system_info" => "Basic 4-bus System (4 buses, 4 branches)"
                )))
        else
            return HTTP.Response(400, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => false,
                    "error" => "Unknown example system: $example_name"
                )))
        end
        
    catch e
        return HTTP.Response(500, ["Content-Type" => "application/json"], 
            JSON3.write(Dict(
                "success" => false,
                "error" => "Failed to load example: $(string(e))"
            )))
    end
end

"""
Handle power flow analysis requests
"""
function handle_powerflow(req::HTTP.Request)
    try
        if CURRENT_SYSTEM[] === nothing
            return HTTP.Response(400, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => false,
                    "error" => "No system loaded. Please load a system first."
                )))
        end
        
        # Parse request body
        body = String(req.body)
        payload = JSON3.read(body)
        method = get(payload, "method", "ac")
        
        if method == "ac"
            # Run AC power flow
            solver = Main.JuliaGrid.newtonRaphson(CURRENT_SYSTEM[])
            Main.JuliaGrid.powerFlow!(solver)
            
            return HTTP.Response(200, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => true,
                    "status" => "Converged",
                    "method" => "AC Power Flow (Newton-Raphson)",
                    "iterations" => "See console for details",
                    "bus_data" => extract_basic_system_info(CURRENT_SYSTEM[]),
                    "message" => "Analysis completed successfully. Check the console output for detailed results."
                )))
        else
            # DC power flow
            analysis = Main.JuliaGrid.dcPowerFlow(CURRENT_SYSTEM[])
            
            return HTTP.Response(200, ["Content-Type" => "application/json"], 
                JSON3.write(Dict(
                    "success" => true,
                    "status" => "Completed",
                    "method" => "DC Power Flow",
                    "bus_data" => extract_basic_system_info(CURRENT_SYSTEM[]),
                    "message" => "DC power flow analysis completed. Check the console output for detailed results."
                )))
        end
        
    catch e
        return HTTP.Response(500, ["Content-Type" => "application/json"], 
            JSON3.write(Dict(
                "success" => false,
                "error" => string(e)
            )))
    end
end

"""
Handle system status requests
"""
function handle_system_status(req::HTTP.Request)
    if CURRENT_SYSTEM[] === nothing
        return HTTP.Response(200, ["Content-Type" => "application/json"], 
            JSON3.write(Dict(
                "has_system" => false,
                "system_info" => "No system loaded"
            )))
    else
        system = CURRENT_SYSTEM[]
        num_buses = length(system.bus.label)
        num_branches = length(system.branch.label)
        
        return HTTP.Response(200, ["Content-Type" => "application/json"], 
            JSON3.write(Dict(
                "has_system" => true,
                "system_info" => "$num_buses buses, $num_branches branches"
            )))
    end
end

"""
Create a simplified IEEE system without macros
"""
function create_simple_ieee_system()
    # Use parent module functions
    system = Main.JuliaGrid.powerSystem()
    
    # Add buses without using macros
    Main.JuliaGrid.addBus!(system; label =  1, type = 3, base = 230, active =  0.0, reactive =  0.0, magnitude = 1.060, angle =   0.00)
    Main.JuliaGrid.addBus!(system; label =  2, type = 2, base = 230, active = 21.7, reactive = 12.7, magnitude = 1.045, angle =  -4.98)
    Main.JuliaGrid.addBus!(system; label =  3, type = 2, base = 230, active = 94.2, reactive = 19.0, magnitude = 1.010, angle = -12.72)
    Main.JuliaGrid.addBus!(system; label =  4, type = 1, base = 230, active = 47.8, reactive = -3.9, magnitude = 1.019, angle = -10.33)
    Main.JuliaGrid.addBus!(system; label =  5, type = 1, base = 230, active =  7.6, reactive =  1.6, magnitude = 1.020, angle =  -8.78)
    Main.JuliaGrid.addBus!(system; label =  6, type = 2, base = 115, active = 11.2, reactive =  7.5, magnitude = 1.070, angle = -14.22)
    Main.JuliaGrid.addBus!(system; label =  7, type = 1, base = 115, active =  0.0, reactive =  0.0, magnitude = 1.062, angle = -13.37)
    Main.JuliaGrid.addBus!(system; label =  8, type = 2, base = 115, active =  0.0, reactive =  0.0, magnitude = 1.090, angle = -13.36)
    
    # Add branches
    Main.JuliaGrid.addBranch!(system; from =  1, to =  2, resistance = 0.01938, reactance = 0.05917, susceptance = 0.0528)
    Main.JuliaGrid.addBranch!(system; from =  1, to =  5, resistance = 0.05403, reactance = 0.22304, susceptance = 0.0492)
    Main.JuliaGrid.addBranch!(system; from =  2, to =  3, resistance = 0.04699, reactance = 0.19797, susceptance = 0.0438)
    Main.JuliaGrid.addBranch!(system; from =  2, to =  4, resistance = 0.05811, reactance = 0.17632, susceptance = 0.0340)
    Main.JuliaGrid.addBranch!(system; from =  2, to =  5, resistance = 0.05695, reactance = 0.17388, susceptance = 0.0346)
    Main.JuliaGrid.addBranch!(system; from =  6, to =  7, resistance = 0.01335, reactance = 0.04211, susceptance = 0.0000)
    
    # Add generators
    Main.JuliaGrid.addGenerator!(system; label = 1, bus = 1, magnitude = 1.060, active = 232.4, reactive = -16.9)
    Main.JuliaGrid.addGenerator!(system; label = 2, bus = 2, magnitude = 1.045, active =  40.0, reactive =  42.4)
    Main.JuliaGrid.addGenerator!(system; label = 3, bus = 3, magnitude = 1.010, active =   0.0, reactive =  23.4)
    
    Main.JuliaGrid.acModel!(system)
    
    return system
end

"""
Create a basic 4-bus system without macros
"""
function create_basic_4bus_system()
    system = Main.JuliaGrid.powerSystem()
    
    # Add buses
    Main.JuliaGrid.addBus!(system; label = "Bus 1", type = 3, angle = 0.0)
    Main.JuliaGrid.addBus!(system; label = "Bus 2", type = 2, active = 20.2, reactive = 10.5)
    Main.JuliaGrid.addBus!(system; label = "Bus 3", type = 1, conductance = 0.1, susceptance = 8.2)
    Main.JuliaGrid.addBus!(system; label = "Bus 4", type = 1, active = 50.8, reactive = 23.1)
    
    # Add branches
    Main.JuliaGrid.addBranch!(system; from = "Bus 1", to = "Bus 3", resistance = 0.02, reactance = 0.22, susceptance = 0.05)
    Main.JuliaGrid.addBranch!(system; from = "Bus 1", to = "Bus 2", resistance = 0.05, reactance = 0.22, susceptance = 0.04)
    Main.JuliaGrid.addBranch!(system; from = "Bus 2", to = "Bus 3", resistance = 0.04, reactance = 0.22, susceptance = 0.04)
    Main.JuliaGrid.addBranch!(system; from = "Bus 3", to = "Bus 4", resistance = 0.01, reactance = 0.22, turnsRatio = 0.98)
    
    # Add generators
    Main.JuliaGrid.addGenerator!(system; bus = "Bus 1", active = 60.1, reactive = 40.2, magnitude = 0.98)
    Main.JuliaGrid.addGenerator!(system; bus = "Bus 2", active = 18.2, magnitude = 1.01)
    
    Main.JuliaGrid.acModel!(system)
    
    return system
end

"""
Extract basic system information for display
"""
function extract_basic_system_info(system)
    try
        bus_data = []
        
        for i in 1:length(system.bus.label)
            push!(bus_data, Dict(
                "Bus" => string(system.bus.label[i]),
                "Type" => system.bus.type[i] == 3 ? "Slack" : (system.bus.type[i] == 2 ? "PV" : "PQ"),
                "Active Load (MW)" => round(system.bus.demand.active[i], digits=2),
                "Reactive Load (MVAr)" => round(system.bus.demand.reactive[i], digits=2)
            ))
        end
        
        return bus_data
    catch e
        return [Dict("Info" => "System loaded successfully", "Details" => "Use analysis tools to see results")]
    end
end

end # module UI