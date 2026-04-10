# Development Workflow with Revise

## Quick Start

### First Time Setup

1. **Start Julia in the project directory:**
   ```bash
   cd /Users/ocots/Research/ensemble_control/EnsembleControl
   julia --project=.
   ```

2. **Load the development environment:**
   ```julia
   julia> include("dev_setup.jl")
   ```
   
   This will:
   - Activate the project environment
   - Load Revise
   - Load your modules with auto-reload enabled
   - Import all necessary packages

3. **Run the example:**
   ```julia
   julia> include("examples/run_polishing.jl")
   ```

### Interactive Development

Once `dev_setup.jl` is loaded, you can:

1. **Modify source files** (`src/PolishingProblem.jl`, `src/PolishingVisualization.jl`)
2. **Re-run the example** without restarting Julia:
   ```julia
   julia> include("examples/run_polishing.jl")
   ```
3. **Changes are automatically picked up** by Revise!

### What Gets Auto-Reloaded?

✅ **Auto-reloaded:**
- Function definitions in `src/PolishingProblem.jl`
- Function definitions in `src/PolishingVisualization.jl`
- Docstrings
- Method additions

❌ **Requires restart:**
- Struct definitions (changing fields)
- Module-level constants
- Export statements (sometimes)

## File Structure

```
EnsembleControl/
├── dev_setup.jl              # Load this first for development
├── examples/
│   └── run_polishing.jl      # Main example script
├── src/
│   ├── PolishingProblem.jl   # Core problem definition
│   └── PolishingVisualization.jl  # Plotting functions
├── mirroir.jl                # Original notebook translation
└── mirroir_refactored.jl     # Standalone refactored version
```

## Typical Workflow

```julia
# === Session Start ===
julia> include("dev_setup.jl")
✓ Development environment loaded with Revise
✓ Modules: PolishingProblem, PolishingVisualization
✓ You can now modify source files and changes will auto-reload

# === First Run ===
julia> include("examples/run_polishing.jl")
Creating grid...
Grid created with 25 points
...
✓ Simulation complete!

# === Modify src/PolishingProblem.jl in your editor ===
# (e.g., change a parameter, add a println, etc.)

# === Re-run (changes auto-loaded!) ===
julia> include("examples/run_polishing.jl")
Creating grid...
Grid created with 25 points
...
✓ Simulation complete!

# === Continue iterating... ===
```

## Tips

### 1. Check what Revise is tracking
```julia
julia> using Revise
julia> Revise.watched_files
```

### 2. Force a manual revision
```julia
julia> Revise.revise()
```

### 3. If something seems stuck
```julia
julia> Revise.revise()  # Force update
julia> include("examples/run_polishing.jl")  # Re-run
```

### 4. If you change struct definitions
You'll need to restart Julia:
```julia
julia> exit()
$ julia --project=.
julia> include("dev_setup.jl")
```

## Alternative: Using includet directly

If you prefer not to use `dev_setup.jl`, you can use `includet` directly:

```julia
using Pkg
Pkg.activate(@__DIR__)
using Revise

# Load with tracking
includet("src/PolishingProblem.jl")
includet("src/PolishingVisualization.jl")

using .PolishingProblem
using .PolishingVisualization

# Now work interactively
```

## Troubleshooting

### "UndefVarError: create_grid not defined"
- Make sure you ran `dev_setup.jl` first
- Check that modules are loaded: `using .PolishingProblem`

### "Module PolishingProblem not found"
- Make sure you're in the correct directory
- Run `include("dev_setup.jl")` again

### Changes not being picked up
- Run `Revise.revise()` manually
- Check if you modified a struct (requires restart)
- Make sure you're editing the right file

### "World age" errors
- This happens when you redefine functions in the REPL
- Usually fixed by re-running your code
- If persistent, restart Julia

## Performance Note

Revise adds a small overhead (~100ms) when checking for file changes. This is negligible for interactive development but if you're running benchmarks, you might want to use the standalone `mirroir_refactored.jl` instead.

## See Also

- [Revise.jl Documentation](https://timholy.github.io/Revise.jl/stable/)
- [Julia Workflow Tips](https://docs.julialang.org/en/v1/manual/workflow-tips/)
