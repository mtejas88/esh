library(shiny)
shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
      @import url('//fonts.googleapis.com/css?family=Roboto+Slab');
      @import url('//fonts.googleapis.com/css?family=Lato:300');
    
      body {
        background-color: #FFFFFF;
        font-family: 'Lato', sans-serif;
                    font-weight: 300;
                    line-height: 1.1;
                    font-size: 14pt;
                    color: #899DA4;
    }
      
      h1 {
        font-family: 'Roboto Slab';
        font-weight: 500;
        line-height: 1.1;
        color: #F26B21;
      }

      h2 {
        font-family: 'Lato', sans-serif;
                    font-weight: 300;
                    line-height: 1.1;
                    font-size: 12pt;
                    color: #899DA4;
      }
    shiny-plot-output {
        background-color: #00EFD1;
    }

      .test {
        font-family: 'Roboto Slab', serif;
                    font-weight: 100;
                    line-height: 1.1;
                    font-size: 18pt;
                    margin-left: 500px;
                    text-align: left;
                    color: #899DA4;
      }

      .well {
                    background-color: #FFFFFF;
      }

      .irs-bar {
                    background-color: #F26B21;
      }

      .irs-from {
                    background-color: #F26B21;
      }

      .irs-to {
                    background-color: #F26B21;
      }

      a {
              color: #F26B21;
      }
      .shiny-output-error-validation {
              margin-top: 25px;
              margin-left: 10px;
      }
    "))
  ),
  title="Price Dispersion",
  titlePanel(h1("Price Dispersion")),
  sidebarLayout(
    conditionalPanel(condition="input.condition_panel == 'Cost - Box and Whiskers'",
      sidebarPanel(
      sliderInput("bandwidth",
                  h2("Circuit Size"),
                  min = 0,
                  max = 10000,
                  value = c(0,10000),
                  step = 50),
      selectInput("connection", 
                  h2("Select Connection Type"),
                  choices = c("Fiber", "Copper", "Cable / DSL", "Fixed Wireless", "Other / Uncategorized")),
      selectInput("locale", 
                  h2("Select District Locale"), 
                  choices = c('Rural', 'Small Town', 'Suburban', 'Urban'), selected="Rural"),
      selectInput("size", 
                  h2("Select District Size"), 
                  choices = c('Tiny', 'Small', 'Medium', 'Large', 'Mega'), selected="Tiny"),
      selectInput("state", 
                  h2("Select State"), 
                  choices = c('All', 'CA', 'IN', 'MT', 'MN'), selected="Tiny"),
      width=3
    )),
    mainPanel(
      tabsetPanel(
        tabPanel("Cost - Box and Whiskers", imageOutput("distPlot", height="550px", width="1000px"),
                 div(id="test1", class="test", textOutput("n_observations"))),
        tabPanel("Cost - Histogram", plotOutput("histPlot", height="800px", width="1000px")),
      id="condition_panel"
  )
)
)))