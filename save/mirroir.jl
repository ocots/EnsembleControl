using Pkg
Pkg.activate(@__DIR__)
Pkg.add("OptimalControl")
Pkg.add("Plots")
Pkg.add("NLPModelsIpopt")
Pkg.add("OrdinaryDiffEq")

using OptimalControl
using Plots
using NLPModelsIpopt
using OrdinaryDiffEq

# Grid
n = 5; m = 5;
grid = zeros(2, n*m)
x_span = range(-1, 1, length=n)
y_span = range(-1, 1, length=m)
k = 1
for xi ∈ x_span
    for yi ∈ y_span
        grid[1, k] = xi
        grid[2, k] = yi
        k = k + 1        
    end
end

# Polishing function at point (x,y) with the nozzle centered at (sx,sy) 
f(x,y,sx,sy; A = 0.1, σx = 0.05, σy = 0.01) = -A * exp(- ((x - sx)^2/(2*σx) + (y - sy)^2/(2*σy)))
# Initial surface
surf_init(x,y) = 1*exp(- ((x - 0)^2/(2*1) + (y - 0)^2/(2*1)))
# Flow
function surface(t,x,y,u,X0)
    # X = [sx, sy, h]
    lhs(t,X) = [u(t)[1], u(t)[2], f(x,y,X[1],X[2])]  
    ϕ = Flow(lhs; autonomous = false)
    return ϕ(0, X0, t)
end
u_ref(t) = [0.1, 0]
tf = 15
s0 = [-1, 0]
surf_final(x,y) = surface(tf, x, y, u_ref, [s0[1], s0[2], surf_init(x,y)])[3]

# Number of grid points
nb_pts = size(grid,2)
# State dynamics
F(sx,sy, u1, u2) = [u1; u2 ;[f(grid[1,i],grid[2,i],sx,sy) for i ∈ 1:nb_pts]]
# Initial and final height conditions on grid
h0 = [surf_init(grid[1,i], grid[2,i]) for i ∈1:nb_pts]
hf = [surf_final(grid[1,i], grid[2,i]) for i ∈1:nb_pts]
nothing

x = range(-1, 1, length=100)
y = range(-1, 1, length=100)
z_initial = @. surf_init(x', y)
z_final = @. surf_final(x', y)
contour(x, y, z_initial, title = "Initial surface")

contour(x, y, z_final, title = "Final simulated surface")

h(x) = x[3:end]

ocp = @def begin
    tf ∈ R,             variable    
    t ∈ [0, tf],        time
    x ∈ R^(2+nb_pts),   state
    u ∈ R²,             control

    s₁ = x[1]
    s₂ = x[2]

    s₁(0) == s0[1]
    s₂(0) == s0[2]
    h(x(0)) == h0

    -1 ≤ s₁(t) ≤ 1
    -1 ≤ s₂(t) ≤ 1
    u₁(t)^2 + u₂(t)^2 ≤ 1

    ẋ(t) == F(s₁(t), s₂(t), u₁(t), u₂(t))

    sum((h(x(tf)) .- hf).^2) → min
end

sol = solve(ocp)

x = state(sol)
s(t) = x(t)[1:2] 
u = control(sol)
t = time_grid(sol)
tf = t[end]
println(tf)

plot(t, t -> u(t)[1]^2 + u(t)[2]^2, label = "||u||")

plt = plot(t, t -> s(t)[1], label = "s1")
plot!(plt, t,  t -> s(t)[2], label = "s2")

# # Grid
x = range(-1, 1, length=100)
y = range(-1, 1, length=100)
z = @. surf_init(x', y)
contour(x, y, z, title = "Initial surface")
scatter!(grid[1,:], grid[2,:], label = false)

buse_centree(x,y) = f(x,y, 0, 0)
x = range(-1, 1, length=100)
y = range(-1, 1, length=100)
z = @. buse_centree(x', y)

contour(x, y, z, title = "Centered nozzle")
# scatter!(grid[1,:], grid[2,:], label = false)

function surf(t,x,y,state; surf_init = surf_init)
    s0 = surf_init(x,y)
    ϕ = Flow((t, s) -> f(x,y,state(t)[1], state(t)[2]); autonomous = false)
    return ϕ(0, s0, t)
end

surf_final(x,y) = surf(tf,x,y,t -> state(sol)(t)[1:2])
cost = [surf_final(grid[1,i], grid[2,i]) for i ∈ 1:size(grid,2)]
println(cost)
# # Grid
x = range(-1, 1, length=50)
y = range(-1, 1, length=50)
z = @. surf_final(x', y)
contour(x, y, z)
plot!(t -> state(sol)(t)[1], t ->state(sol)(t)[2], 0, tf)
scatter!(grid[1,:], grid[2,:], label = false)
