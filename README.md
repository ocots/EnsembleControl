# Surface Polishing Optimal Control

Optimal control problem for surface polishing using a moving nozzle.

## Quick Start

### 1. Setup Development Environment

```julia
julia --project=.
```

```julia
julia> include("dev_setup.jl")
```

### 2. Run Example

```julia
julia> include("examples/run_polishing.jl")
```

### 3. View Surface Profile Gallery

```julia
julia> include("examples/build_profile_gallery.jl")
```

This generates a visual gallery of all available surface profiles.

### 4. Generate Report

```julia
julia> include("examples/generate_report.jl")
```

Results are saved in `results/` directory.

## Project Structure

```text
.
├── src/
│   ├── SurfaceProfiles.jl        # Surface profile catalog
│   ├── PolishingProblem.jl       # Problem definition and OCP setup
│   └── PolishingVisualization.jl # Plotting functions
├── examples/
│   ├── run_polishing.jl          # Main execution script
│   ├── generate_report.jl        # Report generator
│   ├── build_profile_gallery.jl  # Generate profile gallery
│   ├── generate_profile_figures.jl
│   └── generate_profile_gallery_md.jl
├── results/
│   ├── *.svg                     # Generated plots
│   ├── profiles/                 # Profile figures
│   ├── RESULTS.md                # Numerical results report
│   └── PROFILE_GALLERY.md        # Surface profile gallery
├── docs/
│   └── SURFACE_PROFILES.md       # Profile documentation
├── dev_setup.jl                  # Development environment setup
└── save/                         # Archived files

```

## Problem Description

**State**: Nozzle position $(s_1, s_2)$ and surface heights $h_i$ at grid points

**Control**: Nozzle velocity $(u_1, u_2)$

**Dynamics**:

- $\dot{s}_1 = u_1$, $\dot{s}_2 = u_2$
- $\dot{h}_i = f(x_i, y_i, s_1, s_2)$ (Gaussian polishing function)

**Objective**: Minimize surface error + control effort

$$J = \sum_i (h_i(t_f) - h_f^i)^2 + 10^{-3} \int_0^{t_f} (u_1^2 + u_2^2) \, dt$$

**Constraints**:

- Workspace: $-1 \leq s_1, s_2 \leq 1$
- Control: $u_1^2 + u_2^2 \leq 1$
- Time bounds: $5 \leq t_f \leq 30$

## Surface Profiles

Choose from 5 predefined surface profiles:

- **`gaussian_bump`** - Large Gaussian bump → flat
- **`flat_with_defect`** ⭐ - Small defect on flat → perfectly flat (recommended)
- **`saddle_shape`** - Saddle shape → flat
- **`random_rough`** - Multiple defects → smooth curve
- **`wavy_surface`** - Sinusoidal waves → flat

View the complete gallery:
```julia
julia> include("examples/build_profile_gallery.jl")
```

## Configuration

Edit `examples/run_polishing.jl` to change:

- Surface profile (default: `flat_with_defect`)
- Grid size (default: 10×10)
- Nozzle parameters (amplitude, width)
- Solver options (grid_size, tolerance, max_iter)

## Dependencies

- Julia 1.12+
- OptimalControl.jl
- Plots.jl
- NLPModelsIpopt
- OrdinaryDiffEq.jl

## Workflow with Revise

The development setup uses Revise.jl for interactive development:

1. Load environment once: `include("dev_setup.jl")`
2. Modify source files in `src/`
3. Re-run examples - changes auto-reload!

No need to restart Julia for most changes.

## Results

After running `generate_report.jl`, check:

- `results/RESULTS.md` - Full report with figures
- `results/*.svg` - Individual plots (2D and 3D)

## Archive

Old files and documentation are in `save/` directory.
