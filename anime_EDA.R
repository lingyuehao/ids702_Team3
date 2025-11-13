library(tidyverse)

anime <- read.csv("https://github.com/lingyuehao/ids702_Team3/raw/refs/heads/main/anime_dataset.csv")

glimpse(anime)


#====================================

# Summary statistics
summary(anime)

# Check missing values
colSums(is.na(anime))

# Remove the 'synopsis' column
anime <- anime %>%
  select(-synopsis)

#====================================
#====================================

# Seperate genre
anime_clean <- anime %>%
  mutate(genres = str_remove_all(genres, "\\[|\\]|'")) %>%  
  separate_rows(genres, sep = ",\\s*") %>%
  filter(!is.na(genres) & genres != "")

anime_clean <- anime_clean %>%
mutate(studios = str_remove_all(studios, "\\[|\\]|'")) %>%  
  separate_rows(studios, sep = ",\\s*") %>%
  filter(!is.na(studios) & studios != "")

#====================================
# How do genres and studios influence anime ratings and popularity?

genre_summary <- anime_clean %>%
  group_by(genres) %>%
  summarise(
    avg_score = mean(score, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

top10_genre <- genre_summary %>%
  slice_max(avg_score, n = 10) %>%
  mutate(
    rank = dense_rank(desc(avg_score)),
    highlight = if_else(rank <= 3, "Top 3", "Other")
  ) %>%
  arrange(avg_score)

ggplot(top10_genre, aes(x = reorder(genres, avg_score), y = avg_score, fill = highlight)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.2f", avg_score), color = highlight),
            hjust = -0.1, size = 3.8, show.legend = FALSE) +
  coord_flip(ylim = c(6, max(top10_genre$avg_score) + 0.4)) + 
  scale_fill_manual(values = c("Top 3" = "#d62728", "Other" = "#4c78a8")) +
  scale_color_manual(values = c("Top 3" = "#d62728", "Other" = "#1b2838")) +
  labs(title = "Top 10 Genres by Average Score",
       subtitle = "Scores shown on bars; Top 3 highlighted in red",
       x = "Genre", y = "Average Score") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        plot.margin = margin(10, 30, 10, 10))

#====================

studio_summary <- anime_clean %>%
  group_by(studios) %>%
  summarise(
    avg_score = mean(score, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) 
  
top10_studios <- studio_summary %>%
  arrange(desc(avg_score), desc(n), studios) %>%  
  slice_head(n = 10) %>%                         
  mutate(
    highlight = if_else(row_number() <= 3, "Top 3", "Other")
  ) %>%
  arrange(avg_score)


ggplot(top10_studios, aes(x = reorder(studios, avg_score), y = avg_score, fill = highlight)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.2f", avg_score), color = highlight),
            hjust = -0.1, size = 3.8, show.legend = FALSE) +
  coord_flip(ylim = c(6, max(top10_studios$avg_score) + 0.4)) +
  scale_fill_manual(values = c("Top 3" = "#d62728", "Other" = "#4c78a8")) +
  scale_color_manual(values = c("Top 3" = "#d62728", "Other" = "#1b2838")) +
  labs(title = "Top 10 Studios by Average Score",
       subtitle = "Scores shown on bars; Top 3 highlighted in red",
       x = "Studio", y = "Average Score") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        plot.margin = margin(10, 30, 10, 10))

#====================================
#====================================
# Is there a relationship between the number of episodes and viewer engagement? 

# Relationship between Episodes and Members
anime %>%
  filter(!is.na(episodes)) %>%
  mutate(ep_bin = cut(
    episodes,
    breaks = c(0, 12, 24, 50, 100, 200, 500, Inf),
    labels = c("≤12", "13–24", "25–50", "51–100", "101–200", "201–500", "500+"),
    right = TRUE, include.lowest = TRUE
  )) %>%
  group_by(ep_bin) %>%
  summarise(avg_members = mean(members, na.rm = TRUE), n = n(), .groups = "drop") %>%
  ggplot(aes(x = ep_bin, y = avg_members)) +
  scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
  geom_col(fill = "#4c78a8", width = 0.7) +
  geom_text(aes(label = scales::label_number(scale_cut = scales::cut_short_scale())(avg_members)),
            vjust = 1.2, color = "white", size = 3.5) +
  labs(
    title = "Average Members by Episode Range",
    x = "Episode Range", y = "Average Members"
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.x = element_blank())

