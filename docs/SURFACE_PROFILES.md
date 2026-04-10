# Surface Profiles Guide

## Overview

The `SurfaceProfiles` module provides a catalog of predefined surface pairs (initial → target) for polishing optimization.

## Available Profiles

### 1. `gaussian_bump`
**Description**: Gaussian bump → flat surface

- **Initial**: Gaussian bump centered at origin (like a sail)
- **Target**: Perfectly flat (height = 0)
- **Use case**: Classic polishing problem, removing a large bump

### 2. `flat_with_defect` ⭐ **Recommended for your case**
**Description**: Flat with small defect → perfectly flat

- **Initial**: Nearly flat surface with a small Gaussian defect in the center
- **Target**: Perfectly flat (height = 0)
- **Use case**: Removing a small imperfection from an otherwise flat surface
- **Parameters**: Defect amplitude = 0.2, width = 0.1

### 3. `saddle_shape`
**Description**: Saddle shape → flat surface

- **Initial**: Hyperbolic paraboloid (saddle-shaped)
- **Target**: Perfectly flat
- **Use case**: Complex curvature correction

### 4. `random_rough`
**Description**: Multiple defects → smooth curved surface

- **Initial**: Multiple Gaussian bumps at different locations
- **Target**: Smooth polynomial surface
- **Use case**: Rough surface polishing to smooth finish

### 5. `wavy_surface`
**Description**: Wavy surface → flat

- **Initial**: Sinusoidal waves
- **Target**: Perfectly flat
- **Use case**: Removing periodic patterns

## Usage

### Basic Usage

```julia
# Load development environment
include("dev_setup.jl")

# List all available profiles
SurfaceProfiles.list_profiles()

# Get a specific profile
profile = get_profile("flat_with_defect")

# Use in configuration
config = PolishingConfig(
    grid_size = (10, 10),
    initial_surface = profile.initial,
    target_surface = profile.target,
    # ... other parameters
)
```

### In `run_polishing.jl`

```julia
# Choose profile (line 29)
profile = get_profile("flat_with_defect")

# Configuration automatically uses the profile
config = PolishingConfig(
    initial_surface = profile.initial,
    target_surface = profile.target,
    # ...
)
```

### Creating Custom Profiles

You can also define custom surfaces directly:

```julia
# Custom initial surface: flat with two defects
my_initial(x, y) = begin
    defect1 = 0.15 * exp(-((x - 0.3)^2 + (y - 0.3)^2) / 0.02)
    defect2 = 0.10 * exp(-((x + 0.4)^2 + (y - 0.2)^2) / 0.01)
    return defect1 + defect2
end

# Custom target: slightly curved
my_target(x, y) = 0.05 * (1 - x^2 - y^2)

config = PolishingConfig(
    initial_surface = my_initial,
    target_surface = my_target,
    # ...
)
```

## Profile Characteristics

| Profile | Initial Shape | Target Shape | Difficulty |
|---------|--------------|--------------|------------|
| `gaussian_bump` | Large bump | Flat | Medium |
| `flat_with_defect` | Small defect | Flat | Easy |
| `saddle_shape` | Saddle | Flat | Hard |
| `random_rough` | Multiple bumps | Curved | Hard |
| `wavy_surface` | Waves | Flat | Medium |

## Design Principles

The surface profile system follows SOLID principles:

- **Single Responsibility**: Each profile is self-contained
- **Open/Closed**: Easy to add new profiles without modifying existing code
- **Liskov Substitution**: All profiles follow the same interface
- **Interface Segregation**: Simple function signature `(x, y) -> height`
- **Dependency Inversion**: Profiles are independent of OCP implementation

## Examples

### Example 1: Flat with Defect (Your Use Case)

```julia
profile = get_profile("flat_with_defect")
config = PolishingConfig(
    initial_surface = profile.initial,
    target_surface = profile.target
)
```

This gives you:
- Initial: Mostly flat with a small bump (amplitude 0.2, width 0.1)
- Target: Perfectly flat
- Perfect for simulating imperfection removal

### Example 2: Multiple Defects

```julia
profile = get_profile("random_rough")
config = PolishingConfig(
    initial_surface = profile.initial,
    target_surface = profile.target
)
```

This gives you:
- Initial: 3 defects at different locations
- Target: Smooth curved surface
- Good for testing complex polishing scenarios

### Example 3: Custom Profile

```julia
# Very flat with tiny defect
tiny_defect(x, y) = 0.05 * exp(-((x)^2 + (y)^2) / 0.005)
flat(x, y) = 0.0

config = PolishingConfig(
    initial_surface = tiny_defect,
    target_surface = flat
)
```

## Visualization

All profiles can be visualized using the standard plotting functions:

```julia
# After creating config with your chosen profile
p_init, p_target = plot_surfaces(config)
display(p_init)
display(p_target)

# 3D view
p_init_3d, p_target_3d = plot_surfaces_3d(config)
display(p_init_3d)
display(p_target_3d)
```

## Adding New Profiles

To add a new profile to the catalog:

1. Edit `src/SurfaceProfiles.jl`
2. Add a new function following the pattern:

```julia
function my_new_profile()
    initial(x, y) = # your initial surface formula
    target(x, y) = # your target surface formula
    
    return SurfaceProfile(
        "my_new_profile",
        "Description of initial → target",
        initial,
        target
    )
end
```

3. Add it to `available_profiles()`:

```julia
function available_profiles()
    profiles = [
        gaussian_bump(),
        flat_with_defect(),
        # ... existing profiles
        my_new_profile()  # Add here
    ]
    
    return Dict(p.name => p for p in profiles)
end
```

4. The new profile is immediately available via `get_profile("my_new_profile")`

## Tips

- Start with `flat_with_defect` for your use case (flat with imperfection)
- Use `list_profiles()` to see all available options
- Visualize profiles before running optimization
- Adjust defect size by modifying amplitude and width in custom profiles
- For very small defects, reduce `nozzle_amplitude` in config
