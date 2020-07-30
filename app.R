# Load packages ----
library(shiny)
library(plotly)
library(ggplot2)
library(dplyr)
library(ggthemes)
library(zoo)
# Load data ----
filenames <- Sys.glob("data/health_metrics_*.csv")
newdates <- gsub(".csv", "", sub("data/health_metrics_", "", filenames))
datenames <- as.Date(newdates, format = "%Y-%m-%d")
data <- read.csv(file=filenames[which.max(datenames)], 
                 header=TRUE, 
                 sep=",",
                 stringsAsFactors = FALSE,
                 col.names = c("Date", "Weight", "Body_Fat", "Protein", "Fat", 
                               "Carbs", "Kcal_Input", "Kcal_Output", 
                               "Kcal_Deficit"),
                 colClasses = c('character', 'numeric', 'numeric', 
                                'numeric', 'numeric', 'numeric', 'numeric', 
                                'numeric', 'numeric'),
                 na.strings = c("", ".", "NA")
                 )
data$Date <- as.Date(data$Date, format = '%m/%d/%y')
data <- distinct(data, Date, .keep_all = TRUE)

# Source helpers ----
source("~/DSwork/health-app/helpers.R")

# User interface ----
ui <- fluidPage(
    tags$head(tags$script(src = "message-handler.js")),
    titlePanel("Health Tracking"),
    sidebarLayout(
        sidebarPanel(
            dateInput('day', label = "Date of Values", value = format(Sys.Date(), "%Y/%m/%d")),
            numericInput("bw", label = "Body Weight", value = 0),
            numericInput("bf", label = "Body Fat %", value = 0),
            numericInput("pro", label = "Protein", value = NA),
            numericInput("fat", label = "Fat", value = NA),
            numericInput("carb", label = "Carbs", value = NA),
            numericInput("calin", label = "Calories Consumed", value = 0),
            numericInput("calout", label = "Calories Expended", value = 0),
            actionButton('button', 'ENTER'),
            width = 2
        ),
        mainPanel(plotlyOutput("plot_bw"),
                  plotlyOutput("plot_bf"),
                  plotlyOutput("plot_def"),
                  plotlyOutput("plot_cals"),
                  width=10
        )
        
    )
)

# Server logic ----
server <- function(input, output, session) {
    # Calculated features
    data$Kcal_Deficit <- data$Kcal_Input - data$Kcal_Output
    columns_rm <- c('Weight', 'Body_Fat', 'Kcal_Input', 'Kcal_Output', 'Kcal_Deficit')
    data <- make_rm(data, columns_rm, 14)
    # Initial plots (without new values)
    # Body weight plot
    output$plot_bw <- renderPlotly({
        bw <- ggplot(data, aes(x=Date)) +
            geom_line(aes(y=Weight), color = 'black', alpha=0.25, size=0.25) +
            geom_line(aes(y=Weight_14_Day_Rolling_Mean), color = 'black', size=1) +
            theme_minimal() +
            theme(axis.text.x=element_text(angle=60, hjust=1)) +
            scale_x_date(date_labels = "%m-%d-%y") +
            scale_x_date(date_breaks = "1 month") +
            ylab("Body Weight") +
            xlab("") +
            ggtitle("Body Weight (lbs) with Moving Average")
        ggplotly(bw)
    })
    # Body fat plot
    output$plot_bf <- renderPlotly({
        bf <- ggplot(data, aes(x=Date)) +
            geom_line(aes(y=Body_Fat), color = 'black', alpha=0.25, size=0.25) +
            geom_line(aes(y=Body_Fat_14_Day_Rolling_Mean), color = 'black', size=1) +
            theme_minimal() +
            theme(axis.text.x=element_text(angle=60, hjust=1)) +
            scale_x_date(date_labels = "%m-%d-%y") +
            scale_x_date(date_breaks = "1 month") +
            ylab("Body Fat %") +
            xlab("") +
            ggtitle("Body Fat (%) with Moving Average")
        ggplotly(bf)
    })
    # Deficit Plot
    output$plot_def <- renderPlotly({
        def <- ggplot(data, aes(x=Date)) +
            geom_line(aes(y=Kcal_Deficit), color = "black", alpha=0.25, size=0.25) + 
            geom_line(aes(y=Kcal_Deficit_14_Day_Rolling_Mean), color = 'black', size=1) +
            geom_hline(yintercept=-1000, color="orange", size=0.25) +
            theme_minimal() +
            theme(axis.text.x=element_text(angle=60, hjust=1)) +
            scale_x_date(date_labels = "%m-%d-%y") +
            scale_x_date(date_breaks = "1 month") +
            ylab("Kilo Calories") +
            xlab("") +
            ggtitle("Calorie Deficit with Moving Average")
        ggplotly(def)
    })
    # Calories Plot
    output$plot_cals <- renderPlotly({
        cals <- ggplot(data, aes(x=Date)) +
            geom_line(aes(y=Kcal_Input), color = "black", alpha=0.25, size=0.25) + 
            geom_line(aes(y=Kcal_Output), color = "darkred", alpha=0.25, size=0.25) +
            geom_line(aes(y=Kcal_Input_14_Day_Rolling_Mean), color = 'black', size=1) +
            geom_line(aes(y=Kcal_Output_14_Day_Rolling_Mean), color = 'darkred', size=1) +
            theme_minimal() +
            theme(axis.text.x=element_text(angle=60, hjust=1)) +
            scale_x_date(date_labels = "%m-%d-%y") +
            scale_x_date(date_breaks = "1 month") +
            ylab("Kilo Calories") +
            xlab("") + 
            ggtitle("Calories Consumed and Expended with Moving Averages")
        ggplotly(cals)
    })
    
    # Look for button click
    observeEvent(input$button, {
        # Create df of input values
        surplus = input$calin - input$calout
        inputs_df <- data.frame(Date = input$day, 
                                Weight = input$bw, 
                                Body_Fat = input$bf,
                                Protein = input$pro,
                                Fat = input$fat,
                                Carbs = input$carb,
                                Kcal_Input = input$calin,
                                Kcal_Output = input$calout,
                                Kcal_Deficit = surplus
        )
        # Append input values to old data and save out
        new_data <- rbind(data[,1:9], inputs_df)
        # Calculated features
        columns_rm <- c('Weight', 'Body_Fat', 'Kcal_Input', 'Kcal_Output', 
                        'Kcal_Deficit')
        new_data <- make_rm(new_data, columns_rm, 14)
        write.csv(new_data, file = paste0("~/DSwork/health-app/data/", 
                                          "health_metrics_", 
                                          Sys.Date(), 
                                          ".csv"), 
                  row.names = FALSE)
        # Need to add code to replot graphs with new data
        # Body weight plot
        output$plot_bw <- renderPlotly({
            bw <- ggplot(new_data, aes(x=Date)) +
                geom_line(aes(y=Weight), color = 'black', alpha=0.25, size=0.25) +
                geom_line(aes(y=Weight_14_Day_Rolling_Mean), color = 'black', size=1) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Body Weight") +
                xlab("") +
                ggtitle("Body Weight (lbs) with Moving Average")
            ggplotly(bw)
        })
        # Body fat plot
        output$plot_bf <- renderPlotly({
            bf <- ggplot(new_data, aes(x=Date)) +
                geom_line(aes(y=Body_Fat), color = 'black', alpha=0.25, size=0.25) +
                geom_line(aes(y=Body_Fat_14_Day_Rolling_Mean), color = 'black', size=1) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Body Fat %") +
                xlab("") +
                ggtitle("Body Fat (%) with Moving Average")
            ggplotly(bf)
        })
        # Deficit Plot
        output$plot_def <- renderPlotly({
            def <- ggplot(new_data, aes(x=Date)) +
                geom_line(aes(y=Kcal_Deficit), color = "black", alpha=0.25, size=0.25) + 
                geom_line(aes(y=Kcal_Deficit_14_Day_Rolling_Mean), color = 'black', size=1) +
                geom_hline(yintercept=-1000, color="orange", size=0.25) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Kilo Calories") +
                xlab("") +
                ggtitle("Calorie Deficit with Moving Average")
            ggplotly(def)
        })
        # Calories Plot
        output$plot_cals <- renderPlotly({
            cals <- ggplot(new_data, aes(x=Date)) +
                geom_line(aes(y=Kcal_Input), color = "black", alpha=0.25, size=0.25) + 
                geom_line(aes(y=Kcal_Output), color = "darkred", alpha=0.25, size=0.25) +
                geom_line(aes(y=Kcal_Input_14_Day_Rolling_Mean), color = 'black', size=1) +
                geom_line(aes(y=Kcal_Output_14_Day_Rolling_Mean), color = 'darkred', size=1) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Kilo Calories") +
                xlab("") + 
                ggtitle("Calories Consumed and Expended with Moving Averages")
            ggplotly(cals)
        })
    })
}

# Run the app
shinyApp(ui, server)
