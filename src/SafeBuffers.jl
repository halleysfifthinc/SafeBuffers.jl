module SafeBuffers

using Base: Semaphore, acquire, release

export withbuffer

export SafeBuffer

"""
    SafeBuffer{T,N}
    SafeBuffer(n, reftype)
    SafeBuffer(n, buffer::AbstractArray)
    SafeBuffer(n, arrtype, dims...)

A type with `n` lockable mutable buffers.

# Examples

```jldoctest
julia> b1 = SafeBuffer(2, Ref{Int})
SafeBuffer{Base.RefValue{Int64}, 2}(🔒: 0, size = ())

julia> b2 = SafeBuffer(2, Vector{Int}, 2)
SafeBuffer{Vector{Int64}, 2}(🔒: 0, size = (2,))

julia> b3 = SafeBuffer(Threads.nthreads(), Vector{Int}, 2)
SafeBuffer{Vector{Int64}, 8}(🔒: 0, size = (2,))
```
"""
struct SafeBuffer{T,N}
    held::Semaphore
    locks::NTuple{N,ReentrantLock}
    buffers::Vector{T}
end

function SafeBuffer(n, reftype::Type{Ref{T}}) where T
    return SafeBuffer(Semaphore(n), ntuple(_ -> ReentrantLock(), n),
        [ Ref{T}() for _ in 1:n ])
end

function SafeBuffer(n, buffer::AbstractArray)
    return SafeBuffer(Semaphore(n), ntuple(_ -> ReentrantLock(), n),
        [ similar(buffer) for _ in 1:n ])
end

function SafeBuffer(n, arrtype::Type{<:AbstractArray{T,N}}, dims::Vararg{Int,N}) where {T,N}
    return SafeBuffer(n, arrtype, dims)
end

function SafeBuffer(n, arrtype::Type{<:AbstractArray{T,N}}, dims::NTuple{N,Int}) where {T,N}
    return SafeBuffer(Semaphore(n), ntuple(_ -> ReentrantLock(), n),
        [ Array{T,N}(undef, dims) for _ in 1:n ])
end

function Base.show(io::IO, buffer::SafeBuffer)
    print(io, "$(typeof(buffer))(🔒: $(buffer.held.curr_cnt), size = $(size(buffer.buffers[1])))")
end

function acquirebuffer(buffer)
    # buffer.held.curr_cnt === buffer.held.sem_size && @debug "Buffer fully subscribed" Threads.threadid() stacktrace()
    acquire(buffer.held)
    @inbounds for ci in eachindex(buffer.locks)
        if trylock(buffer.locks[ci])
            return buffer.locks[ci], buffer.buffers[ci]
        end
    end

    return nothing
end

function releasebuffer(lock, buffer)
    unlock(lock)
    release(buffer.held)
end

"""
    withbuffer(f, buffer)

Acquire a buffer in the `SafeBuffer` and call `f` on the acquired buffer.

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
function withbuffer(f, buffer)
    l, buf = acquirebuffer(buffer)
    local ret
    try
        ret = f(buf)
    finally
        releasebuffer(l, buffer)
    end

    return ret
end

end
