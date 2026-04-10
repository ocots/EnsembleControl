"""
Development setup for interactive work with Revise

This file sets up the environment for interactive development.
Run this once at the start of your Julia session, then you can modify
the source files and changes will be automatically picked up.

Usage:
    julia> include("dev_setup.jl")
    julia> # Now work interactively, modify source files, they auto-reload!
"""

using Pkg
Pkg.activate(@__DIR__)

# Install Revise if not already installed
if !haskey(Pkg.project().dependencies, "Revise")
    Pkg.add("Revise")
end

using Revise

# Load modules with Revise tracking
includet(joinpath(@__DIR__, "src", "PolishingProblem.jl"))
includet(joinpath(@__DIR__, "src", "PolishingVisualization.jl"))

using .PolishingProblem
using .PolishingVisualization

# Also load the packages we need
using OptimalControl
using Plots
using NLPModelsIpopt
using OrdinaryDiffEq

println("✓ Development environment loaded with Revise")
println("✓ Modules: PolishingProblem, PolishingVisualization")
println("✓ You can now modify source files and changes will auto-reload")
println("\nTo run the example:")
println("  julia> include(\"examples/run_polishing.jl\")")
