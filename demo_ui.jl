#!/usr/bin/env julia

"""
JuliaGrid Web UI Demo

This script demonstrates the functionality of the JuliaGrid web interface
by programmatically testing all the key features.
"""

using Pkg
Pkg.activate(@__DIR__)

using JuliaGrid
using HTTP
using JSON3

println("🔌 JuliaGrid Web UI Demo")
println("=" ^ 50)

# Start server in background
println("🚀 Starting web server...")
server_task = @async begin
    try
        start_ui(8089, "127.0.0.1")
    catch e
        println("Server error: $e")
    end
end

# Give server time to start
sleep(3)

println("✅ Server started on http://127.0.0.1:8089")

try
    # Test 1: Access the main page
    println("\n📋 Test 1: Accessing main web interface...")
    response = HTTP.get("http://127.0.0.1:8089/"; retry=false, readtimeout=5)
    if response.status == 200
        println("✅ Main page accessible ($(length(response.body)) bytes)")
        
        # Check for key UI elements
        content = String(response.body)
        if occursin("JuliaGrid", content) && occursin("Power System Analysis", content)
            println("✅ UI contains expected branding and title")
        end
        if occursin("Load Example", content) && occursin("Analysis Tools", content)
            println("✅ UI contains system loading and analysis sections")
        end
    else
        println("❌ Main page returned status: $(response.status)")
    end

    # Test 2: Load example system
    println("\n📊 Test 2: Loading example power system...")
    example_response = HTTP.post("http://127.0.0.1:8089/api/system/example/simple4", 
                               ["Content-Type" => "application/json"], 
                               "{}"; retry=false, readtimeout=10)
    
    if example_response.status == 200
        result = JSON3.read(String(example_response.body))
        if result.success
            println("✅ Successfully loaded: $(result.system_info)")
        else
            println("❌ Failed to load system: $(result.error)")
        end
    else
        println("❌ System loading failed with status: $(example_response.status)")
    end

    # Test 3: Check system status
    println("\n🔍 Test 3: Checking system status...")
    status_response = HTTP.get("http://127.0.0.1:8089/api/system/status"; retry=false, readtimeout=5)
    
    if status_response.status == 200
        status = JSON3.read(String(status_response.body))
        if status.has_system
            println("✅ System status: $(status.system_info)")
        else
            println("ℹ️ No system currently loaded")
        end
    end

    # Test 4: Run AC Power Flow analysis
    println("\n⚡ Test 4: Running AC Power Flow analysis...")
    pf_response = HTTP.post("http://127.0.0.1:8089/api/analysis/powerflow",
                           ["Content-Type" => "application/json"],
                           "{\"method\": \"ac\"}"; retry=false, readtimeout=15)
    
    if pf_response.status == 200
        result = JSON3.read(String(pf_response.body))
        if result.success
            println("✅ AC Power Flow completed successfully")
            println("   Method: $(result.method)")
            println("   Status: $(result.status)")
            if haskey(result, :bus_data) && length(result.bus_data) > 0
                println("   Bus data entries: $(length(result.bus_data))")
            end
        else
            println("❌ AC Power Flow failed: $(result.error)")
        end
    else
        println("❌ AC Power Flow request failed with status: $(pf_response.status)")
    end

    # Test 5: Run DC Power Flow analysis  
    println("\n🔋 Test 5: Running DC Power Flow analysis...")
    dc_response = HTTP.post("http://127.0.0.1:8089/api/analysis/powerflow",
                           ["Content-Type" => "application/json"],
                           "{\"method\": \"dc\"}"; retry=false, readtimeout=15)
    
    if dc_response.status == 200
        result = JSON3.read(String(dc_response.body))
        if result.success
            println("✅ DC Power Flow completed successfully")
            println("   Method: $(result.method)")
            println("   Status: $(result.status)")
        else
            println("❌ DC Power Flow failed: $(result.error)")
        end
    else
        println("❌ DC Power Flow request failed with status: $(dc_response.status)")
    end

    # Test 6: Load IEEE system
    println("\n🏢 Test 6: Loading IEEE 14-bus system...")
    ieee_response = HTTP.post("http://127.0.0.1:8089/api/system/example/ieee14", 
                             ["Content-Type" => "application/json"], 
                             "{}"; retry=false, readtimeout=10)
    
    if ieee_response.status == 200
        result = JSON3.read(String(ieee_response.body))
        if result.success
            println("✅ Successfully loaded: $(result.system_info)")
        else
            println("❌ Failed to load IEEE system: $(result.error)")
        end
    else
        println("❌ IEEE system loading failed with status: $(ieee_response.status)")
    end

    println("\n🎉 Demo completed successfully!")
    println("\n📖 Usage Instructions:")
    println("1. Run 'julia ui.jl' to start the web interface")
    println("2. Open http://127.0.0.1:8080 in your web browser")
    println("3. Select an example system from the sidebar")
    println("4. Click 'AC Power Flow' or 'DC Power Flow' to run analysis")
    println("5. View results in the main panel")
    
    println("\n💡 Features:")
    println("• Interactive web-based interface")
    println("• Pre-configured example power systems")
    println("• AC and DC power flow analysis")
    println("• Real-time results display")
    println("• Mobile-responsive design")
    println("• RESTful API backend")

catch e
    println("❌ Demo failed with error: $e")
    println("\nPlease ensure JuliaGrid is properly installed and the server can start.")
end

println("\n🛑 Shutting down demo server...")
# Server will stop when the script ends