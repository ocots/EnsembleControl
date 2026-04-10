"""
Surface Profile Gallery

Display a visual gallery of available surface profiles.
Shows initial and target surfaces side-by-side in 3D.

Usage:
    julia> include("dev_setup.jl")
    julia> include("examples/show_profile_gallery.jl")
"""

println("="^70)
println("Surface Profile Gallery")
println("="^70)

# Create results directory if needed
mkpath("results")

# ============================================================================
# Option 1: Show all profiles
# ============================================================================

println("\nGenerating gallery of all profiles...")
gallery_all = plot_profile_gallery(
    save_path="results/profile_gallery_all.svg"
)
display(gallery_all)

# ============================================================================
# Option 2: Show selected profiles
# ============================================================================

println("\nGenerating gallery of selected profiles...")
selected_profiles = ["flat_with_defect", "gaussian_bump", "random_rough"]
gallery_selected = plot_profile_gallery(
    selected_profiles,
    save_path="results/profile_gallery_selected.svg"
)
display(gallery_selected)

# ============================================================================
# Option 3: Show single profile for detailed view
# ============================================================================

println("\nGenerating detailed view of flat_with_defect...")
gallery_detail = plot_profile_gallery(
    ["flat_with_defect"],
    resolution=100,  # Higher resolution for detail
    save_path="results/profile_flat_with_defect.svg"
)
display(gallery_detail)

println("\n" * "="^70)
println("✓ Galleries generated and saved to results/")
println("  - profile_gallery_all.svg (all profiles)")
println("  - profile_gallery_selected.svg (selected profiles)")
println("  - profile_flat_with_defect.svg (detailed view)")
println("="^70)
