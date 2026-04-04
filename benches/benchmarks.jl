# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for PostDisciplinary.jl

using BenchmarkTools
using PostDisciplinary
using UUIDs

const SUITE = BenchmarkGroup()

# ── ResearchProject and add_link! ────────────────────────────────────────────

SUITE["project"] = BenchmarkGroup()

SUITE["project"]["create"] = @benchmarkable ResearchProject("Benchmark Project")

SUITE["project"]["add_link"] = let
    p = ResearchProject("Bench")
    e1 = LinkedEntity(uuid4(), :A, :x, :Model, Dict{Symbol,Any}())
    e2 = LinkedEntity(uuid4(), :B, :y, :Claim, Dict{Symbol,Any}())
    @benchmarkable add_link!($p, $e1, $e2, :supports) setup=(p = ResearchProject("B"))
end

SUITE["project"]["generate_synthesis_small"] = let
    function make_project(n)
        p = ResearchProject("Synth $n")
        es = [LinkedEntity(uuid4(), :D, Symbol("e$i"), :Claim, Dict{Symbol,Any}()) for i in 1:n+1]
        for i in 1:n
            add_link!(p, es[i], es[i+1], :supports)
        end
        p
    end
    p5 = make_project(5)
    @benchmarkable generate_synthesis($p5)
end

# ── MetaAnalysis ─────────────────────────────────────────────────────────────

SUITE["meta_analysis"] = BenchmarkGroup()

SUITE["meta_analysis"]["aggregate_10"] = let
    studies = [EffectSize(rand(), 0.01, rand() * 100) for _ in 1:10]
    @benchmarkable aggregate_effects($studies)
end

SUITE["meta_analysis"]["heterogeneity_q_10"] = let
    studies = [EffectSize(rand(), 0.01, rand() * 100) for _ in 1:10]
    pooled = aggregate_effects(studies)
    @benchmarkable heterogeneity_q($studies, $pooled)
end

# ── RaftConsensus ────────────────────────────────────────────────────────────

SUITE["raft"] = BenchmarkGroup()

SUITE["raft"]["request_vote"] = let
    node = RaftNode()
    id = uuid4()
    @benchmarkable request_vote($node, 1, $id) setup=(node = RaftNode())
end

SUITE["raft"]["append_entries_10"] = let
    entries = ["fact$i" for i in 1:10]
    leader_id = uuid4()
    @benchmarkable append_entries($node, 1, $leader_id, $entries) setup=(node = RaftNode())
end

if abspath(PROGRAM_FILE) == @__FILE__
    tune!(SUITE)
    results = run(SUITE, verbose=true)
    BenchmarkTools.save("benchmarks_results.json", results)
end
