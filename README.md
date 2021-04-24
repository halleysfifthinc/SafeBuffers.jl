# SafeBuffers

[![Build Status](https://github.com/halleysfifthinc/SafeBuffers.jl/workflows/CI/badge.svg)](https://github.com/halleysfifthinc/SafeBuffers.jl/actions)
[![Coverage](https://codecov.io/gh/halleysfifthinc/SafeBuffers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/halleysfifthinc/SafeBuffers.jl)

Concurrency/multi-threading safe pre-allocated mutable buffers (e.g. arrays, etc.).

Using a simple `Vector` of e.g. preallocated arrays may not have a strong enough "ownership"
guarantee when Tasks yield before finishing using a particular prealloc'ed array. A
`SafeBuffer` protects each buffer with a lock while a particular buffer is in use.
`withbuffer` will wait for a buffer to become available when/as needed.

## Examples

```julia
julia> b1 = SafeBuffer(2, Ref{Int})
SafeBuffer{Base.RefValue{Int64}, 2}(🔒: 0, size = ())

julia> b2 = SafeBuffer(2, Vector{Int}, 2)
SafeBuffer{Vector{Int64}, 2}(🔒: 0, size = (2,))

julia> b3 = SafeBuffer(Threads.nthreads(), Vector{Int}, 2)
SafeBuffer{Vector{Int64}, 8}(🔒: 0, size = (2,))

julia> withbuffer(b2) do buf
           buf .= 1:2
           sum(abs2, buf)
       end
5
```
