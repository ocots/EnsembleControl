"""
Generate Individual Profile Figures

Creates separate SVG files for each surface profile (initial and target).
These figures are then used in the profile gallery markdown.

Usage:
    julia> include("dev_setup.jl")
    julia> include("examples/generate_profile_figures.jl")
"""

using Plots

println("="^70)
println("Generating Surface Profile Figures")
println("="^70)

# Create output directory
output_dir = "results/profiles"
mkpath(output_dir)

# Domain and resolution settings
domain = (-1.0, 1.0)
resolution_2d = 100
resolution_3d = 50

x_range = range(domain[1], domain[2], length=resolution_2d)
y_range = range(domain[1], domain[2], length=resolution_2d)
x_range_3d = range(domain[1], domain[2], length=resolution_3d)
y_range_3d = range(domain[1], domain[2], length=resolution_3d)

# Get all profiles
all_profiles = available_profiles()
profile_names = sort(collect(keys(all_profiles)))

println("\nGenerating figures for $(length(profile_names)) profiles...")
println()

for profile_name in profile_names
    println("Processing: $profile_name")
    profile = all_profiles[profile_name]
    
    # Evaluate surfaces
    z_initial_2d = @. profile.initial(x_range', y_range)
    z_target_2d = @. profile.target(x_range', y_range)
    z_initial_3d = [profile.initial(x, y) for y in y_range_3d, x in x_range_3d]
    z_target_3d = [profile.target(x, y) for y in y_range_3d, x in x_range_3d]
    
    # === 2D Filled Contours ===
    
    # Initial 2D
    p_init_2d = contourf(x_range, y_range, z_initial_2d,
                         title="$profile_name - Initial",
                         xlabel="x", ylabel="y",
                         color=:viridis,
                         levels=20,
                         size=(400, 350))
    savefig(p_init_2d, joinpath(output_dir, "$(profile_name)_initial_2d.svg"))
    
    # Target 2D
    p_target_2d = contourf(x_range, y_range, z_target_2d,
                           title="$profile_name - Target",
                           xlabel="x", ylabel="y",
                           color=:plasma,
                           levels=20,
                           size=(400, 350))
    savefig(p_target_2d, joinpath(output_dir, "$(profile_name)_target_2d.svg"))
    
    # === 3D Surfaces ===
    
    # Initial 3D
    p_init_3d = surface(x_range_3d, y_range_3d, z_initial_3d,
                        title="$profile_name - Initial (3D)",
                        xlabel="x", ylabel="y", zlabel="height",
                        color=:viridis,
                        camera=(30, 60),
                        size=(400, 350))
    savefig(p_init_3d, joinpath(output_dir, "$(profile_name)_initial_3d.svg"))
    
    # Target 3D
    p_target_3d = surface(x_range_3d, y_range_3d, z_target_3d,
                          title="$profile_name - Target (3D)",
                          xlabel="x", ylabel="y", zlabel="height",
                          color=:plasma,
                          camera=(30, 60),
                          size=(400, 350))
    savefig(p_target_3d, joinpath(output_dir, "$(profile_name)_target_3d.svg"))
    
    println("  ✓ Generated 4 figures (2D + 3D, initial + target)")
end

println()
println("="^70)
println("✓ All figures generated successfully!")
println("  Output directory: $output_dir")
println("  Total files: $(length(profile_names) * 4)")
println()
println("Files generated:")
for profile_name in profile_names
    println("  • $(profile_name)_initial_2d.svg")
    println("  • $(profile_name)_target_2d.svg")
    println("  • $(profile_name)_initial_3d.svg")
    println("  • $(profile_name)_target_3d.svg")
end
println("="^70)
