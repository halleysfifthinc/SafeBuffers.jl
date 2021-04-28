module SafeBuffers

export withbuffer

export BufferPool

"""
    BufferPool(n, factory)

A type with `n` lockable mutable buffers.

# Examples

```jldoctest
julia> b1 = BufferPool(2, () -> Ref{Int}())
BufferPool{Base.RefValue{Int64}}(🔒: 0 of 2, size = ())

julia> b2 = BufferPool(2, () -> Vector{Int}(undef, 2))
BufferPool{Vector{Int64}}(🔒: 0 of 2, size = (2,))

julia> b3 = BufferPool(Threads.nthreads(), () -> Matrix{Int}(undef, 2, 2))
BufferPool{Vector{Int64}}(🔒: 0 of 8, size = (2,2))
```
"""
struct BufferPool{T}
    N::Int
    condition::Threads.Condition
    buffers::Vector{T}
end

function BufferPool(n, factory)
    n > 0 || throw(ArgumentError("must have at least 1 buffer; got n = $n"))
    BufferPool(n, Threads.Condition(), [ factory() for _ in 1:n ])
end

function Base.show(io::IO, pool::BufferPool)
    print(io, typeof(pool), "(🔒: $(pool.N - length(pool.buffers)) of $(pool.N), size = $(size(first(pool.buffers))))")
end

"""
    withbuffer(f, pool)

Acquire a buffer in the `BufferPool` and call `f` on the acquired buffer.

`withbuffer` will wait as necessary for a buffer to become available. `f` must take one
argument, the buffer to be used/mutated.

# Examples

```jldoctest
julia> withbuffer(b2) do buf
           buf .= 1:2
           sum(abs2, buf)
       end
5
```
"""
function withbuffer(f, pool)
    buf = lock(pool.condition) do
        while isempty(pool.buffers)
            wait(pool.condition)
        end
        pop!(pool.buffers)
    end

    try
        f(buf)
    finally
        lock(pool.condition) do
            push!(pool.buffers, buf)
            notify(pool.condition)
        end
    end
end

end
