module BallTreeCode
using GreatCircle
export BoundingSphere, Node


type BoundingSphere
    c::Array{Float64}
    r::Float64
    BoundingSphere(c::Array{Float64}, r::Float64) = new(c,r)
end

abstract type GeoPoint end
type Node <: GeoPoint
    id::Int
    point::Vector{Float64}
    Node(i::Int, p::Vector{Float64}) = new(i, p)
end

type BallTree
    node::Node
    left::BallTree
    right::BallTree
    b_sphere::BoundingSphere
    # top down k-d construction
    function BallTree(points::Vector{Node})
        lo = 1 # subtree nodes pointer
        hi = length(points) # subtree nodes pointer
        indices = collect(lo:hi)
        function _ball_tree(points::Vector{Node}, indices::Vector{Int}, lo::Int, hi::Int)
            self = new()
            n_points = hi - lo + 1
            if n_points == 1 
                # leaf node
                self.node = points[indices[lo]]
            elseif n_points > 1
                # split index
                mid = ceil(Integer,n_points/2) + lo - 1 
                # split dimension with greatest spread
                split_dim = get_spread_dim(points, indices, lo, hi)   
                # find the median of the split dimension 
                self.node = select_node!(points, indices, mid, lo, hi, split_dim)    
                # recursive construction    
                self.left = _ball_tree(points,indices,lo, mid-1)         
                self.right = _ball_tree(points,indices,mid+1,hi)  
                if isdefined(self.left, :b_sphere) && isdefined(self.right, :b_sphere)         
                    # bounding sphere of two spheres        
                    self.b_sphere = bounding_sphere(self.left.b_sphere, self.right.b_sphere)     
                else            
                    # smallest enclosing circle        
                    self.b_sphere = bounding_sphere2d(points[indices[lo:hi]])   
                end                                            
            end
            return self
        end
        return _ball_tree(points, indices, lo, hi)
    end
end

# Modified from https://github.com/JuliaLang/julia/blob/v0.3.5/base/sort.jl
@inline function select_node!(points::Vector{Node}, indices::Vector{Int}, k::Int,
                              lo::Int, hi::Int, dim::Int)
  @inbounds lo <= k <= hi || error("select index $k is out of range $lo:$hi")
  while lo < hi
    if hi-lo == 1
      if points[indices[hi]].point[dim] < points[indices[lo]].point[dim]
        indices[lo], indices[hi] = indices[hi], indices[lo]
      end
      return points[indices[k]]
    end
    pivot = indices[(lo+hi)>>>1]
    i, j = lo, hi
    while true
      while points[indices[i]].point[dim] < points[pivot].point[dim]; i += 1; end
      while points[pivot].point[dim] < points[indices[j]].point[dim]; j -= 1; end
      i <= j || break
      indices[i], indices[j] = indices[j], indices[i]
      i += 1; j -= 1
    end
    if k <= j
      hi = j
    elseif i <= k
      lo = i
    else
      return points[pivot]
    end
  end
  return points[indices[lo]]
end

# Get the dimension of maximum spread of data in order to choose that dimension
# as the space splitting dimension.
# @param points: Dataset of nodes
# @param indices: Pointers to nodes in the dataset belonging to actual subtree
# @param lo: Low bound pointer to nodes in subtree
# @param lo: High bound pointer to nodes in subtree
# @return split_dim {Int}: dimension
function get_spread_dim(points::Vector{Node},indices::Vector{Int}, lo::Int, hi::Int)
  n_points = hi - lo + 1
  n_dim = 2
  split_dim = 1
  max_spread = .0
  for dim in 1:n_dim
    xmin = typemax(Float64)
    xmax = typemin(Float64)
    for coordinate in 1:n_points
        xmin = min(xmin, points[indices[coordinate + lo - 1]].point[dim])
        xmax = max(xmax, points[indices[coordinate + lo - 1]].point[dim])
    end
    if xmax - xmin > max_spread
        max_spread = xmax - xmin
        split_dim = dim
    end
  end
  return split_dim
end

# Bounding sphere for two spheres
function bounding_sphere(b1::BoundingSphere, b2::BoundingSphere)
  if encloses(b1, b2)
    return BoundingSphere(b1.c, b1.r)
  elseif encloses(b2, b1)
    return BoundingSphere(b2.c, b2.r)
  end
  d = norm(b1.c - b2.c)
  x = 0.5 * (b2.r - b1.r + d)
  rad = 0.5 * (b2.r + b1.r + d)
  alpha = x / d
  c = (1 - alpha) * b1.c + alpha * b2.c
  return BoundingSphere(c, rad)
end

function two_point_circle(p1::Array{Float64}, p2::Array{Float64})
  c = (p1 + p2) / 2
  r = norm(p1-c)
  return (c, r)
end

function in_circle(p::Array{Float64}, c::Tuple{Array{Float64},Float64})
  return norm(p - c[1]) <= c[2]
end

function circumcircle(p0::Array{Float64}, p1::Array{Float64}, p2::Array{Float64})
    ax = p0[1]
  ay = p0[2]
    bx = p1[1]
  by = p1[2]
    cx = p2[1]
  cy = p2[2]
    d = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) * 2.0
    if d == 0.0
        return
  end
    x = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay -
 by)) / d
    y = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx -
 ax)) / d
    ra = hypot(x - ax, y - ay)
    rb = hypot(x - bx, y - by)
    rc = hypot(x - cx, y - cy)
    return (Float64[x, y], max(ra, rb, rc))
end

function is_left(p1::Array{Float64}, p2::Array{Float64}, p::Array{Float64})
  return sign(det(hcat(p2-p1,p-p1))) > 0 #det(P1P2,P1P)
end

# Smallest enclosing circle for N points
function bounding_sphere2d(p::Vector{Node})
  c = two_point_circle(p[1].point,p[2].point)
  for i=3:length(p)
    if !in_circle(p[i].point, c)
      c = smallest_enclosing_circle1p(p[1:i-1], p[i].point)
    end
  end
  return BoundingSphere(c[1], c[2])
end



# Smallest enclosing circle for a circle and 1 point
function smallest_enclosing_circle1p(points::Vector{Node}, p::Array{Float64})
  c = two_point_circle(p, points[1].point)
  for i=2:length(points)
    if !in_circle(points[i].point, c)
      c = smallest_enclosing_circle2p(points[1:i-1], points[i].point, p)
    end
  end
  return c
end



# Smallest enclosing circle for a circle and 2 points
function smallest_enclosing_circle2p(points::Vector{Node}, p1::Array{Float64}, p2::Array{Float64})
  c0 = two_point_circle(p1,p2)
  c1 = Nullable()
  c2 = Nullable()
  for p in points
    if in_circle(p.point, c0)
      continue
    end
    c = circumcircle(p1, p2, p.point)
    if c == nothing
      continue
    end
    d = det(hcat(p2-p1, c[1]-p1))
    if is_left(p1, p2, p.point) && (isnull(c1) || d > det(hcat(p2-p1, c1[1]-p1)))
      c1 = c
    end
    if !is_left(p1, p2, p.point) && (isnull(c2) || d < det(hcat(p2-p1, c2[1]-p1)))
      c2 = c
    end
  end
  if isnull(c1) && isnull(c2)
    return c0
  elseif isnull(c1)
    return c2
  elseif isnull(c2)
    return c1
  else
    return c1[2] <= c2[2] ? c1 : c2
  end
end

# Obtain the nodes of a given ball trajectories
# @param t: ball tree or subtree in a ball tree
# @return nodes {Vector{Node}}
function collect_nodes(t::BallTree)
  nodes = Node[]
  _collect_nodes(t,nodes) # recursive call
  return nodes
end

# Recursive call of collect_nodes
function _collect_nodes(t::BallTree, nodes::Array{Node})
  if isdefined(t, :node)
    push!(nodes, t.node)
    if isdefined(t, :left)
      _collect_nodes(t.left, nodes)
    end
    if isdefined(t, :right)
      _collect_nodes(t.right, nodes)
    end
  end
end

# Nearest neighbours search (w/ simple prunning)
# @param t: ball tree to search
# @param point: point to search in ball tree
# @param radius: radius of nearest neighbours (in meters)
# @return neighbours {Vector{Node}}: nearest neighbours
function nn(t::BallTree, point::Array{Float64}, radius::Float64)
  c = great_circle(radius, 0, point[1], point[2])
  r =  norm([point[1] - c["latitude"],  point[2] - c["longitude"]])
  query_ball = BoundingSphere(point, r)
  neighbours = Node[]
  _nn(t, query_ball, neighbours) # recursive call
  return neighbours
end

# Recursive call of nn
function _nn(t::BallTree, ball::BoundingSphere, neighbours::Array{Node})
  if isdefined(t, :node)
    if isdefined(t, :b_sphere) && overlaps(ball, t.b_sphere)
      if encloses(ball, t.b_sphere)
        append!(neighbours, collect_nodes(t))
      else
        if in_circle(t.node.point, (ball.c, ball.r))
          push!(neighbours, t.node)
        end
        if isdefined(t, :left)
          _nn(t.left, ball, neighbours)
        end
        if isdefined(t, :right)
          _nn(t.right, ball, neighbours)
        end
      end
    elseif in_circle(t.node.point, (ball.c, ball.r))
      push!(neighbours, t.node)
    end
  end
end

# Checks if b1 encloses b2
function encloses(b1::BoundingSphere, b2::BoundingSphere)
  return norm(b1.c - b2.c) + b2.r <= b1.r
end

# Checks if sphere1 overlaps with sphere2
function overlaps(sphere1::BoundingSphere, sphere2::BoundingSphere)
  return norm(sphere1.c - sphere2.c) <= sphere1.r + sphere2.r
end 

end
