"""
    PolishingProblem

Module for defining and solving surface polishing optimal control problems.

Follows SOLID principles:
- Single Responsibility: Each struct/function has one clear purpose
- Open/Closed: Extensible via abstract types
- Interface Segregation: Clean, minimal interfaces
"""
module PolishingProblem

using OptimalControl
using OrdinaryDiffEq

export PolishingConfig, NozzleModel, SurfaceModel, Grid2D
export create_grid, polishing_function, initial_surface, state_dynamics
export setup_ocp_problem, compute_surface_evolution

# ============================================================================
# Configuration (Single Responsibility: Hold parameters)
# ============================================================================

"""
    PolishingConfig

Configuration parameters for the polishing problem.

# Fields
- `grid_size::Tuple{Int,Int}`: Grid dimensions (n, m)
- `domain::Tuple{Float64,Float64}`: Spatial domain limits
- `nozzle_amplitude::Float64`: Polishing intensity (A)
- `nozzle_sigma_x::Float64`: Nozzle width in x direction
- `nozzle_sigma_y::Float64`: Nozzle width in y direction
- `initial_position::Vector{Float64}`: Initial nozzle position
- `time_final::Float64`: Final time for reference trajectory
- `reference_velocity::Vector{Float64}`: Reference control velocity
"""
struct PolishingConfig
    grid_size::Tuple{Int,Int}
    domain::Tuple{Float64,Float64}
    nozzle_amplitude::Float64
    nozzle_sigma_x::Float64
    nozzle_sigma_y::Float64
    initial_position::Vector{Float64}
    time_final::Float64
    reference_velocity::Vector{Float64}
    
    function PolishingConfig(;
        grid_size = (5, 5),
        domain = (-1.0, 1.0),
        nozzle_amplitude = 0.1,
        nozzle_sigma_x = 0.05,
        nozzle_sigma_y = 0.01,
        initial_position = [-1.0, 0.0],
        time_final = 15.0,
        reference_velocity = [0.1, 0.0]
    )
        new(grid_size, domain, nozzle_amplitude, nozzle_sigma_x, 
            nozzle_sigma_y, initial_position, time_final, reference_velocity)
    end
end

# ============================================================================
# Grid Management (Single Responsibility: Grid creation and access)
# ============================================================================

"""
    Grid2D

2D grid representation for surface discretization.

# Fields
- `points::Matrix{Float64}`: 2×N matrix of grid points
- `n::Int`: Number of points in x direction
- `m::Int`: Number of points in y direction
"""
struct Grid2D
    points::Matrix{Float64}
    n::Int
    m::Int
end

"""
    create_grid(config::PolishingConfig) -> Grid2D

Create a 2D grid based on configuration.

# Arguments
- `config::PolishingConfig`: Configuration parameters

# Returns
- `Grid2D`: Grid structure with points
"""
function create_grid(config::PolishingConfig)
    n, m = config.grid_size
    domain_min, domain_max = config.domain
    
    grid = zeros(2, n * m)
    x_span = range(domain_min, domain_max, length=n)
    y_span = range(domain_min, domain_max, length=m)
    
    k = 1
    for xi ∈ x_span
        for yi ∈ y_span
            grid[1, k] = xi
            grid[2, k] = yi
            k += 1
        end
    end
    
    return Grid2D(grid, n, m)
end

Base.size(g::Grid2D) = size(g.points, 2)
Base.getindex(g::Grid2D, i::Int, j::Int) = g.points[i, j]
Base.getindex(g::Grid2D, i::Int, ::Colon) = g.points[i, :]
Base.getindex(g::Grid2D, ::Colon, j::Int) = g.points[:, j]

# ============================================================================
# Physical Models (Single Responsibility: Physics equations)
# ============================================================================

"""
    polishing_function(x, y, sx, sy, config::PolishingConfig) -> Float64

Compute polishing effect at point (x,y) with nozzle centered at (sx,sy).

Uses a Gaussian model: f(x,y) = -A * exp(-((x-sx)²/(2σx) + (y-sy)²/(2σy)))

# Arguments
- `x, y`: Point coordinates
- `sx, sy`: Nozzle center coordinates
- `config::PolishingConfig`: Configuration with nozzle parameters

# Returns
- `Float64`: Polishing rate (negative for material removal)
"""
function polishing_function(x, y, sx, sy, config::PolishingConfig)
    A = config.nozzle_amplitude
    σx = config.nozzle_sigma_x
    σy = config.nozzle_sigma_y
    
    return -A * exp(-((x - sx)^2 / (2 * σx) + (y - sy)^2 / (2 * σy)))
end

"""
    initial_surface(x, y) -> Float64

Define the initial surface height at point (x,y).

# Arguments
- `x, y`: Point coordinates

# Returns
- `Float64`: Initial surface height
"""
function initial_surface(x, y)
    return exp(-((x - 0)^2 / (2 * 1) + (y - 0)^2 / (2 * 1)))
end

"""
    state_dynamics(sx, sy, u1, u2, grid::Grid2D, config::PolishingConfig) -> Vector

Compute state dynamics: [ṡx, ṡy, ḣ₁, ḣ₂, ..., ḣₙ]

# Arguments
- `sx, sy`: Current nozzle position
- `u1, u2`: Control inputs (nozzle velocities)
- `grid::Grid2D`: Discretization grid
- `config::PolishingConfig`: Configuration parameters

# Returns
- `Vector`: State derivative [velocity_x, velocity_y, height_rates...]
"""
function state_dynamics(sx, sy, u1, u2, grid::Grid2D, config::PolishingConfig)
    nb_pts = size(grid)
    height_rates = [polishing_function(grid[1, i], grid[2, i], sx, sy, config) 
                    for i ∈ 1:nb_pts]
    
    return [u1; u2; height_rates]
end

"""
    compute_surface_evolution(t, x, y, u, X0, config::PolishingConfig)

Compute surface evolution at point (x,y) under control u.

# Arguments
- `t`: Time
- `x, y`: Point coordinates
- `u`: Control function
- `X0`: Initial state [sx0, sy0, h0]
- `config::PolishingConfig`: Configuration

# Returns
- Final state at time t
"""
function compute_surface_evolution(t, x, y, u, X0, config::PolishingConfig)
    lhs(τ, X) = [u(τ)[1], u(τ)[2], polishing_function(x, y, X[1], X[2], config)]
    ϕ = Flow(lhs; autonomous=false)
    return ϕ(0, X0, t)
end

# ============================================================================
# OCP Setup (Single Responsibility: Problem formulation)
# ============================================================================

# Helper function to compute spatial gradient
function spatial_gradient_penalty(h_vec, grid::Grid2D)
    penalty = 0.0
    n, m = grid.n, grid.m
    
    # Penalize differences between neighboring points
    for i in 1:n
        for j in 1:m-1
            idx = (i-1)*m + j
            # Difference in y-direction
            penalty += (h_vec[idx+1] - h_vec[idx])^2
        end
    end
    
    for i in 1:n-1
        for j in 1:m
            idx = (i-1)*m + j
            # Difference in x-direction
            penalty += (h_vec[idx+m] - h_vec[idx])^2
        end
    end
    
    return penalty
end

"""
    setup_ocp_problem(grid::Grid2D, config::PolishingConfig)

Set up the optimal control problem for surface polishing.

# Arguments
- `grid::Grid2D`: Discretization grid
- `config::PolishingConfig`: Problem configuration

# Returns
- Tuple of (ocp, H0, Hf) where:
  - ocp: OptimalControl problem definition
  - H0: Initial surface heights
  - Hf: Target final surface heights
"""
function setup_ocp_problem(grid::Grid2D, config::PolishingConfig)
    nb_pts = size(grid)
    
    # Reference trajectory for target surface
    u_ref(t) = config.reference_velocity
    tf_ref = config.time_final
    s0 = config.initial_position
    
    # Compute target final surface
    final_surface(x, y) = begin
        X0 = [s0[1], s0[2], initial_surface(x, y)]
        compute_surface_evolution(tf_ref, x, y, u_ref, X0, config)[3]
    end
    
    # Initial and final height conditions on grid
    h0 = [initial_surface(grid[1, i], grid[2, i]) for i ∈ 1:nb_pts]
    hf = [final_surface(grid[1, i], grid[2, i]) for i ∈ 1:nb_pts]
    
    h(x) = x[3:end]

    # Define OCP
    ocp = @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R^(2 + nb_pts), state
        u ∈ R², control
        
        s₁ = x[1]
        s₂ = x[2]
        
        # Initial conditions
        s₁(0) == s0[1]
        s₂(0) == s0[2]
        h(x(0)) == h0
        
        # State constraints
        -1 ≤ s₁(t) ≤ 1
        -1 ≤ s₂(t) ≤ 1
        
        # Control constraint
        u₁(t)^2 + u₂(t)^2 ≤ 1
        
        # Time bounds (important for convergence!)
        5 ≤ tf ≤ 30
        
        # Dynamics
        ẋ(t) == state_dynamics(s₁(t), s₂(t), u₁(t), u₂(t), grid, config)
        
        # Objective: minimize surface error + control regularization
        sum((h(x(tf)) .- hf).^2) + 
        ∫(1e-3 * (u₁(t)^2 + u₂(t)^2)) → min
        # ∫(1e-3 * (u₁(t)^2 + u₂(t)^2) + 1e-4 * spatial_gradient_penalty(h(x(t)), grid)) → min
    end
    
    return (ocp, h0, hf)
end

end # module
