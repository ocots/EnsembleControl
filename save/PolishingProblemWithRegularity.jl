"""
Example: OCP with spatial regularity constraint

This shows how to add spatial smoothness to the objective.
"""

# Add this to your OCP definition:

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

# Modified OCP with smoothness
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
    
    # Time bounds
    5 ≤ tf ≤ 30
    
    # Dynamics
    ẋ(t) == state_dynamics(s₁(t), s₂(t), u₁(t), u₂(t), grid, config)
    
    # Multi-objective:
    # 1. Track target surface (Mayer term)
    # 2. Minimize control effort + spatial smoothness (Lagrange term)
    sum((h(x(tf)) .- hf).^2) + 
    ∫(1e-3 * (u₁(t)^2 + u₂(t)^2) + 1e-4 * spatial_gradient_penalty(h(x(t)), grid)) → min
end

# Note: You need to make spatial_gradient_penalty available in the OCP scope
# This might require defining it as a closure or passing grid differently
