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
