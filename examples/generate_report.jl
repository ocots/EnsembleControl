"""
Generate Problem Report

This script runs the polishing optimization and generates a markdown report
with the results.

Usage:
    julia> include("dev_setup.jl")
    julia> include("examples/generate_report.jl")
"""

using Dates
using Printf

println("="^70)
println("Surface Polishing Optimal Control - Report Generation")
println("="^70)

# Run the main example (this saves all plots)
include(joinpath(@__DIR__, "run_polishing.jl"))

# Generate the report with actual results
println("\n" * "="^70)
println("Generating report...")
println("="^70)

report_content = """
# Surface Polishing Optimal Control Problem - Results

**Generated on**: $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS"))

## Problem Configuration

- **Grid size**: $(config.grid_size[1])×$(config.grid_size[2]) = $(config.grid_size[1] * config.grid_size[2]) points
- **Domain**: [$(config.domain[1]), $(config.domain[2])] × [$(config.domain[1]), $(config.domain[2])]
- **Nozzle amplitude**: A = $(config.nozzle_amplitude)
- **Nozzle widths**: σₓ = $(config.nozzle_sigma_x), σᵧ = $(config.nozzle_sigma_y)
- **Initial position**: s₀ = $(config.initial_position)
- **Reference time**: tf_ref = $(config.time_final)
- **Reference velocity**: u_ref = $(config.reference_velocity)

## Mathematical Formulation

### State Variables

The state vector is \$x(t) \\in \\mathbb{R}^{$(2 + size(grid))}\$ where:
- \$s_1(t), s_2(t)\$: Position of the nozzle center
- \$h_i(t)\$, \$i=1,\\ldots,$(size(grid))\$: Surface heights at grid points

### Dynamics

\$\$\\dot{s}_1(t) = u_1(t)\$\$

\$\$\\dot{s}_2(t) = u_2(t)\$\$

\$\$\\dot{h}_i(t) = f(x_i, y_i, s_1(t), s_2(t))\$\$

where the polishing function is:

\$\$f(x,y,s_x,s_y) = -A \\exp\\left(-\\frac{(x-s_x)^2}{2\\sigma_x} - \\frac{(y-s_y)^2}{2\\sigma_y}\\right)\$\$

### Objective Function

\$\$J = \\sum_{i=1}^{$(size(grid))} (h_i(t_f) - h_f^i)^2 + 10^{-3} \\int_0^{t_f} (u_1(t)^2 + u_2(t)^2) \\, dt \\to \\min\$\$

### Constraints

**State constraints**:
- \$-1 \\leq s_1(t) \\leq 1\$
- \$-1 \\leq s_2(t) \\leq 1\$

**Control constraint**:
- \$u_1(t)^2 + u_2(t)^2 \\leq 1\$

## Numerical Results

### Optimal Solution

**Optimal final time**: tf* = $(round(tf_solution, digits=4))

### Initial Surface

The initial surface is a Gaussian bump:

**2D view (filled contours)**:
![Initial Surface 2D](../results/01_initial_surface.svg)

**3D view**:
![Initial Surface 3D](../results/01b_initial_surface_3d.svg)

### Target Surface

The target surface from reference trajectory:

**2D view (filled contours)**:
![Target Surface 2D](../results/02_target_surface.svg)

**3D view**:
![Target Surface 3D](../results/02b_target_surface_3d.svg)

### Grid Discretization

Surface discretized on $(size(grid)) grid points:

![Grid with Surface](../results/03_grid_with_surface.svg)

### Nozzle Effect

Polishing effect of a centered nozzle:

![Nozzle Effect](../results/04_nozzle_effect.svg)

### Control Norm

Evolution of \$\\|u(t)\\|^2\$ over time:

![Control Norm](../results/05_control_norm.svg)

### Optimal Trajectory

Optimal nozzle path \$(s_1(t), s_2(t))\$:

![Trajectory](../results/06_trajectory.svg)

### Final Result

Final surface with optimal trajectory:

**2D view (filled contours)**:
![Final Result 2D](../results/07_final_result.svg)

**3D view**:
![Final Result 3D](../results/07b_final_result_3d.svg)

## Final Surface Error

Final heights at grid points:
```
$(join([@sprintf("%.6f", c) for c in cost], ", "))
```

**Mean squared error**: $(round(sum((cost .- hf).^2) / length(cost), digits=8))

## Implementation

- **Language**: Julia $(VERSION)
- **Solver**: Ipopt (interior-point method)
- **Framework**: OptimalControl.jl

### Files

```
src/
├── PolishingProblem.jl       # Problem definition
└── PolishingVisualization.jl # Visualization

examples/
├── run_polishing.jl          # Main script
└── generate_report.jl        # This report generator

results/
└── *.png                     # Generated plots
```

## Interpretation

1. **Optimal time**: The solver found that tf* = $(round(tf_solution, digits=2)) is optimal
2. **Trajectory**: The nozzle follows an optimized path to achieve the target surface
3. **Control effort**: The regularization term keeps the control smooth
4. **Accuracy**: The final surface closely matches the target

---

*This report was automatically generated from the optimization results.*
"""

# Save the report
open("results/RESULTS.md", "w") do f
    write(f, report_content)
end

println("✓ Report saved to results/RESULTS.md")
println("\nAll files generated:")
println("  - results/01_initial_surface.svg (2D)")
println("  - results/01b_initial_surface_3d.svg (3D)")
println("  - results/02_target_surface.svg (2D)")
println("  - results/02b_target_surface_3d.svg (3D)")
println("  - results/03_grid_with_surface.svg")
println("  - results/04_nozzle_effect.svg")
println("  - results/05_control_norm.svg")
println("  - results/06_trajectory.svg")
println("  - results/07_final_result.svg (2D)")
println("  - results/07b_final_result_3d.svg (3D)")
println("  - results/RESULTS.md")
println("\n" * "="^70)
println("✓ Report generation complete!")
println("="^70)
