# Load packages ----
library(shiny)
library(quantmod)

# Source helpers ----
source("helpers.R")

# User interface ----
ui <- fluidPage(
  titlePanel("stockVis"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Select a stock to examine. 
               Information will be collected from Yahoo finance."),
      
      textInput("symb", "Symbol", "SPY"),
      
      dateRangeInput("dates",
                     "Date range",
                     start = "2013-01-01",
                     end = as.character(Sys.Date())),
      
      br(),
      br(),
      
      checkboxInput("log", "Plot y axis on log scale",
                    value = FALSE),
      
      checkboxInput("adjust",
                    "Adjust prices for inflation", value = FALSE)
    ),
    
    mainPanel(plotOutput("plot"))
  )
)

# Server logic
server <- function(input, output) {
  
  # At first: 
  
  # output$plot <- renderPlot({
  #   data <- getSymbols(input$symb, src = "yahoo",
  #                      from = input$dates[1],
  #                      to = input$dates[2],
  #                      auto.assign = FALSE)
  #   
  #   chartSeries(data, theme = chartTheme("white"),
  #               type = "line", log.scale = input$log, TA = NULL)
  # })
  
  # However, in this case, each time renderPlot re-runs,
  # it re-fetches the data from Yahoo finance with getSymbols, and
  # it re-draws the chart with the correct axis.
  # This is not good, because you do not need to re-fetch the data to re-draw 
  # the plot. In fact, Yahoo finance will cut you off if you re-fetch your data 
  # too often (because you begin to look like a bot). But more importantly, 
  # re-running getSymbols is unnecessary work, which can slow down your app and 
  # consume server bandwidth.
  
  # Also (for inflation adjustment): 
  
  # output$plot <- renderPlot({   
  #   data <- dataInput() (see below))
  #   if (input$adjust) data <- adjust(dataInput())
  #   
  #   chartSeries(data, theme = chartheme("white"),
  #               type = "line", log.scale = input$log, TA = NULL)
  # }) 
  
  # This is bad because adjust is called inside renderPlot. If the adjust box is 
  # checked, the app will readjust all of the prices each time you switch from a 
  # normal y scale to a logged y scale. This readjustment is unnecessary work.

  
  dataInput <- reactive({ # using reactive expression to limit what gets rerun 
    getSymbols(input$symb, src = "yahoo", # returns an updated value whenever original widget input (symb) changes 
               from = input$dates[1],
               to = input$dates[2],
               auto.assign = FALSE)
  })
  
  finalInput <- reactive({  
    if (!input$adjust) return(dataInput())
    adjust(dataInput())
  })

  output$plot <- renderPlot({
    
    # Shiny keeps track of which reactive expressions an output object depends on, 
    # as well as which widget inputs. Shiny will automatically re-build an object if
    # an input value in the objects’s render* function changes, or a reactive 
    # expression in the objects’s render* function becomes obsolete.
    
    chartSeries(finalInput(), theme = chartTheme("white"),
                type = "line", log.scale = input$log, TA = NULL)
  }) 
}

# Run the app
shinyApp(ui, server)