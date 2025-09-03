#!/usr/bin/env julia

using Pkg
Pkg.activate(@__DIR__)

using JuliaGrid
using HTTP

println("Testing JuliaGrid Web UI...")

# Start server in background
server_task = @async begin
    try
        start_ui(8084, "127.0.0.1")
    catch e
        println("Server error: $e")
    end
end

# Give server time to start
sleep(3)

# Test basic connectivity
try
    response = HTTP.get("http://127.0.0.1:8084/"; retry=false, readtimeout=5)
    println("✅ Server is accessible!")
    println("Status: $(response.status)")
    println("Response length: $(length(response.body)) bytes")
    
    # Test loading an example system
    try
        example_response = HTTP.post("http://127.0.0.1:8084/api/system/example/simple4", 
                                   ["Content-Type" => "application/json"], 
                                   "{}"; retry=false, readtimeout=10)
        println("✅ Example system loading API works!")
        println("Example response: $(String(example_response.body))")
    catch e
        println("❌ Example system API failed: $e")
    end
    
    # Test power flow analysis
    try
        pf_response = HTTP.post("http://127.0.0.1:8084/api/analysis/powerflow",
                               ["Content-Type" => "application/json"],
                               "{\"method\": \"ac\"}"; retry=false, readtimeout=15)
        println("✅ Power flow analysis API works!")
        println("Power flow response: $(String(pf_response.body))")
    catch e
        println("❌ Power flow API failed: $e")
    end
    
catch e
    println("❌ Server is not accessible: $e")
end

# Stop the server
println("Stopping server...")
try
    HTTP.get("http://127.0.0.1:8084/shutdown"; retry=false, readtimeout=1)
catch
    # Expected to fail since we don't have a shutdown endpoint
end

println("✅ Test completed!")