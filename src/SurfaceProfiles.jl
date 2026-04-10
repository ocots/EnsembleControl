"""
    SurfaceProfiles

Module for defining various surface profiles (initial and target pairs).

Follows SOLID principles:
- Single Responsibility: Each profile is a separate function
- Open/Closed: Easy to add new profiles without modifying existing code
- Liskov Substitution: All profiles follow the same interface
- Interface Segregation: Simple function signature (x, y) -> height
- Dependency Inversion: Profiles are independent of the OCP implementation
"""
module SurfaceProfiles

export SurfaceProfile, available_profiles, get_profile
export gaussian_bump, flat_with_defect, saddle_shape, random_rough, wavy_surface
export plot_profile_gallery

# ============================================================================
# Profile Type Definition
# ============================================================================

"""
    SurfaceProfile

Container for a pair of initial and target surface functions.

# Fields
- `name::String`: Profile name
- `description::String`: Profile description
- `initial::Function`: Initial surface function (x, y) -> height
- `target::Function`: Target surface function (x, y) -> height
"""
struct SurfaceProfile
    name::String
    description::String
    initial::Function
    target::Function
end

# ============================================================================
# Profile Catalog
# ============================================================================

"""
    gaussian_bump() -> SurfaceProfile

Gaussian bump to flat surface.

Initial: Gaussian bump centered at origin
Target: Flat surface (height = 0)
"""
function gaussian_bump()
    initial(x, y) = exp(-((x - 0)^2 / (2 * 1) + (y - 0)^2 / (2 * 1)))
    target(x, y) = 0.0
    
    return SurfaceProfile(
        "gaussian_bump",
        "Gaussian bump → flat surface",
        initial,
        target
    )
end

"""
    flat_with_defect() -> SurfaceProfile

Nearly flat surface with a small defect (bump) to perfectly flat.

Initial: Flat surface with a small Gaussian defect in the center
Target: Perfectly flat surface
"""
function flat_with_defect()
    # Small defect: amplitude 0.2, narrow width
    initial(x, y) = 0.2 * exp(-((x - 0)^2 / (2 * 0.1) + (y - 0)^2 / (2 * 0.1)))
    target(x, y) = 0.0
    
    return SurfaceProfile(
        "flat_with_defect",
        "Flat with small defect → perfectly flat",
        initial,
        target
    )
end

"""
    saddle_shape() -> SurfaceProfile

Saddle-shaped surface to flat.

Initial: Hyperbolic paraboloid (saddle)
Target: Flat surface
"""
function saddle_shape()
    initial(x, y) = 0.5 * (x^2 - y^2)
    target(x, y) = 0.0
    
    return SurfaceProfile(
        "saddle_shape",
        "Saddle shape → flat surface",
        initial,
        target
    )
end

"""
    random_rough() -> SurfaceProfile

Random rough surface to smooth target.

Initial: Sum of multiple Gaussian bumps at random locations
Target: Smooth polynomial surface
"""
function random_rough()
    # Multiple defects at different locations
    initial(x, y) = begin
        h = 0.0
        # Defect 1: center
        h += 0.15 * exp(-((x - 0.0)^2 / (2 * 0.15) + (y - 0.0)^2 / (2 * 0.15)))
        # Defect 2: top-right
        h += 0.10 * exp(-((x - 0.5)^2 / (2 * 0.1) + (y - 0.5)^2 / (2 * 0.1)))
        # Defect 3: bottom-left
        h += 0.08 * exp(-((x + 0.5)^2 / (2 * 0.08) + (y + 0.3)^2 / (2 * 0.08)))
        return h
    end
    
    # Smooth target (slight curvature)
    target(x, y) = 0.05 * (1 - x^2 - y^2)
    
    return SurfaceProfile(
        "random_rough",
        "Multiple defects → smooth curved surface",
        initial,
        target
    )
end

"""
    wavy_surface() -> SurfaceProfile

Wavy surface to flat.

Initial: Sinusoidal waves
Target: Flat surface
"""
function wavy_surface()
    initial(x, y) = 0.2 * (sin(3π * x) * sin(3π * y))
    target(x, y) = 0.0
    
    return SurfaceProfile(
        "wavy_surface",
        "Wavy surface → flat",
        initial,
        target
    )
end

# ============================================================================
# Profile Registry
# ============================================================================

"""
    available_profiles() -> Dict{String, SurfaceProfile}

Get dictionary of all available surface profiles.

# Returns
- `Dict{String, SurfaceProfile}`: Map of profile names to profiles
"""
function available_profiles()
    profiles = [
        gaussian_bump(),
        flat_with_defect(),
        saddle_shape(),
        random_rough(),
        wavy_surface()
    ]
    
    return Dict(p.name => p for p in profiles)
end

"""
    get_profile(name::String) -> SurfaceProfile

Get a surface profile by name.

# Arguments
- `name::String`: Profile name (e.g., "gaussian_bump", "flat_with_defect")

# Returns
- `SurfaceProfile`: The requested profile

# Throws
- `ArgumentError`: If profile name is not found

# Example
```julia
profile = get_profile("flat_with_defect")
h_init = profile.initial(0.5, 0.5)
h_target = profile.target(0.5, 0.5)
```
"""
function get_profile(name::String)
    profiles = available_profiles()
    
    if !haskey(profiles, name)
        available = join(keys(profiles), ", ")
        throw(ArgumentError("Profile '$name' not found. Available profiles: $available"))
    end
    
    return profiles[name]
end

"""
    list_profiles()

Print all available profiles with descriptions.
"""
function list_profiles()
    println("Available Surface Profiles:")
    println("=" ^ 70)
    
    for (name, profile) in available_profiles()
        println("  • $name")
        println("    $(profile.description)")
        println()
    end
end

# ============================================================================
# Visualization
# ============================================================================

using Plots

"""
    plot_profile_gallery(profile_names::Vector{String}; 
                        domain=(-1.0, 1.0), 
                        resolution=50,
                        save_path=nothing)

Create a gallery of surface profiles showing initial and target surfaces in 3D.

Each row shows one profile with:
- Left: Initial surface (3D)
- Right: Target surface (3D)

# Arguments
- `profile_names::Vector{String}`: List of profile names to display
- `domain::Tuple{Float64,Float64}`: Domain limits (default: (-1, 1))
- `resolution::Int`: Grid resolution for 3D plots (default: 50)
- `save_path::Union{String,Nothing}`: Optional path to save the gallery (e.g., "gallery.svg")

# Returns
- Plot object with the gallery layout

# Example
```julia
# Show all profiles
plot_profile_gallery(["gaussian_bump", "flat_with_defect", "saddle_shape"])

# Show specific profiles
plot_profile_gallery(["flat_with_defect", "random_rough"])

# Save to file
plot_profile_gallery(["flat_with_defect"], save_path="results/profile_gallery.svg")
```
"""
function plot_profile_gallery(profile_names::Vector{String}; 
                             domain=(-1.0, 1.0), 
                             resolution=50,
                             save_path=nothing)
    
    n_profiles = length(profile_names)
    
    if n_profiles == 0
        throw(ArgumentError("profile_names cannot be empty"))
    end
    
    # Create grid for evaluation
    x_range = range(domain[1], domain[2], length=resolution)
    y_range = range(domain[1], domain[2], length=resolution)
    
    # Create layout: n_profiles rows × 2 columns
    plots_array = []
    
    for profile_name in profile_names
        profile = get_profile(profile_name)
        
        # Evaluate surfaces
        z_initial = [profile.initial(x, y) for y in y_range, x in x_range]
        z_target = [profile.target(x, y) for y in y_range, x in x_range]
        
        # Initial surface (left)
        p_init = surface(x_range, y_range, z_initial,
                        title="$(profile_name)\nInitial",
                        xlabel="x", ylabel="y", zlabel="height",
                        color=:viridis,
                        camera=(30, 60),
                        titlefontsize=10,
                        labelfontsize=8)
        
        # Target surface (right)
        p_target = surface(x_range, y_range, z_target,
                          title="$(profile_name)\nTarget",
                          xlabel="x", ylabel="y", zlabel="height",
                          color=:plasma,
                          camera=(30, 60),
                          titlefontsize=10,
                          labelfontsize=8)
        
        push!(plots_array, p_init)
        push!(plots_array, p_target)
    end
    
    # Create gallery layout
    gallery = plot(plots_array..., 
                   layout=(n_profiles, 2),
                   size=(800, 400 * n_profiles),
                   plot_title="Surface Profile Gallery",
                   plot_titlefontsize=14)
    
    # Save if requested
    if !isnothing(save_path)
        savefig(gallery, save_path)
        println("Gallery saved to: $save_path")
    end
    
    return gallery
end

"""
    plot_profile_gallery()

Show gallery of all available profiles.
"""
function plot_profile_gallery(; kwargs...)
    all_names = collect(keys(available_profiles()))
    return plot_profile_gallery(all_names; kwargs...)
end

end # module
