# Load packages ----
library(shiny)
library(plotly)
library(ggplot2)
library(dplyr)
library(ggthemes)
library(zoo)
# Load test data ----
# filenames <- Sys.glob("data/testing_data_*.csv")
# newdates <- gsub(".csv", "", sub("data/testing_data_", "", filenames))
# datenames <- as.Date(newdates, format = "%Y-%m-%d")
# data <- read.csv(file=filenames[which.max(datenames)],
#                  header=TRUE,
#                  stringsAsFactors = FALSE,
#                  col.names = c("Date", "Weight", "Body_Fat", "Protein", "Fat",
#                                "Carbs", "Kcal_Input", "Kcal_Output"),
#                  colClasses = c('character', 'numeric', 'numeric',
#                                 'numeric', 'numeric', 'numeric', 'numeric',
#                                 'numeric'),
#                  na.strings = c("", ".", "NA")
# )
# rm(datenames, filenames, newdates)
# data$Date <- as.Date(data$Date, format = '%Y-%m-%d')
# data <- arrange(data, Date)
# data <- distinct(data, Date, .keep_all = TRUE)

# Load real data ----
filenames <- Sys.glob("data/health_metrics_*.csv")
newdates <- gsub(".csv", "", sub("data/health_metrics_", "", filenames))
datenames <- as.Date(newdates, format = "%Y-%m-%d")
data <- read.csv(file=filenames[which.max(datenames)],
                 header=TRUE,
                 stringsAsFactors = FALSE,
                 col.names = c("Date", "Weight", "Body_Fat", "Protein", "Fat",
                               "Carbs", "Kcal_Input", "Kcal_Output"),
                 colClasses = c('character', 'numeric', 'numeric',
                                'numeric', 'numeric', 'numeric', 'numeric',
                                'numeric'),
                 na.strings = c("", ".", "NA")
                 )
rm(datenames, filenames, newdates)
data$Date <- as.Date(data$Date, format = '%Y-%m-%d')
data <- arrange(data, Date)
data <- distinct(data, Date, .keep_all = TRUE)

# Source helpers ----
source("~/DSwork/health-app/helpers.R")

# User interface ----
ui <- fluidPage(
    titlePanel("Health Tracking"),
    sidebarLayout(
        sidebarPanel(
            dateInput('day', label = "Date of Values", 
                      value = format(Sys.Date()-1, "%Y/%m/%d")),
            numericInput("bw", label = "Body Weight", value = 0),
            numericInput("bf", label = "Body Fat %", value = 0),
            #numericInput("pro", label = "Protein", value = NA),
            #numericInput("fat", label = "Fat", value = NA),
            #numericInput("carb", label = "Carbs", value = NA),
            numericInput("calin", label = "Calories Consumed", value = 0),
            numericInput("calout", label = "Calories Expended", value = 0),
            actionButton('button', 'ENTER', icon("floppy-o"), 
                         style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
            br(),
            br(),
            sliderInput('movavg', label = 'Moving Average', 2, 28, value = 14),
            width = 2
        ),
        mainPanel(h5(textOutput('notifier')),
                  br(),
                  plotlyOutput("plot_bw", height = '300px'),
                  plotlyOutput("plot_bf", height = '300px'),
                  plotlyOutput("plot_def", height = '300px'),
                  plotlyOutput("plot_cals", height = '300px'),
                  width=10
        )
    )
)

# Server logic ----
server <- function(input, output, session) {
    # Calculated features
    max_date <- max(data$Date)
    data$Kcal_Deficit <- data$Kcal_Input - data$Kcal_Output
    columns_rm <- c('Weight', 'Body_Fat', 'Kcal_Input', 'Kcal_Output', 'Kcal_Deficit')
    # Notifier
    output$notifier <- renderText({
        paste0("Latest data displayed is from ", max_date, 
               ". You have chosen a moving average of ", input$movavg, ' days.')
    })
    # Calculate moving average based on slider input
    dataInput <- reactive({
        make_rm(data, columns_rm, input$movavg)
    })
    # Initial plots (without new values)
    # Body weight plot
    output$plot_bw <- renderPlotly({
        bw <- ggplot(dataInput(), aes(x=Date)) +
            geom_line(aes(y=Weight), color = 'black', alpha=0.25, size=0.25) +
            geom_line(aes(y=Weight_Rolling_Mean), color = 'black', size=1) +
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
        bf <- ggplot(dataInput(), aes(x=Date)) +
            geom_line(aes(y=Body_Fat), color = 'black', alpha=0.25, size=0.25) +
            geom_line(aes(y=Body_Fat_Rolling_Mean), color = 'black', size=1) +
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
        def <- ggplot(dataInput(), aes(x=Date)) +
            geom_line(aes(y=Kcal_Deficit), color = "black", alpha=0.25, size=0.25) + 
            geom_line(aes(y=Kcal_Deficit_Rolling_Mean), color = 'black', size=1) +
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
        cals <- ggplot(dataInput(), aes(x=Date)) +
            geom_line(aes(y=Kcal_Input), color = "black", alpha=0.25, size=0.25) + 
            geom_line(aes(y=Kcal_Output), color = "darkred", alpha=0.25, size=0.25) +
            geom_line(aes(y=Kcal_Input_Rolling_Mean), color = 'black', size=1) +
            geom_line(aes(y=Kcal_Output_Rolling_Mean), color = 'darkred', size=1) +
            theme_minimal() +
            theme(axis.text.x=element_text(angle=60, hjust=1)) +
            scale_x_date(date_labels = "%m-%d-%y") +
            scale_x_date(date_breaks = "1 month") +
            ylab("Kilo Calories") +
            xlab("") + 
            ggtitle("Calories Consumed and Expended with Moving Averages")
        ggplotly(cals)
    })
    
    # Look for button click ####
    observeEvent(input$button, {
        # Create df of input values
        inputs_df <- data.frame(Date = input$day, 
                                Weight = input$bw, 
                                Body_Fat = input$bf,
                                Protein = NA,
                                Fat = NA,
                                Carbs = NA,
                                Kcal_Input = input$calin,
                                Kcal_Output = input$calout
        )
        # Append input values to old data and save out
        if(input$bw == 99999){
            new_data <- rbind(data[,1:8], inputs_df)
            write.csv(new_data, file = paste0("~/DSwork/health-app/data/", 
                                              "testing_data_",
                                              Sys.Date(),
                                              ".csv"), 
                      row.names = FALSE)
        }else{
            new_data <- rbind(data[,1:8], inputs_df)
            write.csv(new_data, file = paste0("~/DSwork/health-app/data/", 
                                              "health_metrics_", 
                                              Sys.Date(), 
                                              ".csv"), 
                      row.names = FALSE)
        }
        # Calculated features
        max_date <- max(new_data$Date)
        # Notifier
        output$notifier <- renderText({
            paste0("Latest data displayed is from ", max_date, 
                   ". You have chosen a moving average of ", input$movavg, ' days.')
        })
        new_data$Kcal_Deficit <- new_data$Kcal_Input - new_data$Kcal_Output
        # Calculate moving average based on slider input
        dataInput <- reactive({
            make_rm(new_data, columns_rm, input$movavg)
        })
        # Save out the new row with the old data
        # Body weight plot with new values
        output$plot_bw <- renderPlotly({
            bw <- ggplot(dataInput(), aes(x=Date)) +
                geom_line(aes(y=Weight), color = 'black', alpha=0.25, size=0.25) +
                geom_line(aes(y=Weight_Rolling_Mean), color = 'black', size=1) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Body Weight") +
                xlab("") +
                ggtitle("Body Weight (lbs) with Moving Average")
            ggplotly(bw)
        })
        # Body fat plot with new values
        output$plot_bf <- renderPlotly({
            bf <- ggplot(dataInput(), aes(x=Date)) +
                geom_line(aes(y=Body_Fat), color = 'black', alpha=0.25, size=0.25) +
                geom_line(aes(y=Body_Fat_Rolling_Mean), color = 'black', size=1) +
                theme_minimal() +
                theme(axis.text.x=element_text(angle=60, hjust=1)) +
                scale_x_date(date_labels = "%m-%d-%y") +
                scale_x_date(date_breaks = "1 month") +
                ylab("Body Fat %") +
                xlab("") +
                ggtitle("Body Fat (%) with Moving Average")
            ggplotly(bf)
        })
        # Deficit Plot with new values
        output$plot_def <- renderPlotly({
            def <- ggplot(dataInput(), aes(x=Date)) +
                geom_line(aes(y=Kcal_Deficit), color = "black", alpha=0.25, size=0.25) + 
                geom_line(aes(y=Kcal_Deficit_Rolling_Mean), color = 'black', size=1) +
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
        # Calories Plot with new values
        output$plot_cals <- renderPlotly({
            cals <- ggplot(dataInput(), aes(x=Date)) +
                geom_line(aes(y=Kcal_Input), color = "black", alpha=0.25, size=0.25) + 
                geom_line(aes(y=Kcal_Output), color = "darkred", alpha=0.25, size=0.25) +
                geom_line(aes(y=Kcal_Input_Rolling_Mean), color = 'black', size=1) +
                geom_line(aes(y=Kcal_Output_Rolling_Mean), color = 'darkred', size=1) +
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
shinyApp(ui, server, options = list(port=4594))
