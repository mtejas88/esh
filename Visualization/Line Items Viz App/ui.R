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
        display: inline-block;
        margin-top: 0px;
      }

      img {
        font-family: 'Roboto Slab';
        font-weight: 500;
        line-height: 1.1;
        color: #F26B21;
        margin-top: 500px
        align: right;
        display: inline-block;
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
  title="Price Dispersion - EducationSuperHighway",
  titlePanel(div(h1("Price Dispersion"))), #, img(src='esh-logo.png', align = "right", width='230px'))),
  sidebarLayout(
    conditionalPanel(condition="1==1",
      sidebarPanel(
      checkboxGroupInput("bandwidths", 
                    h2("Select Circuit Sizes"),
                    choices = c(50,100,500,1000,10000),
                    selected = c(50,100,500,1000,10000)),
      selectInput("dataset",
                  h2("Select Dataset"),
                  choices = c('All', 'Clean', 'Dirty'), selected = "All"),
      selectInput("purpose", 
                  h2("Select Purpose"),
                  choices = c('All', 'Internet', 'Upstream', 'WAN', 'ISP Only')),
      selectInput("connection", 
                  h2("Select Connection Type"),
                  choices = c("All", "Fiber", "Dark Fiber", "Copper", "Cable / DSL", "Fixed Wireless", "Other / Uncategorized")),
      selectInput("locale", 
                  h2("Select District Locale"), 
                  choices = c('All', 'Rural', 'Small Town', 'Suburban', 'Urban'), selected="All"),
      selectInput("size", 
                  h2("Select District Size"), 
                  choices = c('All', 'Tiny', 'Small', 'Medium', 'Large', 'Mega'), selected="All"),
      selectInput("state", 
                  h2("Select State"), 
                  choices = c('All', 'AK','AL','AR','AZ',
                              'CA','CO','CT','DC',
                              'DE','FL','GA','HI','IA',
                              'ID','IL','IN','KS',
                              'KY','LA','MA','MD',
                              'ME','MI','MN','MO',
                              'MS','MT','NC','ND',
                              'NE','NH','NJ','NM',
                              'NV','NY','OH','OK',
                              'OR','PA','RI','SC',
                              'SD','TN','TX','UT','VA',
                              'WA','WI','WV','WY'), selected="All"),
      selectInput("goals",
                  h2("Select Goal Status"), 
                  choices = c('2014 Goals', '2018 Goals'),
                  selected = '2014 Goals'),
      width=3
    )),
    mainPanel(
      tabsetPanel(
        tabPanel("About", div(p(br(), "For Internal Use Only By EducationSuperHighway.",br(),br() 
                                              )), 
                 width="300px"),
        tabPanel("Cost - Box and Whiskers", imageOutput("distPlot", height="550px", width="1000px"),
                 div(id="test1", class="test", textOutput("n_observations"))),
        tabPanel("Cost - Histogram", plotOutput("histPlot", height="550px", width="1000px")),
        tabPanel("Cost - National Comparison", plotOutput("natComparison", height="550px", width="1000px")),
        tabPanel("Bandwidth Projection", plotOutput("bwProjection", height="550px", width="1000px")),
        tabPanel("District Map", fluidRow(column(12, align = "center", plotOutput("gen_map", height="550px", width = "1000px")))),
      id="condition_panel"
  )
)
)))