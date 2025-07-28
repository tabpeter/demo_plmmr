# TKP
# Objective: create folders to organize results for objective 1

g <- expand.grid(n = c(350, 700, 1050, 1401), p = c("400K", "600K", "700K"))
for (i in 1:nrow(g)){
  foldername <- file.path("results", paste0("n", g[i,1], "_p", g[i,2]))
  if (!dir.exists(obj4_dir)) {
    dir.create(foldername, recursive = TRUE)
  }
}
