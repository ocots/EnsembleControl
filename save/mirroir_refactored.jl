"""
Surface Polishing Optimal Control Problem - Refactored Version

This script demonstrates the refactored approach following SOLID principles:
- Single Responsibility: Each module has one clear purpose
- Open/Closed: Extensible via configuration
- Dependency Inversion: Depends on abstractions (modules)
- Interface Segregation: Clean, minimal interfaces
- DRY: No code duplication

Compare with original mirroir.jl to see improvements in:
- Readability
- Maintainability
- Testability
- Reusability
"""

using Revise
using Pkg
Pkg.activate(@__DIR__)

using OptimalControl
using Plots
using NLPModelsIpopt
using OrdinaryDiffEq

# Load our modular components
include(joinpath(@__DIR__, "src", "PolishingProblem.jl"))
include(joinpath(@__DIR__, "src", "PolishingVisualization.jl"))

using .PolishingProblem
using .PolishingVisualization

# ============================================================================
# Configuration (all parameters in one place)
# ============================================================================

config = PolishingConfig(
    grid_size = (5, 5),
    domain = (-1.0, 1.0),
    nozzle_amplitude = 0.1,
    nozzle_sigma_x = 0.05,
    nozzle_sigma_y = 0.01,
    initial_position = [-1.0, 0.0],
    time_final = 15.0,
    reference_velocity = [0.1, 0.0]
)

# ============================================================================
# Problem Setup
# ============================================================================

println("Creating grid...")
grid = create_grid(config)
println("Grid created with $(size(grid)) points")

println("\nSetting up optimal control problem...")
ocp, h0, hf = setup_ocp_problem(grid, config)
println("OCP problem defined")

# ============================================================================
# Visualization: Initial and Target Surfaces
# ============================================================================

println("\nPlotting initial and target surfaces...")
p_init, p_target = plot_surfaces(config)
display(p_init)
display(p_target)

# Plot grid with initial surface
p_grid = plot_grid_with_surface(grid, config)
display(p_grid)

# Plot nozzle effect
p_nozzle = plot_nozzle_effect(config)
display(p_nozzle)

# ============================================================================
# Solve Optimal Control Problem
# ============================================================================

println("\nSolving optimal control problem...")
sol = solve(ocp; 
    grid_size = 500,  # Plus de points de discrétisation
    tol = 1e-8,       # Tolérance
    max_iter = 500    # Plus d'itérations
)
println("Problem solved!")

# Extract solution
t_grid = time_grid(sol)
tf_solution = t_grid[end]
println("Optimal time: $tf_solution")

# ============================================================================
# Visualization: Results
# ============================================================================

println("\nPlotting results...")

# Control norm
p_control = plot_control_norm(sol)
display(p_control)

# Trajectory
p_traj = plot_trajectory(sol)
display(p_traj)

# Final result with trajectory
p_final = plot_final_result(sol, grid, config)
display(p_final)

# ============================================================================
# Analysis: Compute final cost
# ============================================================================

println("\nComputing final surface error...")
x_state = state(sol)

function surf_achieved(t, x, y, state_func)
    s0_val = initial_surface(x, y)
    ϕ = Flow((τ, s) -> polishing_function(x, y, state_func(τ)[1], state_func(τ)[2], config); 
             autonomous=false)
    return ϕ(0, s0_val, t)
end

surf_final_achieved(x, y) = surf_achieved(tf_solution, x, y, t -> x_state(t)[1:2])
cost = [surf_final_achieved(grid[1, i], grid[2, i]) for i ∈ 1:size(grid)]
println("Final surface heights at grid points:")
println(cost)

println("\n✓ Simulation complete!")
