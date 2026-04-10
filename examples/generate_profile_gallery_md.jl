"""
Generate Profile Gallery Markdown

Creates a markdown document displaying all surface profiles.
Run generate_profile_figures.jl first to create the images.

Usage:
    julia> include("dev_setup.jl")
    julia> include("examples/generate_profile_figures.jl")  # First!
    julia> include("examples/generate_profile_gallery_md.jl")
"""

using Dates

println("="^70)
println("Generating Profile Gallery Markdown")
println("="^70)

# Get all profiles
all_profiles = available_profiles()
profile_names = sort(collect(keys(all_profiles)))

# Build markdown content
md_content = """
# Surface Profile Gallery

**Generated on**: $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS"))

This gallery shows all available surface profiles for the polishing optimization problem.
Each profile consists of an **initial surface** (to be polished) and a **target surface** (desired result).

## Overview

$(length(profile_names)) profiles available:

"""

# Add profile list
for profile_name in profile_names
    profile = all_profiles[profile_name]
    global md_content *= "- **`$profile_name`**: $(profile.description)\n"
end

md_content *= """

---

## Profile Details

"""

# Add each profile with its figures
for profile_name in profile_names
    profile = all_profiles[profile_name]
    
    global md_content *= """
### $profile_name

**Description**: $(profile.description)

#### 2D Views (Filled Contours)

<table>
<tr>
<td width="50%">

**Initial Surface**

![$(profile_name) Initial 2D](profiles/$(profile_name)_initial_2d.svg)

</td>
<td width="50%">

**Target Surface**

![$(profile_name) Target 2D](profiles/$(profile_name)_target_2d.svg)

</td>
</tr>
</table>

#### 3D Views

<table>
<tr>
<td width="50%">

**Initial Surface (3D)**

![$(profile_name) Initial 3D](profiles/$(profile_name)_initial_3d.svg)

</td>
<td width="50%">

**Target Surface (3D)**

![$(profile_name) Target 3D](profiles/$(profile_name)_target_3d.svg)

</td>
</tr>
</table>

---

"""
end

# Add usage section
md_content *= """
## Usage

To use a profile in your optimization:

```julia
# Load development environment
include("dev_setup.jl")

# Choose a profile
profile = get_profile("flat_with_defect")  # or any other profile name

# Create configuration with the profile
config = PolishingConfig(
    grid_size = (10, 10),
    initial_surface = profile.initial,
    target_surface = profile.target,
    # ... other parameters
)

# Run optimization
include("examples/run_polishing.jl")
```

## Profile Comparison

| Profile | Initial Shape | Target Shape | Difficulty |
|---------|--------------|--------------|------------|
| `gaussian_bump` | Large Gaussian bump | Flat | Medium |
| `flat_with_defect` | Small defect on flat | Flat | Easy |
| `saddle_shape` | Hyperbolic paraboloid | Flat | Hard |
| `random_rough` | Multiple bumps | Smooth curve | Hard |
| `wavy_surface` | Sinusoidal waves | Flat | Medium |

## Adding Custom Profiles

You can define custom surfaces directly in your configuration:

```julia
# Custom initial surface
my_initial(x, y) = 0.3 * exp(-((x - 0.2)^2 + (y + 0.3)^2) / 0.05)

# Custom target surface
my_target(x, y) = 0.0  # Flat

config = PolishingConfig(
    initial_surface = my_initial,
    target_surface = my_target,
    # ...
)
```

Or add a new profile to `src/SurfaceProfiles.jl` following the existing pattern.

## Regenerating This Gallery

To regenerate this gallery with updated profiles:

```julia
julia> include("dev_setup.jl")
julia> include("examples/generate_profile_figures.jl")
julia> include("examples/generate_profile_gallery_md.jl")
```

---

*This gallery was automatically generated from the surface profile catalog.*
"""

# Save markdown file
output_file = "results/PROFILE_GALLERY.md"
open(output_file, "w") do f
    write(f, md_content)
end

println()
println("✓ Markdown gallery generated successfully!")
println("  Output file: $output_file")
println()
println("Profiles included:")
for profile_name in profile_names
    println("  • $profile_name")
end
println()
println("="^70)
println("To view the gallery, open: $output_file")
println("="^70)
