using SafeBuffers
using Test

@testset "SafeBuffers.jl" begin
    @test_nowarn SafeBuffer(2, Ref{Int})
    @test_nowarn SafeBuffer(2, Vector{Int}, 2)
    @test_nowarn SafeBuffer(2, Vector{Int}, (2,))
    @test_nowarn SafeBuffer(2, Matrix{Int}, 2, 2)
    @test_nowarn SafeBuffer(2, Matrix{Int}, (2,2))

    buf = Matrix{Int}(undef, 2,2)
    @test_nowarn SafeBuffer(2, buf)

    b1 = SafeBuffer(2, Vector{Int}, 2)
    @test 5 == withbuffer(b1) do buf
        buf .= 1:2
        sum(abs2, buf)
    end

    @test_nowarn begin
        t1 = @async withbuffer(b1) do buf
            buf .= 1
            sleep(1)
            yield()
            sum(log, buf)
        end
        t2 = @async withbuffer(b1) do buf
            buf .= -1
            nothing
        end
        t3 = @async withbuffer(b1) do buf
            buf .= -1
            nothing
        end
        wait.([t1, t2, t3])
    end

end
