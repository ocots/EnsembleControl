"""
Build Complete Profile Gallery

All-in-one script that:
1. Generates all individual profile figures (2D + 3D)
2. Creates a markdown gallery document

Usage:
    julia> include("dev_setup.jl")
    julia> include("examples/build_profile_gallery.jl")
"""

println("="^70)
println("Building Complete Profile Gallery")
println("="^70)
println()

# Step 1: Generate figures
println("Step 1/2: Generating profile figures...")
println("-"^70)
include(joinpath(@__DIR__, "generate_profile_figures.jl"))

println()
println()

# Step 2: Generate markdown
println("Step 2/2: Generating markdown gallery...")
println("-"^70)
include(joinpath(@__DIR__, "generate_profile_gallery_md.jl"))

println()
println("="^70)
println("✓ Complete profile gallery built successfully!")
println()
println("Generated files:")
println("  • results/profiles/*.svg (individual figures)")
println("  • results/PROFILE_GALLERY.md (markdown gallery)")
println()
println("Next steps:")
println("  1. Open results/PROFILE_GALLERY.md to view the gallery")
println("  2. Choose a profile for your optimization")
println("  3. Edit examples/run_polishing.jl to use your chosen profile")
println("="^70)
