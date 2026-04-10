# Surface Polishing Optimal Control Problem

## Problem Statement

We consider an optimal control problem for surface polishing, where a nozzle moves over a surface to achieve a desired final shape through material removal.

## Mathematical Formulation

### State Variables

The state vector is $x(t) \in \mathbb{R}^{2+n}$ where:

- $s_1(t), s_2(t)$: Position of the nozzle center in the $(x,y)$ plane
- $h_i(t)$, $i=1,\ldots,n$: Surface heights at $n$ grid points

### Control Variables

The control vector is $u(t) \in \mathbb{R}^2$ where:

- $u_1(t), u_2(t)$: Velocity components of the nozzle

### Dynamics

The system dynamics are given by:

$$\dot{s}_1(t) = u_1(t)$$

$$\dot{s}_2(t) = u_2(t)$$

$$\dot{h}_i(t) = f(x_i, y_i, s_1(t), s_2(t)), \quad i=1,\ldots,n$$

where $f(x,y,s_x,s_y)$ is the **polishing function** modeling material removal:

$$f(x,y,s_x,s_y) = -A \exp\left(-\frac{(x-s_x)^2}{2\sigma_x} - \frac{(y-s_y)^2}{2\sigma_y}\right)$$

with:

- $A = 0.1$: Polishing amplitude (material removal rate)
- $\sigma_x = 0.05$: Nozzle width in $x$ direction
- $\sigma_y = 0.01$: Nozzle width in $y$ direction

This Gaussian model represents the localized material removal effect of the polishing nozzle.

### Initial Conditions

- **Nozzle position**: $s_1(0) = -1$, $s_2(0) = 0$
- **Initial surface**: $h_i(0) = \exp\left(-\frac{x_i^2}{2} - \frac{y_i^2}{2}\right)$ (Gaussian bump)

### Target Surface

The target final surface $h_f$ is computed by simulating a reference trajectory:

- Reference control: $u_{ref}(t) = [0.1, 0]$ (constant velocity)
- Reference time: $t_f^{ref} = 15$

### Constraints

**State constraints** (nozzle workspace):

$$-1 \leq s_1(t) \leq 1$$

$$-1 \leq s_2(t) \leq 1$$

**Control constraint** (velocity limit):

$$u_1(t)^2 + u_2(t)^2 \leq 1$$

### Objective Function

Minimize the weighted sum of:

1. **Surface error** (primary objective):
   $$\sum_{i=1}^n (h_i(t_f) - h_f^i)^2$$

2. **Control effort** (regularization):
   $$10^{-3} \int_0^{t_f} (u_1(t)^2 + u_2(t)^2) \, dt$$

The complete objective is:

$$J = \sum_{i=1}^n (h_i(t_f) - h_f^i)^2 + 10^{-3} \int_0^{t_f} (u_1(t)^2 + u_2(t)^2) \, dt \to \min$$

### Free Final Time

The final time $t_f$ is a **free variable** to be optimized.

## Discretization

The surface is discretized on a **5×5 grid** in the domain $[-1, 1] \times [-1, 1]$, giving $n = 25$ grid points.

## Numerical Results

### Initial Surface

The initial surface is a Gaussian bump centered at the origin:

![Initial Surface](results/01_initial_surface.svg)

### Target Surface

The target surface is obtained by simulating the reference trajectory:

![Target Surface](results/02_target_surface.svg)

### Grid Discretization

The surface is discretized on 25 grid points:

![Grid with Surface](results/03_grid_with_surface.svg)

### Nozzle Effect

The polishing effect of a centered nozzle (Gaussian material removal):

![Nozzle Effect](results/04_nozzle_effect.svg)

## Optimal Solution

### Control Norm

Evolution of the control norm $\|u(t)\|^2$ over time:

![Control Norm](results/05_control_norm.svg)

The control stays within the constraint $\|u\|^2 \leq 1$.

### Optimal Trajectory

The optimal nozzle trajectory $(s_1(t), s_2(t))$:

![Trajectory](results/06_trajectory.svg)

### Final Result

The final achieved surface with the optimal trajectory overlaid:

![Final Result](results/07_final_result.svg)

The red curve shows the optimal path of the nozzle, and the contours show the final surface shape.

## Implementation

The problem is implemented using:

- **OptimalControl.jl**: Problem formulation and solving
- **NLPModelsIpopt**: Interior-point optimization solver
- **OrdinaryDiffEq.jl**: ODE integration for flow computations

### Code Structure

```text
src/
├── PolishingProblem.jl       # Problem definition, physics, OCP setup
└── PolishingVisualization.jl # Plotting and visualization

examples/
└── run_polishing.jl          # Main execution script

results/
└── *.png                     # Generated plots
```

## Physical Interpretation

1. **Polishing Process**: The nozzle removes material according to a Gaussian profile
2. **Optimization Goal**: Find the best path to transform the initial surface into the target shape
3. **Trade-off**: Balance between achieving the target surface and minimizing control effort
4. **Constraint**: The nozzle must stay within the workspace and respect velocity limits

## References

- OptimalControl.jl: [https://control-toolbox.org/OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl)
- Related work: Surface polishing optimization, trajectory planning for manufacturing

---

**Generated on**: $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS"))

**Configuration**:

- Grid: 5×5 (25 points)
- Domain: [-1, 1] × [-1, 1]
- Nozzle amplitude: A = 0.1
- Nozzle widths: σₓ = 0.05, σᵧ = 0.01
- Control weight: 10⁻³
