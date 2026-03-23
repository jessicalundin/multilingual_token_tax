# Fertility vs Accuracy Analysis PER SUBJECT PER LANGUAGE for AfriMMLU Results
# Author: Analysis Script
# Date: 2025

# Set working directory and create output subdirectories
setwd("/Users/[redacted]/Documents/repos/llm-research/AfriMMLU/afrimmlu_results")
dir.create("R_linear_fit/figures_per_subject_per_language", showWarnings = FALSE, recursive = TRUE)
dir.create("R_linear_fit/statistics_per_subject_per_language", showWarnings = FALSE, recursive = TRUE)

# Function to extract model name from filename
extract_model_name <- function(filename) {
  gsub("_full_results\\.csv$", "", basename(filename))
}

# Function to analyze fertility vs accuracy per subject per language for a single model
analyze_model_per_subject_per_language <- function(file_path) {
  model_name <- extract_model_name(file_path)
  cat("Processing model:", model_name, "\n")
  
  # Read the data
  tryCatch({
    data <- read.csv(file_path, stringsAsFactors = FALSE)
    
    # Convert accuracy to numeric (handle TRUE/FALSE)
    data$accuracy_numeric <- as.numeric(data$accuracy == "True" | data$accuracy == TRUE)
    
    # Get fertility column - prefer subject-wise, then row-wise
    if ("fertility_subject_wise" %in% names(data)) {
      data$fertility <- data$fertility_subject_wise
    } else if ("fertility_row_wise" %in% names(data)) {
      data$fertility <- data$fertility_row_wise
    } else if ("fertility_language_wise" %in% names(data)) {
      data$fertility <- data$fertility_language_wise
    } else {
      cat("No fertility column found for model:", model_name, "\n")
      return(NULL)
    }
    
    # Filter out missing values and exclude Amharic
    data <- data[!is.na(data$fertility) & !is.na(data$accuracy_numeric), ]
    data <- data[data$language != "amh", ]  # Exclude Amharic
    
    # Skip OpenAI o1 model
    if (grepl("OpenAI_o1", model_name)) {
      cat("Skipping OpenAI o1 model\n")
      return(NULL)
    }
    
    # Check if we have sufficient data
    if (nrow(data) < 50) {
      cat("Insufficient data for model:", model_name, "\n")
      return(NULL)
    }
    
    # Calculate average fertility and accuracy by SUBJECT and LANGUAGE
    subjects <- unique(data$subject)
    subjects <- subjects[!is.na(subjects)]
    languages <- unique(data$language)
    languages <- languages[!is.na(languages)]
    
    if (length(subjects) < 3 || length(languages) < 3) {
      cat("Insufficient subjects or languages for model:", model_name, "\n")
      return(NULL)
    }
    
    # Calculate subject-language averages
    subject_language_stats <- data.frame(
      subject = character(),
      language = character(),
      avg_fertility = numeric(),
      avg_accuracy = numeric(),
      n_observations = numeric(),
      stringsAsFactors = FALSE
    )
    
    for (subj in subjects) {
      for (lang in languages) {
        subj_lang_data <- data[data$subject == subj & data$language == lang, ]
        
        if (nrow(subj_lang_data) >= 3) {  # Need at least 3 observations per subject-language combo
          avg_fert <- mean(subj_lang_data$fertility, na.rm = TRUE)
          avg_acc <- mean(subj_lang_data$accuracy_numeric, na.rm = TRUE)
          n_obs <- nrow(subj_lang_data)
          
          if (!is.na(avg_fert) && !is.na(avg_acc)) {
            subject_language_stats <- rbind(subject_language_stats, data.frame(
              subject = subj,
              language = lang,
              avg_fertility = avg_fert,
              avg_accuracy = avg_acc,
              n_observations = n_obs,
              stringsAsFactors = FALSE
            ))
          }
        }
      }
    }
    
    # Check if we have sufficient data after averaging
    if (nrow(subject_language_stats) < 10) {
      cat("Insufficient subject-language combinations for model:", model_name, "\n")
      return(NULL)
    }
    
    # Fit linear models per subject (fertility vs accuracy across languages)
    subject_fits <- list()
    subject_stats_list <- list()
    subject_summary_list <- list()
    
    valid_subjects <- c()
    
    for (subj in subjects) {
      subj_data <- subject_language_stats[subject_language_stats$subject == subj, ]
      
      # Need at least 4 languages for meaningful regression per subject
      if (nrow(subj_data) >= 4) {
        # Fit linear model for this subject across languages
        subj_lm <- lm(avg_accuracy ~ avg_fertility, data = subj_data)
        subj_summary <- summary(subj_lm)
        
        # Store the fit
        subject_fits[[subj]] <- subj_lm
        valid_subjects <- c(valid_subjects, subj)
        
        # Extract subject model statistics
        subj_coef_table <- coef(subj_summary)
        subj_conf_int <- confint(subj_lm)
        
        subj_model_stats <- data.frame(
          model = model_name,
          subject = subj,
          term = c("(Intercept)", "avg_fertility"),
          estimate = subj_coef_table[, "Estimate"],
          std_error = subj_coef_table[, "Std. Error"],
          t_value = subj_coef_table[, "t value"],
          p_value = subj_coef_table[, "Pr(>|t|)"],
          conf_low = subj_conf_int[, "2.5 %"],
          conf_high = subj_conf_int[, "97.5 %"],
          n_languages = nrow(subj_data),
          stringsAsFactors = FALSE
        )
        
        subj_model_summary <- data.frame(
          model = model_name,
          subject = subj,
          r_squared = subj_summary$r.squared,
          adj_r_squared = subj_summary$adj.r.squared,
          p_value = pf(subj_summary$fstatistic[1], subj_summary$fstatistic[2], subj_summary$fstatistic[3], lower.tail = FALSE),
          residual_se = subj_summary$sigma,
          df = subj_summary$df[2],
          n_languages = nrow(subj_data),
          stringsAsFactors = FALSE
        )
        
        subject_stats_list[[subj]] <- subj_model_stats
        subject_summary_list[[subj]] <- subj_model_summary
      }
    }
    
    # Check if we have any valid subjects
    if (length(valid_subjects) == 0) {
      cat("No subjects with sufficient languages for model:", model_name, "\n")
      return(NULL)
    }
    
    # Combine all subject statistics
    all_subject_stats <- do.call(rbind, subject_stats_list)
    all_subject_summaries <- do.call(rbind, subject_summary_list)
    
    
    # Create 1x5 subplot layout for LaTeX paper
    png(filename = file.path("R_linear_fit/figures_per_subject_per_language", 
                            paste0(model_name, "_fertility_vs_accuracy_1x5_subplots.png")),
        width = 15, height = 3, units = "in", res = 300, bg = "white")
    
    # Set up 1x5 layout
    par(mfrow = c(1, min(5, length(valid_subjects))), mar = c(3, 3, 2.5, 1), 
        mgp = c(1.8, 0.6, 0), cex = 0.8)
    
    # Use consistent colors for subjects
    subject_colors <- rainbow(length(valid_subjects))
    names(subject_colors) <- valid_subjects
    
    # Plot each subject in its own subplot (up to 5 subjects)
    subjects_to_plot <- valid_subjects[1:min(5, length(valid_subjects))]
    
    for (subj in subjects_to_plot) {
      subj_data <- subject_language_stats[subject_language_stats$subject == subj, ]
      subj_summary_row <- all_subject_summaries[all_subject_summaries$subject == subj, ]
      subj_lm <- subject_fits[[subj]]
      
      # Create scatter plot for this subject
      plot(subj_data$avg_fertility, subj_data$avg_accuracy,
           xlab = "Fertility",
           ylab = "Accuracy", 
           main = subj,
           pch = 19, 
           col = "steelblue", 
           cex = 1.0,
           xlim = range(subject_language_stats$avg_fertility),
           ylim = c(0, 1))
      
      # Add regression line with confidence interval
      x_range <- seq(min(subj_data$avg_fertility), max(subj_data$avg_fertility), length.out = 50)
      pred_int <- predict(subj_lm, newdata = data.frame(avg_fertility = x_range), interval = "confidence")
      
      # Add confidence band
      polygon(c(x_range, rev(x_range)), 
              c(pred_int[, "lwr"], rev(pred_int[, "upr"])), 
              col = rgb(1, 0.75, 0.8, 0.3), border = NA)
      
      # Add regression line
      lines(x_range, pred_int[, "fit"], col = "red", lwd = 2)
      
      # Add R² to plot
      text(x = min(subj_data$avg_fertility) + 0.1 * diff(range(subj_data$avg_fertility)),
           y = 0.95,
           labels = paste("R² =", round(subj_summary_row$r_squared, 3)),
           cex = 0.7, adj = 0)
      
      # Add grid
      grid()
    }
    
    
    dev.off()
    
    # Individual model CSV files are skipped - only keep combined files
    
    cat("Completed analysis for model:", model_name, "\n")
    cat("Analyzed", length(valid_subjects), "subjects across", length(languages), "languages\n")
    cat("Subject R² range:", round(min(all_subject_summaries$r_squared), 3), "to", round(max(all_subject_summaries$r_squared), 3), "\n")
    
    # Print subject summaries
    for (subj in valid_subjects) {
      subj_summary <- all_subject_summaries[all_subject_summaries$subject == subj, ]
      cat(sprintf("  %s: R² = %6.4f (p = %s)\n", 
                  subj, 
                  subj_summary$r_squared, 
                  format.pval(subj_summary$p_value)))
    }
    cat("\n")
    
    return(list(
      model = model_name,
      stats = all_subject_stats,
      summary = all_subject_summaries,
      data = subject_language_stats,
      valid_subjects = valid_subjects
    ))
    
  }, error = function(e) {
    cat("Error processing", model_name, ":", e$message, "\n")
    return(NULL)
  })
}

# Main analysis
cat("=== Fertility vs Accuracy Per Subject Per Language Analysis ===\n\n")

# Find all full results files
full_results_files <- list.files("full", pattern = "*_full_results.csv$", full.names = TRUE)

if (length(full_results_files) == 0) {
  stop("No *_full_results.csv files found in the 'full' directory")
}

cat("Found", length(full_results_files), "model files to process:\n")
cat(paste(basename(full_results_files), collapse = ", "), "\n\n")

# Process all models
all_results <- list()
for (file in full_results_files) {
  result <- analyze_model_per_subject_per_language(file)
  if (!is.null(result)) {
    all_results[[length(all_results) + 1]] <- result
  }
}

if (length(all_results) == 0) {
  stop("No models were successfully processed")
}

# Combine all model statistics
all_coefficients <- do.call(rbind, lapply(all_results, function(x) x$stats))
all_summaries <- do.call(rbind, lapply(all_results, function(x) x$summary))

# Save combined statistics
write.csv(all_coefficients, "R_linear_fit/statistics_per_subject_per_language/all_models_per_subject_coefficients.csv", row.names = FALSE)
write.csv(all_summaries, "R_linear_fit/statistics_per_subject_per_language/all_models_per_subject_summaries.csv", row.names = FALSE)

# Create summary showing average R² per model across subjects
model_summary <- aggregate(r_squared ~ model, data = all_summaries, FUN = function(x) c(mean = mean(x), sd = sd(x), n = length(x)))
model_summary <- data.frame(model_summary$model, model_summary$r_squared)
names(model_summary) <- c("model", "mean_r_squared", "sd_r_squared", "n_subjects")

write.csv(model_summary, "R_linear_fit/statistics_per_subject_per_language/model_average_r_squared_summary.csv", row.names = FALSE)

# Print final summary
cat("=== ANALYSIS COMPLETE ===\n")
cat("Successfully processed", length(all_results), "models\n")
cat("Results saved in R_linear_fit/statistics_per_subject_per_language/ and R_linear_fit/figures_per_subject_per_language/\n\n")

cat("Model Summary (Average R² Across Subjects):\n")
for (i in 1:nrow(model_summary)) {
  result <- model_summary[i, ]
  cat(sprintf("%-25s Mean R² = %6.4f (SD = %6.4f, n_subjects = %d)\n", 
              result$model, 
              result$mean_r_squared, 
              result$sd_r_squared,
              result$n_subjects))
}

cat("\nDetailed per-subject results saved in individual model files.\n")
cat("All analysis files have been saved successfully!\n")