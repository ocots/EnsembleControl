"""
Example: Surface Polishing Optimal Control

This example demonstrates the polishing optimization.
Make sure to run dev_setup.jl first!

Usage:
    julia> include("dev_setup.jl")  # First time only
    julia> include("examples/run_polishing.jl")  # Run example
    # Modify source files, then re-run this file - changes auto-reload!
"""

# ============================================================================
# Setup
# ============================================================================

# Create results directory if it doesn't exist
mkpath("results")

# ============================================================================
# Configuration (all parameters in one place)
# ============================================================================

# Choose a surface profile from the catalog
# Available profiles: "gaussian_bump", "flat_with_defect", "saddle_shape", 
#                     "random_rough", "wavy_surface"
# To see all profiles: SurfaceProfiles.list_profiles()

profile = get_profile("flat_with_defect")  # Nearly flat with small defect → perfectly flat

config = PolishingConfig(
    grid_size = (5, 5),
    domain = (-1.0, 1.0),
    nozzle_amplitude = 0.1,
    nozzle_sigma_x = 0.05,
    nozzle_sigma_y = 0.01,
    initial_position = [-1.0, 0.0],
    initial_surface = profile.initial,
    target_surface = profile.target
)

println("Using surface profile: $(profile.name)")
println("Description: $(profile.description)")

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
savefig(p_init, "results/01_initial_surface.svg")
savefig(p_target, "results/02_target_surface.svg")
println("  ✓ Saved initial and target surfaces (2D)")

# 3D surface plots
p_init_3d, p_target_3d = plot_surfaces_3d(config)
savefig(p_init_3d, "results/01b_initial_surface_3d.svg")
savefig(p_target_3d, "results/02b_target_surface_3d.svg")
println("  ✓ Saved initial and target surfaces (3D)")

# Plot grid with initial surface
p_grid = plot_grid_with_surface(grid, config)
savefig(p_grid, "results/03_grid_with_surface.svg")
println("  ✓ Saved grid visualization")

# Plot nozzle effect
p_nozzle = plot_nozzle_effect(config)
savefig(p_nozzle, "results/04_nozzle_effect.svg")
println("  ✓ Saved nozzle effect")

# ============================================================================
# Solve Optimal Control Problem
# ============================================================================

println("\nSolving optimal control problem...")

# Initial guess for better convergence
# Linear interpolation from initial to final position
tf_guess = 15.0  # Initial guess for final time
init_guess = (
    state = t -> begin
        # Linear trajectory from s0 to center of domain
        s1_interp = config.initial_position[1] + t/tf_guess * (0.0 - config.initial_position[1])
        s2_interp = config.initial_position[2] + t/tf_guess * (0.0 - config.initial_position[2])
        # Heights remain at initial values
        return [s1_interp, s2_interp, h0...]
    end,
    control = t -> [0.1, 0.0],  # Constant velocity guess
    variable = tf_guess
)

sol = solve(ocp, init=init_guess;
    grid_size = 300,  # More discretization points
    tol = 1e-6,       # Tolerance
    max_iter = 500    # More iterations
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
savefig(p_control, "results/05_control_norm.svg")
println("  ✓ Saved control norm")

# Trajectory
p_traj = plot_trajectory(sol)
savefig(p_traj, "results/06_trajectory.svg")
println("  ✓ Saved trajectory")

# Final result with trajectory (2D)
p_final = plot_final_result(sol, grid, config)
savefig(p_final, "results/07_final_result.svg")
println("  ✓ Saved final result (2D)")

# Final result with trajectory (3D)
p_final_3d = plot_final_result_3d(sol, grid, config)
savefig(p_final_3d, "results/07b_final_result_3d.svg")
println("  ✓ Saved final result (3D)")

# ============================================================================
# Analysis: Compute final cost
# ============================================================================

println("\nComputing final surface error...")
x_state = state(sol)

function surf_achieved(t, x, y, state_func)
    s0_val = config.initial_surface(x, y)
    ϕ = Flow((τ, s) -> polishing_function(x, y, state_func(τ)[1], state_func(τ)[2], config); 
             autonomous=false)
    return ϕ(0, s0_val, t)
end

surf_final_achieved(x, y) = surf_achieved(tf_solution, x, y, t -> x_state(t)[1:2])
cost = [surf_final_achieved(grid[1, i], grid[2, i]) for i ∈ 1:size(grid)]
println("Final surface heights at grid points:")
println(cost)

println("\n✓ Simulation complete!")
