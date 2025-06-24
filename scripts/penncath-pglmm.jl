using CSV
using DataFrames
using GLM
using PenalizedGLMM

println("Loaded packages")

### data filepaths ###
const covfile = "results/penncath-float.csv"
const plinkfile = "data/qc_penncath"
const grmfile = "results/penncath-k.txt.gz"

# Convert CAD to float (for normal approx)
covdf = CSV.read(covfile, DataFrame)
#const covfile = "results/penncath-float.csv"
#covdf[:,:CADfloat] = convert(Array{Float64}, covdf[:,:CAD])
#CSV.write("penncathfloat.csv", covdf)
#const floatcovfile = "penncathfloat.csv"

null_fit = pglmm_null(@formula(CADfloat ~ age + sex), covfile = covfile, grmfile = grmfile, family = Normal(), link = IdentityLink())
fit = pglmm(null_fit, plinkfile)

println("Finished")

pglmmAIC = PenalizedGLMM.GIC(fit, :AIC)
pglmmBIC = PenalizedGLMM.GIC(fit, :BIC);
print(fit.lambda[[pglmmAIC, pglmmBIC]])
