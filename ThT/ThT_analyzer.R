library(pacman)
p_load_current_gh("DoseResponse/drcData", "ryandward/drc", "hrbrmstr/hrbrthemes")
doc_theme <- theme_ipsum(base_family = "Arial", caption_margin = 12, axis_title_size = 12, axis_col = "black")

nuoBH_ThT <- fread(
	"ThT/NT_nuoHB.tsv",
	header = T) %>%
	rename("row" = "V1") %>% 
	melt(id.vars = "row", variable.name = "column", value.name = "identity")

nuoBH_ThT <- nuoBH_ThT %>% mutate(
	strain = case_when(
		identity %like% "74" ~ "nuoB",
		identity %like% "73" ~ "nuoH",
		identity %like% "80" ~ "control"),
	induced = case_when(
		identity %like% "I" ~ "induced",
		!identity %like% "I" ~ "uninduced")) 

nuoBH_ThT_data <- fread("ThT/NT_nuoBH_stats.tsv")


setnames(nuoBH_ThT_data, t(nuoBH_ThT_data)[,1])

setnames(nuoBH_ThT_data,"Cycle Nr.",	"Well")

nuoBH_ThT_data <- nuoBH_ThT_data[grep("[A-z][0-9]{1,2}", Well)]

nuoBH_ThT_data <- 
	melt(
		nuoBH_ThT_data, 
		id.vars = "Well", 
		variable.name = "cycle", 
		value.name = "ThT", 
		na.rm = TRUE)

nuoBH_ThT_data <- nuoBH_ThT %>% mutate(Well = paste0(row, column)) %>% inner_join(nuoBH_ThT_data) 

nuoBH_OD <- fread(
	"ThT/NT_nuoHB_OD.tsv",
	header = T) %>%
	rename("row" = "<>") %>% 
	melt(id.vars = "row", variable.name = "column", value.name = "OD")

nuoBH_ThT_data <- nuoBH_ThT_data %>% select(-row, -column ) %>% 
	inner_join(nuoBH_OD %>% mutate(Well = paste0(row, column)) %>% select(-row, -column)) %>%
	mutate(ThT_OD = ThT/OD) 

nuoBH_ThT_data[OD < as.numeric(0.05), strain := NA_character_]


nuoBH_summarised <- nuoBH_ThT_data %>%
	filter(!is.na(strain)) %>%
	group_by(induced, cycle, strain) %>%
	summarise(mean = mean(ThT_OD), sd = sd(ThT_OD), se = sd/sqrt(n())) %>%
	arrange(cycle, strain, induced)

nuoBH_summarised %>%
	filter(induced == "induced") %>%
	inner_join(
		nuoBH_summarised %>% filter(induced == "uninduced"),
		by = c("strain", "cycle")) %>%
	mutate(ratio = mean.x / mean.y,
				 error = sqrt(se.x/mean.x + se.y/mean.y)) %>%
	ggplot(aes(x = cycle, y = ratio, color = strain)) +
	geom_point() +
	geom_errorbar(aes(ymin = ratio - error, ymax = ratio + error)) +
	scale_x_discrete(limits = levels(nuoBH_summarised$cycle)) +
	theme_minimal()


nuoBH_ThT_data %>% filter(!is.na(strain)) %>% ggplot(aes(x = cycle, y = ThT_OD, color = strain)) + geom_boxplot() + facet_grid(~induced) + 	theme_minimal()

nuoBH_ThT_data %>% filter(!is.na(strain) & strain != "nuoH") %>% ggplot(aes(x = induced, y = ThT_OD, fill = strain)) + geom_boxplot() + 	theme_minimal()


##########################################################################################

col_CCCP_ThT <- fread(
	"ThT/colistin_CCCP.tsv",
	header = T) %>%
	rename("row" = "V1") %>% 
	melt(id.vars = "row", variable.name = "column", value.name = "identity")

col_CCCP_ThT_doses <- c(rep(rep(c(0, 0.2, 0.4, 0.8), 2), 6), rep(rep(c(0, 4, 6, 8), 2), 6))

col_CCCP_ThT_drugs <- c(rep("colistin", 48), rep("CCCP", 48))

col_CCCP_ThT_data <- fread("ThT/colistin_CCCP_stats.tsv")

setnames(col_CCCP_ThT_data, t(col_CCCP_ThT_data)[,1])

setnames(col_CCCP_ThT_data,"Cycle Nr.",	"Well")

col_CCCP_ThT_data <- col_CCCP_ThT_data[grep("[A-z][0-9]{1,2}", Well)]

col_CCCP_ThT_data <- 
	melt(
		col_CCCP_ThT_data, 
		id.vars = "Well", 
		variable.name = "cycle", 
		value.name = "ThT", 
		na.rm = TRUE)

col_CCCP_ThT_data <- col_CCCP_ThT %>% mutate(Well = paste0(row, column)) %>% inner_join(col_CCCP_ThT_data) 

col_CCCP_OD <- fread(
	"ThT/colistin_CCCP_OD.tsv",
	header = T) %>%
	rename("row" = "<>") %>% 
	melt(id.vars = "row", variable.name = "column", value.name = "OD") %>%
	mutate(Well = paste0(row, column))

col_CCCP_ThT_data <- col_CCCP_ThT_drugs %>% 
	data.table(drug = .) %>% 
	cbind(col_CCCP_ThT_doses %>% data.table(dose = .)) %>% 
	cbind(col_CCCP_ThT) %>% 
	mutate(strain = case_when(identity %like% "WT" ~ "WT")) %>%
	mutate(Well = paste0(row, column)) %>% 
	inner_join(col_CCCP_ThT_data) %>%
	inner_join(col_CCCP_OD) 

col_CCCP_ThT_data %>% filter(!is.na(strain)) %>%
	mutate(ThT_OD = ThT/OD) %>%
	ggplot(aes(x = cycle, y = ThT_OD)) +
	geom_boxplot(aes(colour = as.character(dose))) +
	facet_wrap(~drug) +
	doc_theme

col_CCCP_ThT_data %>% filter(!is.na(strain)) %>%
	mutate(ThT_OD = ThT/OD) %>%
	ggplot(aes(x = dose, y = ThT_OD)) +
	geom_boxplot(aes(fill = as.character(dose))) +
	facet_wrap(~drug, scales = "free_x") +
	doc_theme


# this is a mess
col_CCCP_ThT_data %>% filter(!is.na(strain)) %>%
	mutate(ThT_OD = ThT/OD) %>% mutate(strain = "WT") %>% rbind(nuoBH_ThT_data, fill = TRUE) %>% mutate(induced = case_when(induced == "induced" ~ "induced", TRUE ~ "uninduced")) %>% mutate(drug = case_when(!is.na(drug) ~ drug, TRUE ~ "none")) %>% mutate(dose = case_when(!is.na(dose) ~ dose, TRUE ~ 0)) %>% filter(!is.na(strain)) %>% ggplot(aes(x = interaction(induced, dose, sep = "\n"), y = ThT_OD, fill = strain)) + geom_boxplot() + 	theme_minimal() + facet_wrap(~drug, scales = "free_x") +
	theme(axis.text.x = element_text(angle = 45))

# t-test
col_CCCP_ThT_data %>% mutate(cycle = as.numeric(cycle)) %>% filter(!is.na(strain) & cycle == 10)  %>%
	mutate(ThT_OD = ThT/OD) %>% group_by(drug) %>% 
	filter(dose == 0 | dose == max(dose)) %>% do(tidy(t.test(ThT_OD ~ dose, data = .)))


nuoBH_ThT_data %>% mutate(cycle = as.numeric(cycle)) %>% filter(strain %in% c("control", "nuoB") & cycle == 10) %>%
	mutate(ThT_OD = ThT/OD) %>% group_by(induced) %>% do(tidy(t.test(ThT_OD ~ strain, data = .)))

