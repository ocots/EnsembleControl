"""
    PolishingVisualization

Module for visualizing polishing problem results.

Follows Single Responsibility Principle: Only handles visualization.
"""
module PolishingVisualization

using OptimalControl
using Plots
using ..PolishingProblem

export plot_surfaces, plot_control_norm, plot_trajectory, plot_nozzle_effect
export plot_final_result, create_visualization_grid, plot_grid_with_surface
export plot_surfaces_3d, plot_final_result_3d

"""
    create_visualization_grid(domain, resolution=100)

Create a fine grid for visualization.

# Arguments
- `domain::Tuple{Float64,Float64}`: Domain limits
- `resolution::Int`: Number of points per dimension

# Returns
- Tuple of (x_range, y_range)
"""
function create_visualization_grid(domain, resolution=100)
    domain_min, domain_max = domain
    x_range = range(domain_min, domain_max, length=resolution)
    y_range = range(domain_min, domain_max, length=resolution)
    return (x_range, y_range)
end

"""
    plot_surfaces(config::PolishingConfig; resolution=100)

Plot initial and target final surfaces.

# Arguments
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution for plotting

# Returns
- Tuple of (plot_initial, plot_final)
"""
function plot_surfaces(config::PolishingConfig; resolution=100)
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    
    # Initial surface
    z_initial = @. initial_surface(x_range', y_range)
    p1 = contourf(x_range, y_range, z_initial, 
                  title="Initial surface",
                  xlabel="x", ylabel="y",
                  color=:viridis,
                  levels=20)
    
    # Target final surface (using reference trajectory)
    u_ref(t) = config.reference_velocity
    tf_ref = config.time_final
    s0 = config.initial_position
    
    surf_final(x, y) = begin
        X0 = [s0[1], s0[2], initial_surface(x, y)]
        compute_surface_evolution(tf_ref, x, y, u_ref, X0, config)[3]
    end
    
    z_final = @. surf_final(x_range', y_range)
    p2 = contourf(x_range, y_range, z_final,
                  title="Target final surface",
                  xlabel="x", ylabel="y",
                  color=:viridis,
                  levels=20)
    
    return (p1, p2)
end

"""
    plot_control_norm(sol; label="||u||")

Plot the norm of the control over time.

# Arguments
- `sol`: Solution from OptimalControl.solve
- `label::String`: Label for the plot

# Returns
- Plot object
"""
function plot_control_norm(sol; label="||u||")
    u = control(sol)
    t = time_grid(sol)
    
    return plot(t, t -> u(t)[1]^2 + u(t)[2]^2, 
                label=label,
                xlabel="Time", ylabel="||u||²",
                title="Control norm")
end

"""
    plot_trajectory(sol)

Plot the nozzle trajectory components.

# Arguments
- `sol`: Solution from OptimalControl.solve

# Returns
- Plot object with both trajectory components
"""
function plot_trajectory(sol)
    x_state = state(sol)
    s(t) = x_state(t)[1:2]
    t = time_grid(sol)
    
    p = plot(t, t -> s(t)[1], label="s₁ (x position)",
             xlabel="Time", ylabel="Position",
             title="Nozzle trajectory")
    plot!(p, t, t -> s(t)[2], label="s₂ (y position)")
    
    return p
end

"""
    plot_nozzle_effect(config::PolishingConfig; resolution=100)

Plot the polishing effect of a centered nozzle.

# Arguments
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution

# Returns
- Plot object
"""
function plot_nozzle_effect(config::PolishingConfig; resolution=100)
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    
    nozzle_centered(x, y) = polishing_function(x, y, 0, 0, config)
    z = @. nozzle_centered(x_range', y_range)
    
    return contour(x_range, y_range, z,
                   title="Centered nozzle effect",
                   xlabel="x", ylabel="y")
end

"""
    plot_final_result(sol, grid::Grid2D, config::PolishingConfig; resolution=50)

Plot the final achieved surface with the optimal trajectory.

# Arguments
- `sol`: Solution from OptimalControl.solve
- `grid::Grid2D`: Discretization grid
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution for surface plot

# Returns
- Plot object
"""
function plot_final_result(sol, grid::Grid2D, config::PolishingConfig; resolution=50)
    x_state = state(sol)
    t_grid = time_grid(sol)
    tf_sol = t_grid[end]
    
    # Compute final surface
    function surf_achieved(t, x, y, state_func)
        s0_val = initial_surface(x, y)
        ϕ = Flow((τ, s) -> polishing_function(x, y, state_func(τ)[1], state_func(τ)[2], config); 
                 autonomous=false)
        return ϕ(0, s0_val, t)
    end
    
    surf_final_achieved(x, y) = surf_achieved(tf_sol, x, y, t -> x_state(t)[1:2])
    
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    z = @. surf_final_achieved(x_range', y_range)
    
    p = contour(x_range, y_range, z,
                title="Final achieved surface",
                xlabel="x", ylabel="y")
    
    # Add trajectory
    plot!(p, t -> x_state(t)[1], t -> x_state(t)[2], 0, tf_sol,
          label="Nozzle trajectory", linewidth=2, color=:red)
    
    # Add grid points
    scatter!(p, grid[1, :], grid[2, :], label="Grid points", 
             markersize=3, color=:black)
    
    return p
end

"""
    plot_grid_with_surface(grid::Grid2D, config::PolishingConfig; resolution=100)

Plot initial surface with grid points overlay.

# Arguments
- `grid::Grid2D`: Discretization grid
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution

# Returns
- Plot object
"""
function plot_grid_with_surface(grid::Grid2D, config::PolishingConfig; resolution=100)
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    z = @. initial_surface(x_range', y_range)
    
    p = contour(x_range, y_range, z,
                title="Initial surface with grid",
                xlabel="x", ylabel="y")
    scatter!(p, grid[1, :], grid[2, :], 
             label="Grid points", markersize=4, color=:red)
    
    return p
end

"""
    plot_surfaces_3d(config::PolishingConfig; resolution=50)

Plot initial and target surfaces in 3D.

# Arguments
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution for 3D plotting

# Returns
- Tuple of (plot_initial_3d, plot_final_3d)
"""
function plot_surfaces_3d(config::PolishingConfig; resolution=50)
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    
    # Initial surface
    z_initial = @. initial_surface(x_range', y_range)
    p1 = surface(x_range, y_range, z_initial,
                 title="Initial surface (3D)",
                 xlabel="x", ylabel="y", zlabel="height",
                 color=:viridis,
                 camera=(30, 60))
    
    # Target final surface
    u_ref(t) = config.reference_velocity
    tf_ref = config.time_final
    s0 = config.initial_position
    
    surf_final(x, y) = begin
        X0 = [s0[1], s0[2], initial_surface(x, y)]
        compute_surface_evolution(tf_ref, x, y, u_ref, X0, config)[3]
    end
    
    z_final = @. surf_final(x_range', y_range)
    p2 = surface(x_range, y_range, z_final,
                 title="Target final surface (3D)",
                 xlabel="x", ylabel="y", zlabel="height",
                 color=:viridis,
                 camera=(30, 60))
    
    return (p1, p2)
end

"""
    plot_final_result_3d(sol, grid::Grid2D, config::PolishingConfig; resolution=50)

Plot the final achieved surface in 3D with the optimal trajectory.

# Arguments
- `sol`: Solution from OptimalControl.solve
- `grid::Grid2D`: Discretization grid
- `config::PolishingConfig`: Problem configuration
- `resolution::Int`: Grid resolution for surface plot

# Returns
- Plot object
"""
function plot_final_result_3d(sol, grid::Grid2D, config::PolishingConfig; resolution=50)
    x_state = state(sol)
    t_grid = time_grid(sol)
    tf_sol = t_grid[end]
    
    # Compute final surface
    function surf_achieved(t, x, y, state_func)
        s0_val = initial_surface(x, y)
        ϕ = Flow((τ, s) -> polishing_function(x, y, state_func(τ)[1], state_func(τ)[2], config); 
                 autonomous=false)
        return ϕ(0, s0_val, t)
    end
    
    surf_final_achieved(x, y) = surf_achieved(tf_sol, x, y, t -> x_state(t)[1:2])
    
    x_range, y_range = create_visualization_grid(config.domain, resolution)
    z = @. surf_final_achieved(x_range', y_range)
    
    p = surface(x_range, y_range, z,
                title="Final achieved surface (3D)",
                xlabel="x", ylabel="y", zlabel="height",
                color=:viridis,
                camera=(30, 60))
    
    # Add trajectory as a 3D curve
    # Sample trajectory points
    t_sample = range(0, tf_sol, length=100)
    traj_x = [x_state(t)[1] for t in t_sample]
    traj_y = [x_state(t)[2] for t in t_sample]
    # Height of trajectory (slightly above surface for visibility)
    traj_z = [maximum(z) * 1.1 for _ in t_sample]
    
    plot!(p, traj_x, traj_y, traj_z,
          label="Nozzle trajectory", linewidth=3, color=:red)
    
    return p
end

end # module
