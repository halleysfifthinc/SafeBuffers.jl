# SafeBuffers

[![Build Status](https://github.com/halleysfifthinc/SafeBuffers.jl/workflows/CI/badge.svg)](https://github.com/halleysfifthinc/SafeBuffers.jl/actions)
[![Coverage](https://codecov.io/gh/halleysfifthinc/SafeBuffers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/halleysfifthinc/SafeBuffers.jl)
![Maintenance](https://img.shields.io/maintenance/no/2021)

Concurrency/multi-threading safe pre-allocated mutable buffers (e.g. arrays, etc.). This package is not registered and should not be assumed to be actively maintained.

Using a simple `Vector` of e.g. preallocated arrays may not have a strong enough "ownership"
guarantee when Tasks yield before finishing using a particular prealloc'ed array. A
`BufferPool` assumes ownership while a particular buffer is in use, preventing use by other Tasks.
`withbuffer` will wait for a buffer to become available when/as needed.

## Examples

```julia
julia> b1 = BufferPool(2, () -> Ref{Int}())
BufferPool{Base.RefValue{Int64}}(🔒: 0 of 2, size = ())

julia> b2 = BufferPool(2, () -> Vector{Int}(undef, 2))
BufferPool{Vector{Int64}}(🔒: 0 of 2, size = (2,))

julia> b3 = BufferPool(Threads.nthreads(), () -> Vector{Int}(undef, 2))
BufferPool{Vector{Int64}}(🔒: 0 of 8, size = (2,))

julia> withbuffer(b2) do buf
           buf .= 1:2
           sum(abs2, buf)
       end
5
```
