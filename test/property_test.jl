# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for PostDisciplinary.jl

using Test
using PostDisciplinary
using UUIDs

@testset "Property-Based Tests" begin

    @testset "Invariant: aggregate_effects is within range of input values" begin
        for _ in 1:50
            n = rand(2:10)
            values = rand(n) .* 2 .- 0.5   # values in [-0.5, 1.5]
            weights = rand(n) .* 100 .+ 1.0
            studies = [EffectSize(values[i], 0.01, weights[i]) for i in 1:n]
            pooled = aggregate_effects(studies)
            @test minimum(values) - 1e-9 <= pooled <= maximum(values) + 1e-9
        end
    end

    @testset "Invariant: heterogeneity_q is non-negative" begin
        for _ in 1:50
            n = rand(2:8)
            values = rand(n)
            weights = rand(n) .* 50 .+ 1.0
            studies = [EffectSize(values[i], 0.01, weights[i]) for i in 1:n]
            pooled = aggregate_effects(studies)
            q = heterogeneity_q(studies, pooled)
            @test q >= -1e-10   # allow floating-point noise
        end
    end

    @testset "Invariant: add_link! always returns a String" begin
        for _ in 1:50
            p = ResearchProject("Property Test $(rand(1:9999))")
            e1 = LinkedEntity(uuid4(), :A, :x, :Model, Dict{Symbol,Any}())
            e2 = LinkedEntity(uuid4(), :B, :y, :Claim, Dict{Symbol,Any}())
            result = add_link!(p, e1, e2, :supports)
            @test result isa String
        end
    end

    @testset "Invariant: generate_synthesis entity count matches add_link! calls" begin
        for _ in 1:30
            p = ResearchProject("Count Test $(rand(1:9999))")
            n = rand(1:5)
            entities = [LinkedEntity(uuid4(), :Domain, Symbol("e$i"), :Claim, Dict{Symbol,Any}()) for i in 1:n+1]
            for i in 1:n
                add_link!(p, entities[i], entities[i+1], :supports)
            end
            synth = generate_synthesis(p)
            @test nrow(synth.entities) == n + 1
        end
    end

end
