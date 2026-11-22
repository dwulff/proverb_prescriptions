# Run from the repository root: Rscript code/analysis.R
if (dir.exists(".R-library")) .libPaths(c(normalizePath(".R-library"), .libPaths()))
for (pkg in c("dplyr", "tidyr", "readr", "stringr", "ggplot2", "tibble")) {
  library(pkg, character.only = TRUE)
}
options(readr.show_col_types = FALSE, dplyr.summarise.inform = FALSE)
set.seed(42)
dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

data_ratings <- read_csv("data/ratings.csv")
proverb_tab <- read_csv("data/sources.csv")
tags <- read_csv("data/tags.csv")
data_ratings <- data_ratings |>
  left_join(tags |> arrange(proverb_id, tag_position) |>
              group_by(proverb_id) |> summarize(tags_clean = list(tag)), by = "proverb_id")
tag_tbl <- read_csv("data/tag_map.csv") |>
  left_join(read_csv("data/tag_groups.csv") |>
              group_by(tag_group_id) |> summarize(tags = list(tag)), by = "tag_group_id")
human_ratings_long <- read_csv("data/human_ratings.csv") |>
  mutate(dimension = factor(dimension, levels = rev(c("prescriptivity", "risk", "time", "social",
    "autonomy", "trust", "honesty", "equality", "kindness", "cooperation"))))
source("code/validate_data.R")

# MAP ----
# Preserve the original shared frequency scale for points and text.
# Splitting this scale changes bubble sizes and drops the text-size mapping.

p = tag_tbl |>
  ggplot(aes(x = lyt_x, y = lyt_y, size = n**1.1, col = as.factor(cluster))) +
  geom_point(pch = 21, fill = "white", alpha=.5, stroke = .3) +
  theme_void() +
  scale_color_viridis_d(option = "G", begin = .2, end = .9) +
  guides(size = "none", color = "none") +
  ggrepel::geom_text_repel(seed = 42, max.time = Inf, data = tag_tbl |> filter(n > 100) |> group_by(cluster) |> arrange(desc(n)) |> slice(1:6) |> ungroup() |> arrange(desc(n)),
                           mapping = aes(label = labels),
                           fontface = "bold", max.overlaps = 20) +
  scale_size(range = c(2, 5)) +
  ylim(c(-7.5, 9.5))



# Regression guard: the original map uses 2–5 mm bubbles and varying text sizes.
map_layers <- ggplot_build(p)$data
stopifnot(isTRUE(all.equal(range(map_layers[[1]]$size), c(2, 5))),
          diff(range(map_layers[[2]]$size)) > 0)

ggsave("figures/01_map.png", plot = p, device = "png", bg = "transparent", width = 8, height = 6)



tag_dict = rep(tag_tbl$labels, lengths(tag_tbl$tags))
names(tag_dict) = tag_tbl$tags |> unlist()

data_ratings = data_ratings |> 
  mutate(tag_1 = sapply(tags_clean, function(x) ifelse(length(x)>0, x[1], NA)),
         tag_2 = sapply(tags_clean, function(x) ifelse(length(x)>1, x[2], NA)),
         tag_3 = sapply(tags_clean, function(x) ifelse(length(x)>2, x[3], NA)),
         tag_4 = sapply(tags_clean, function(x) ifelse(length(x)>3, x[4], NA)),
         tag_1_label = tag_dict[tag_1],
         tag_2_label = tag_dict[tag_2],
         tag_3_label = tag_dict[tag_3],
         tag_4_label = tag_dict[tag_4])




# VALIDATION ----
human_ratings_long_avg = human_ratings_long |> 
  group_by(proverb_id, dimension, gist) |> 
  summarize(value = mean(value)) |> 
  mutate(rater = "Average") |> 
  ungroup()


gemma_ratings_long = data_ratings |>
  filter(proverb_id %in% human_ratings_long$proverb_id) |>
  select(proverb_id, ends_with("_num")) |>
  pivot_longer(-proverb_id, names_to = "dimension", values_to = "value") |>
  mutate(dimension = factor(str_remove(dimension, "_num")))

combined = human_ratings_long |> 
  bind_rows(human_ratings_long_avg) |>
  mutate(proverb_id = as.integer(proverb_id)) |> 
  left_join(gemma_ratings_long, suffix = c("_human", "_gemma"), by = c("proverb_id", "dimension"))
   
human_alignment = human_ratings_long %>% 
  pivot_wider(names_from = rater, values_from = value) %>% 
  group_by(gist, dimension) %>% 
  summarize(cor = cor(Rater_1, Rater_2))  |> 
  ungroup()

human_avg_alignment = human_ratings_long %>% 
  pivot_wider(names_from = rater, values_from = value) |> 
  filter(dimension != "prescriptivity") |> 
  group_by(gist, dimension) |> 
  summarize(Rater_1 = mean(Rater_1),
            Rater_2 = mean(Rater_2)) |> 
  ungroup() |> 
  group_by(gist) |> 
  summarize(cor = cor(Rater_1, Rater_2))

human_ai_alignment = combined |> 
  filter(rater == "Average") |> 
  group_by(gist, dimension) %>% 
  summarize(cor = cor(value_human, value_gemma))

human_ai_avg_alignment = combined |> 
  filter(rater == "Average", dimension != "prescriptivity") |> 
  group_by(gist, dimension) %>% 
  summarize(value_human = mean(value_human), 
            value_gemma = mean(value_gemma)) |> 
  ungroup() |> 
  group_by(gist) |> 
  summarize(cor = cor(value_human, value_gemma))

out_1 =  human_alignment |> 
  mutate(cor_gemma = human_ai_alignment$cor) |> 
  mutate(type = "stratified")

out_2 = human_avg_alignment |> 
  mutate(cor_gemma = human_ai_avg_alignment$cor) |> 
  mutate(type = "stratified", dimension = "aggregate")

levels = c("prescriptivity", "risk", "time", "social", 
           "autonomy","trust","honesty",
           "equality","kindness","cooperation",
           "aggregate") |> str_to_sentence()

out = out_1 |> bind_rows(out_2) |> 
  mutate(dimension = factor(dimension |> str_to_sentence(), levels = levels))

p = out |> 
  ggplot(aes(x = dimension, cor, group = gist, shape = gist)) + 
  theme_minimal() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA)) + 
  ylim(c(0, 1)) + 
  geom_linerange(aes(ymin = cor, ymax = cor_gemma), linetype = 2, 
               position = position_dodge(width = .3)) +
  geom_point(position = position_dodge(width = .3), size= 2.5,
             color = viridis::mako(1, begin = .3)) +
  geom_point(aes(y = cor_gemma), position = position_dodge(width = .3),
             size= 2.5, color = viridis::mako(1, begin = .7)) +
  theme(axis.text.x = element_text(hjust = 1, angle=90),
        axis.title.x = element_blank()) + 
  labs(y = "Alignment (Pearson correlation)") + 
  theme(strip.text = element_blank(), legend.position = "none") +
  annotate("text",x = .9, y=.26, label = c("Gist"), angle=c(90), size=3) + 
  annotate("text",x = 1.1, y=.22, label = c("No gist"), angle=c(90), size=3)+   
  annotate("text",x = 5, y=.13, label = "Human-human", size=4, color=viridis::mako(1, begin = .3)) + 
  annotate("text",x = 6, y=.7, label = "Human-LLM", size=4, color=viridis::mako(1, begin = .7)) +
  theme(axis.text.x = element_text(face = ifelse(levels == "Aggregate", "bold", "plain")))
  

ggsave("figures/01b_performance.png", plot = p, device = "png", bg = "transparent", width = 8, height = 3)


# NORMATIVE ----

count = data_ratings |> select(ends_with("_label")) |> unlist() |> table()
uni = names(count[count >= 200])

means = matrix(ncol = 2, nrow = length(uni), dimnames=list(uni, c("n","normative")))
for(i in 1:length(uni)){
  present = uni[i] == data_ratings$tag_1_label | 
    uni[i] == data_ratings$tag_2_label | 
    uni[i] == data_ratings$tag_3_label |
    uni[i] == data_ratings$tag_4_label
  means[i,] = c(sum(present, na.rm=T), mean(data_ratings$prescriptivity_num[present] > 3, na.rm=T)) 
  }

clusters = tag_tbl |> pull(cluster, labels)


average = data_ratings |> 
  mutate(book = "average") |> 
  group_by(book) |> 
  summarize(prescriptivity = mean(prescriptivity_num %in% c(4,5)))
  
book_means = proverb_tab |> left_join(data_ratings |> select(proverb_id, prescriptivity_num)) |> 
  filter(!is.na(book)) |> 
  group_by(book) |> 
  summarize(prescriptivity = mean(prescriptivity_num %in% c(4,5)))

averages = average |> 
  bind_rows(book_means) |> 
  mutate(tag = "", n = 100, cluster = NA)


p = as_tibble(means) |> 
  mutate(tag = rownames(means),
         cluster = clusters[uni]) |> 
  ggplot(aes(x = normative, y = as.integer(cluster)/20, label = tag, size = n, color = as.factor(cluster))) + 
  geom_vline(aes(xintercept = prescriptivity), data = averages, linewidth=.2, linetype = 1, color = "grey65") +
  geom_point()  + 
  ggrepel::geom_text_repel(seed = 42, max.time = Inf, max.overlaps = 50) + 
  scale_size(range = c(.8, 4)) +
  scale_color_viridis_d(option = "G", begin = .2, end = .9) +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA)) + 
  guides(size = "none", col = "none") +
  theme(axis.text.y = element_blank(),
        axis.title.y = element_text(size = 8, color = "grey25")) + 
  ylim(c(0, 1.05)) +
  xlim(c(.25, 1)) +
  labs(x = "Prescriptive capacity", 
       y = "Clusters (used to increase visual separation)")

# Regression guard: topic text and points share the original 0.8–4 size scale.
normative_layers <- ggplot_build(p)$data
stopifnot(isTRUE(all.equal(range(normative_layers[[2]]$size), c(.8, 4))),
          identical(normative_layers[[2]]$size, normative_layers[[3]]$size),
          identical(p$guides$guides$size, "none"))

ggsave("figures/02_normative.png", plot = p, device = "png", bg = "transparent", width = 8, height = 4)
normative_topics <- as_tibble(means, rownames = "tag")

# POLARITY ----


polarity_llm = data_ratings |> 
  filter(prescriptivity_num > 3) |> 
  select(proverb_id, ends_with("_num"), -prescriptivity_num) |> 
  pivot_longer(-proverb_id) |> 
  group_by(name) |> 
  summarize(mid = 1-mean(value == 3),
            polarity = (2-abs(mean(value-3)))/2) |> 
  mutate(name = str_remove(name, "_num"))

human_prescr_sel = combined |> 
  filter(dimension == "prescriptivity") |> 
  group_by(proverb_id) |> 
  summarize(value_human = mean(value_human)) |> 
  filter(value_human > 3)
 
polarity_human = combined |> 
  filter(proverb_id %in% human_prescr_sel$proverb_id) |> 
  filter(dimension != "prescriptivity") |> 
  group_by(dimension) |> 
  summarize(mid = 1-mean(value_human == 3),
            polarity = (2-abs(mean(value_human-3)))/2) 


levels = c("risk", "time", "social", "autonomy","trust","honesty", "equality","kindness","cooperation") 
out = polarity_llm |> left_join(polarity_human, by = c("name" = "dimension"), suffix = c("", "_human")) |> 
  mutate(name = factor(name, levels = levels))

p = out |> 
  ggplot(aes(x = polarity, y = mid, label = name |> str_to_sentence(), col = name)) + 
  geom_segment(aes(xend = polarity_human, yend = mid_human), linetype=2) +
  geom_point(pch = 15, size=2.2) +
  geom_point(aes(x = polarity_human, y = mid_human), pch = 16, size=2.5) +
  ggrepel::geom_text_repel(seed = 42, max.time = Inf, fontface="bold") + 
  theme_minimal() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA)) +
  labs(x = "Polarity",
       y = "Extremity") + 
  ylim(c(0, 1)) + 
  xlim(c(0, 1)) + 
  scale_color_viridis_d(option = "G", begin = .2, end = .8) + 
  theme(legend.position = "none") + 
  annotate("point",x = .78, y = .14, pch = 16, size=2.2) +
  annotate("point",x = .78, y = .06, pch = 15, size=2.5) +
  annotate("text",x = .78 + .02, y = .14, label = "Human", hjust = 0) +
  annotate("text",x = .78 + .02, y = .06, label = "LLM", hjust = 0) 

ggsave("figures/03_polarity.png", p, device = "png", bg = "transparent", width = 8, height = 2.7)

# DIMENSIONS ----

data_ratings_prescr = data_ratings |> filter(prescriptivity_num > 3)

count = data_ratings_prescr$tags_clean |> unlist() |> table()
uni = names(count[count >= 40])
levels = c("risk", "time", "social", "autonomy","trust","honesty", "equality","kindness","cooperation") 

means = matrix(nrow = length(uni), ncol = length(levels),
               dimnames = list(uni, levels))
for(i in 1:length(uni)){
  for(j in 1:length(levels)){
    present = uni[i] == data_ratings_prescr$tag_1 | uni[i] == data_ratings_prescr$tag_2 | uni[i] == data_ratings_prescr$tag_3 | uni[i] == data_ratings_prescr$tag_4
    present[is.na(present)] = FALSE
    var = data_ratings_prescr[[paste0(levels[j], "_num")]]
    val = var[present]
    if(sum(!is.na(val)) > 10){
      means[i, j] = mean(val, na.rm=T) 
    } else {
      means[i, j] = NA 
    }
  }
}

get_top = function(x, p = .025){
  x > quantile(x, 1-p, na.rm=T) | x < quantile(x, p, na.rm=T)
}

pole_low = c("caution","long-term","other's","compliance","trust","honesty","equality","kindness","cooperation") |> str_to_sentence()
pole_high = c("risk","short-term consequences","own interests","autonomy","suspicion","deception","hierarchy","malice","competition") |> str_to_sentence()
labels = paste0("← ", str_to_sentence(pole_low)," vs. ",str_to_sentence(pole_high), " →")
labels = paste0("<b>",str_to_sentence(levels),"</b>", "<br><span style='font-size:8pt'>", labels, "</span>")

d = expand_grid(tag = rownames(means), 
                dim = colnames(means)) |> 
  mutate(avg = c(t(means)),
         label = rep(labels, nrow(means)) |> factor(levels = labels)) |> 
  mutate(y = 1) |> 
  ungroup() |> 
  group_by(dim) |> 
  mutate(avg = ifelse(is.na(avg), NA, avg)) |> 
  ungroup()

averages = data_ratings_prescr |> 
  select(ends_with("_num"), -prescriptivity_num) |> 
  pivot_longer(everything()) |> 
  filter(!is.na(value)) |> 
  group_by(name) |> 
  summarize(avg = mean(value),
            se = sd(value)/sqrt(n()),
            y = 1, 
            tag = "") |>
  mutate(name = str_remove(name, "_num")) |> 
  mutate(name = factor(name, levels = colnames(means))) |> 
  arrange(name) |> 
  mutate(label = factor(labels, levels = labels))

averages_books = proverb_tab |> 
  filter(proverb_id %in% data_ratings_prescr$proverb_id, !is.na(book)) |> 
  left_join(data_ratings_prescr |> select(proverb_id, ends_with("_num"), -prescriptivity_num)) |> 
  pivot_longer(ends_with("_num")) |> 
  group_by(book, name) |> 
  summarize(avg = mean(value),
            se = sd(value)/sqrt(n()),
            y = 1, 
            tag = "") |>
  mutate(name = str_remove(name, "_num")) |> 
  mutate(name = factor(name, levels = colnames(means))) |> 
  ungroup() |> 
  arrange(name) |> 
  mutate(label = factor(labels[match(name, levels)], levels = labels))

human_averages = human_ratings_long_avg |> 
  filter(proverb_id %in% human_prescr_sel$proverb_id) |> 
  filter(dimension != "prescriptivity") |> 
  mutate(dimension = factor(dimension, levels = levels(averages$name))) |> 
  group_by(dimension) |> 
  summarize(avg = mean(value)) |> 
  mutate(y = 1, tag = "", label = averages$label)

library(ggtext)

p = d |> 
  ggplot(aes(x = avg, y = y, label = tag, col = label)) + 
  geom_vline(data = averages_books, mapping = aes(xintercept = avg), col="grey65", linewidth = .15) +
  ggbeeswarm::geom_quasirandom(size = .8, pch = 21, stroke=.2) +
  geom_vline(xintercept = 3) +
  geom_point(data = averages, size = 3, pch = 22, col="grey95", fill = "black", stroke=.5) +
  geom_point(data = human_averages, size = 3, pch = 21, col="grey95", fill ="black", stroke=.5) +
  facet_wrap(~label, nrow=3) +
  geom_text(data = tibble(avg = c(3.5, 3.5)+.4, y = c(.55, .7),
                          tag ="", 
                          label = factor(labels[2]),
                          text = c("LLM","Human")),
            mapping = aes(label = text),
            fontface = "bold", size=3, hjust = 0) +
  geom_point(data = tibble(avg = 3.6, y = .55,
                          tag ="", 
                          label = factor(labels[2]),
                          text = c("LLM","Human")),
             size = 3, pch = 22, col="grey95", fill ="black", stroke=.5) +
  geom_point(data = tibble(avg = 3.6, y = .7,
                           tag ="", 
                           label = factor(labels[2]),
                           text = c("LLM","Human")),
             size = 3, pch = 21, col="grey95", fill ="black", stroke=.5) +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA)) +
  theme(strip.text = element_markdown(),
        legend.position = "none") +
  scale_color_viridis_d(option = "G", begin = .2, end = .8) 
  

d_new = d |>
  group_by(dim) |> 
  mutate(top = get_top(avg),
         tag_censored = ifelse(top, tag, "")) |> 
  ungroup()

p = p +
  ggrepel::geom_text_repel(seed = 42, max.time = Inf, data = d_new, mapping = aes(label = tag_censored), 
                           size = 1.5, segment.size = .1,
                           point.padding = 0, box.padding = .1, 
                           max.overlaps = 200, 
                           min.segment.length = 0) +
  xlim(c(.5, 5.5)) + 
  ylim(c(.5, 1.5)) +
  labs(x = "Prescription") + 
  theme(axis.title.y = element_blank(),
        axis.text.y = element_blank()) 


ggsave(filename = "figures/03b_dimensions.png", p, device = "png", bg = "transparent", width = 8, height=4.8)




# Export the numerical results used in the figures.
write_csv(human_alignment, "results/human_alignment.csv")
write_csv(human_ai_alignment, "results/human_ai_alignment.csv")
write_csv(bind_rows(human_avg_alignment |> mutate(comparison = "human-human"),
                   human_ai_avg_alignment |> mutate(comparison = "human-LLM")), "results/aggregate_alignment.csv")
write_csv(average, "results/prescriptivity_overall.csv")
write_csv(book_means, "results/prescriptivity_sources.csv")
write_csv(normative_topics, "results/prescriptivity_topics.csv")
write_csv(polarity_llm, "results/polarity_llm.csv")
write_csv(polarity_human, "results/polarity_human.csv")
write_csv(averages |> select(name, avg, se), "results/dimension_averages.csv")
write_csv(averages_books |> select(book, name, avg, se), "results/dimension_sources.csv")
write_csv(human_averages |> select(dimension, avg), "results/dimension_human.csv")
write_csv(d |> select(tag, dim, avg), "results/dimension_topics.csv")
writeLines(capture.output(sessionInfo()), "results/sessionInfo.txt")
message("Analysis complete: five figures and numerical results written.")
