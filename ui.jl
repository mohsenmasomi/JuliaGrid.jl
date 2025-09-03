#!/usr/bin/env julia

"""
JuliaGrid Web UI Launcher

This script starts the JuliaGrid web interface.

Usage:
    julia ui.jl [port] [host]

Arguments:
    port: Port number (default: 8080)
    host: Host address (default: 127.0.0.1)

Example:
    julia ui.jl 3000 0.0.0.0
"""

using Pkg
Pkg.activate(@__DIR__)

using JuliaGrid

function main()
    # Parse command line arguments
    port = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 8080
    host = length(ARGS) >= 2 ? ARGS[2] : "127.0.0.1"
    
    println("="^60)
    println("🔌 JuliaGrid Web Interface")
    println("="^60)
    println("📊 Power System Analysis Tool")
    println("🌐 Starting web server...")
    println()
    
    try
        start_ui(port, host)
    catch e
        if isa(e, InterruptException)
            println("\n👋 Shutting down JuliaGrid Web UI...")
            println("Thank you for using JuliaGrid!")
        else
            println("\n❌ Error starting server: $e")
            exit(1)
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end