random.seed <- 0:9
immune_apoptosis_rate <- seq(6.94e-4, 6.94e-6, length.out = 3)
immune_migration_bias <- seq(0.1, 0.9, length.out = 3)
immune_kill_rate <- seq(0.01, 1.0, length.out = 3)
immune_attachment_lifetime <- seq(10.0, 90.0, length.out = 3)
immune_attachment_rate <- seq(0.01, 1.0, length.out = 3)
oncoprotein_threshold <- seq(0.1, 1.0, length.out = 3)

df <- expand.grid('user_parameters.random_seed' = random.seed,
                  'user_parameters.immune_apoptosis_rate' = immune_apoptosis_rate,
                  'user_parameters.immune_migration_bias' = immune_migration_bias,
                  'user_parameters.immune_kill_rate' = immune_kill_rate,
                  'user_parameters.immune_attachment_lifetime' = immune_attachment_lifetime, 
                  'user_parameters.immune_attachment_rate' = immune_attachment_rate,
                  'user_parameters.oncoprotein_threshold' = oncoprotein_threshold,
                  'save.SVG.enable' = 'false',
                  'user_parameters.tumor_immunogenicity_standard_deviation' = 0.25)

write.table(df, file="~/Documents/repos/PhysiCell-EMEWS-2/cancer-immune/EMEWS-scripts/data/tisd_025_upf.csv", row.names = F, 
            sep=",", quote = F)
