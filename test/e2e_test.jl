# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for PostDisciplinary.jl

using Test
using PostDisciplinary
using UUIDs
using DataFrames

@testset "E2E Pipeline Tests" begin

    @testset "Full interdisciplinary research pipeline" begin
        # Create a project, add linked entities, synthesise, triangulate
        p = ResearchProject("Climate Justice Pipeline")

        e1 = LinkedEntity(uuid4(), :Cliodynamics, :historical_cycle, :Model,
                          Dict(:confidence => 0.9))
        e2 = LinkedEntity(uuid4(), :Economics, :gdp_inequality, :Data,
                          Dict(:source => "World Bank"))
        e3 = LinkedEntity(uuid4(), :Ethics, :distributive_justice, :Claim,
                          Dict(:school => "Rawlsian"))

        r1 = add_link!(p, e1, e2, :informs)
        r2 = add_link!(p, e2, e3, :supports)

        @test occursin("Link established", r1)
        @test occursin("Link established", r2)

        synth = generate_synthesis(p)
        @test synth.report_title == "Synthesis: Climate Justice Pipeline"
        @test nrow(synth.entities) == 3
        @test synth.graph_density isa Float64

        report = triangulate_findings(p, [:Cliodynamics, :Economics, :Ethics])
        @test report isa CorrelationReport
        @test report.agreement_score isa Float64
    end

    @testset "Research project scaffolding pipeline" begin
        # WickedProblem scaffold through to strategy execution
        p = scaffold_project(WickedProblem(), "Housing Inequality")
        @test p isa ResearchProject
        @test p.name == "Housing Inequality"

        @test execute_strategy(MultiDisciplinary(), p) === nothing
        @test run_design(MixedDesign(), p) === nothing
    end

    @testset "Meta-analysis full pipeline" begin
        studies = [EffectSize(0.2 + 0.1*i, 0.01 + 0.005*i, 100.0 - 10.0*i) for i in 0:4]
        pooled = aggregate_effects(studies)
        @test pooled isa Float64
        @test 0.0 < pooled < 1.0

        q = heterogeneity_q(studies, pooled)
        @test q >= 0.0
    end

    @testset "Error handling: empty synthesis" begin
        p = ResearchProject("Empty Project")
        synth = generate_synthesis(p)
        @test nrow(synth.entities) == 0
        @test synth.graph_density isa Float64
    end

end
