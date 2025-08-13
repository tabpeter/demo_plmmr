using CSV
using DataFrames
using GLM
using Pkg

#Pkg.develop(path = "/git/PenalizedGLMM")
using PenalizedGLMM

println("Loaded packages")

# Data filepaths
const outcomefile = "results/bladder_outcome.csv"
const stdxfile = "results/bladder_stdx.csv"
const grmfile = "results/bladder_K_unscaled.csv.gz"

lambda = CSV.read("results/bladder_lambda.csv", DataFrame, header = 0)
lambda = lambda[:,1]

# Convert outcome to float (for normal approx)
outcomedf = CSV.read(outcomefile, DataFrame)
outcomedf[!,:y] = convert(Vector{Float64}, outcomedf[!,:y])

# Fit model
null_fit = pglmm_null(@formula(y ~ 1), 
                        covfile = outcomedf, 
                        grmfile = grmfile, 
                        lambda = lambda,
                        family = Normal(),
                        link = IdentityLink())
fit = pglmm(null_fit, 
            snpfile = stdxfile) 

# Export coefficient paths
coeffit = Matrix(fit.betas)
CSV.write("results/bladder-PenalizedGLMM.csv", Tables.table(coeffit))

println("Finished")