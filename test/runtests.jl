using ViyaBatchJobs, Test

@testset verbose = true "BatchJobs" begin

    @testset "JobProfile" begin
        # simple instantiation
        jp = JobProfile("default", "description", ["workloads/sleeper/test.csv"], ["-MEMSIZE 2G"], "default")
        @test jp.name == "default"

        # instantiate using a dictionary
        dct = Dict(
            "name" => "xlarge",
            "description" => "description"
        )
        jp = JobProfile(dct, "xlarge")
        @test jp.name == "xlarge"
    end


end