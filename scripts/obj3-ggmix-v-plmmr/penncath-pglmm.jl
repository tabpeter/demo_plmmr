using CSV
using DataFrames
using GLM
using PenalizedGLMM

println("Loaded packages")

# Data filepaths
const covfile = joinpath("results", "penncath-float.csv")
const plinkfile = joinpath("data", "qc_penncath")
const grmfile = joinpath("results", "penncath-k.txt.gz")

# Convert CAD to float (for normal approx)
covdf = CSV.read(covfile, DataFrame)
#const covfile = joinpath("results", "penncath-float.csv")
#covdf[:,:CADfloat] = convert(Array{Float64}, covdf[:,:CAD])
#CSV.write("penncath-float.csv", covdf)
#const floatcovfile = "penncath-float.csv"

null_fit = pglmm_null(@formula(CADfloat ~ age + sex), covfile = covfile, grmfile = grmfile, 
    family = Normal(), link = IdentityLink())
fit = pglmm(null_fit, plinkfile)

println("Finished")

pglmmAIC = PenalizedGLMM.GIC(fit, :AIC)
pglmmBIC = PenalizedGLMM.GIC(fit, :BIC);
print(fit.lambda[[pglmmAIC, pglmmBIC]])

#### Prediction Objective ####

# training / testing split - exported from plmmr fit
traininds = CSV.read(joinpath("results", "train_indices.csv"), DataFrame)
traininds = traininds[:,1]
testinds = CSV.read(joinpath("results", "test_indices.csv"), DataFrame)
testinds = testinds[:,1]

nullmodel_normal = pglmm_null(@formula(CADfloat ~ sex + age), 
    family = Normal(),
    link = IdentityLink(),
    covfile = floatcovfile, 
    grmfile = grmfile, 
    covrowinds = traininds,
    grminds = traininds)

modelfit_normal = pglmm(nullmodel_normal, 
    plinkfile, 
    geneticrowinds = traininds,
    penalty_factor_X = Float64[0; ones(2)]) # penalizing the covariates

pglmmBIC = PenalizedGLMM.GIC(modelfit_normal, :BIC)

yhat = PenalizedGLMM.predict(modelfit_normal,
                            @formula(CADfloat ~ sex + age),
                            floatcovfile,
                            plinkfile,
                            grmfile = grmfile,
                            testrowinds = testinds,
                            trainrowinds = traininds,
                            geneticrowinds = testinds,
                            s = [pglmmBIC],
                            outtype = :response)
yhat = vec(yhat)
loss = (yhat - covdf[testinds, :CADfloat]).^2
mean(loss)


