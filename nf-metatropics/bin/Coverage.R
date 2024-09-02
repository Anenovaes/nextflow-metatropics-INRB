#!/usr/bin/env Rscript

library(ggplot2)
library(dplyr)
library(stringr)

# List all .txt files in the current directory
files <- list.files(pattern = "*.coverage.txt")

# Initialize an empty list to store data frames
data_list <- list()

# Loop through each file
for (file in files) {
  # Read the data
  data <- read.table(file, header = FALSE)
  
  # Extract sample name from file name (including NC number)
  sample_name <- sub("(.*)_T1\\.(NC_[0-9]+)_.*", "\\1_\\2", file)
  
  # Assign column names
  colnames(data) <- c("reference", "position", "depth")
  
  # Change depth to numeric and calculate log depth
  data$depth <- as.numeric(data$depth)
  data$log_depth <- log10(data$depth)
  data$log_depth[is.infinite(data$log_depth)] <- 0
  
  # Add color column based on depth
  data$color <- ifelse(data$depth > 5, "Above 5", "Below 5")
  
  # Add sample name column
  data$name <- sample_name
  
  # Add to list
  data_list[[sample_name]] <- data
}

# Combine all data frames
combined_data <- do.call(rbind, data_list)

# Set bin size (change this value to adjust binning)
bin_size <- 50

# Calculate average depth with binning
combined_data_binned <- combined_data %>%
  mutate(bin_start = floor(position / bin_size) * bin_size) %>%
  group_by(name, bin_start) %>%
  summarise(avg_depth = mean(log_depth), .groups = 'drop')

# Uncomment the following lines and comment out the above if you want to use position without binning
# combined_data_binned <- combined_data %>%
#   group_by(name, position) %>%
#   summarise(avg_depth = mean(log_depth), .groups = 'drop')

# Calculate log10(5)
log_5 <- log10(5)

# Function to create and save plot for a group of samples
create_plot <- function(data, group_number) {
  p <- ggplot(data, aes(x = bin_start, y = avg_depth)) +  # Use 'position' instead of 'bin_start' if not binning
    geom_line(color = "#057215") +
    geom_segment(data = subset(data, avg_depth < log_5),
                 aes(xend = bin_start, y = 0, yend = -0.3),  # Use 'position' instead of 'bin_start' if not binning
                 color = "darkred", alpha = 1, linewidth = 0.2) +
    geom_hline(yintercept = log_5, linetype = "dashed", color = "black") +
    theme_bw() +
    facet_wrap(~ name, scales = "free_x") +
    labs(title = paste("Coverage Distribution - Group", group_number),
         x = "Position",
         y = "Log10(Depth)")
  
  filename <- paste0("coverage_distribution_group_", group_number, ".pdf")
  ggsave(filename, plot = p, width = 12, height = 8, units = "in")
}

# Group samples and create plots
sample_names <- unique(combined_data_binned$name)
num_groups <- ceiling(length(sample_names) / 9)
for (i in 1:num_groups) {
  start_index <- (i - 1) * 9 + 1
  end_index <- min(i * 9, length(sample_names))
  group_samples <- sample_names[start_index:end_index]
  
  group_data <- combined_data_binned %>%
    filter(name %in% group_samples)
  
  create_plot(group_data, i)
}
