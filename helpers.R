# Helper functions for health-app
make_rm <- function(input_data, columns, period){
    numcols <- length(columns)
    numrows <- nrow(input_data)
    output <- matrix(ncol=numcols, nrow=numrows)
    colnames(output) <- columns
    for(c in columns){
        output[,c] <- rollapply(input_data[[c]], 
                  period, 
                  mean, 
                  na.rm=TRUE, 
                  partial=TRUE, 
                  fill='extend')
    }
    colnames(output) <- paste0(columns, "_Rolling_Mean")
    new_data <- cbind(input_data, data.frame(output))
    return(data.frame(new_data))
}

# inputs_df <- data.frame(Date = '2/5/1979',
#                         Weight = 0,
#                         Body_Fat = 0,
#                         Protein = NA,
#                         Fat = NA,
#                         Carbs = NA,
#                         Kcal_Input = 0,
#                         Kcal_Output = 0
# )
# new_data <- rbind(data[,1:8], inputs_df)
# new_data$Kcal_Deficit <- new_data$Kcal_Input - new_data$Kcal_Output
# columns_rm <- c('Weight', 'Body_Fat', 'Kcal_Input', 'Kcal_Output', 'Kcal_Deficit')
# new_data_rm <- make_rm(new_data, columns_rm, 13)
