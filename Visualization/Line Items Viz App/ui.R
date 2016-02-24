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

      h3 {
        font-family: 'Lato', sans-serif;
                    font-weight: 300;
                    line-height: 1.1;
                    font-size: 8pt;
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
  title="SHINY for CRs - EducationSuperHighway",
  titlePanel(div(h1("SHINY for Connectivity Reports"))), #, img(src='esh-logo.png', align = "right", width='230px'))),
  sidebarLayout(
    conditionalPanel(condition="1==1",
      sidebarPanel(
        checkboxGroupInput("bandwidths", 
                    h2("Select Circuit Sizes"),
                    choices = c(50,100,500,1000,10000),
                    selected = c(50,100,500,1000,10000)),
      selectInput("dataset",
                  h2("Select Dataset"),
                  choices = c('All', 'Clean'), selected = 'All'),
      selectInput("purpose", 
                  h2("Select Purpose"),
                  choices = c('All', 'Internet', 'Upstream', 'WAN', 'ISP Only'), selected = 'All'),
      selectInput("connection", 
                  h2("Select Connection Type"),
                  choices = c("All", "Fiber", "Dark Fiber", "Cable", "DSL", "Copper", "Cable / DSL", "Fixed Wireless", "Other / Uncategorized", "None - Error"), selected = 'All'),
      selectInput("locale", 
                  h2("Select District Locale"), 
                  choices = c('All', 'Rural', 'Small Town', 'Suburban', 'Urban'), selected= 'All'),
      selectInput("size", 
                  h2("Select District Size"), 
                  choices = c('All', 'Tiny', 'Small', 'Medium', 'Large', 'Mega'), selected='All'),
      selectInput("state", 
                  h2("Select State"), 
                  choices = c('All', 'AL','AR','AZ',
                              'CA','CO','CT',
                              'DE','FL','GA', 'IA',
                              'ID','IL','IN','KS',
                              'KY','LA','MA','MD',
                              'ME','MI','MN','MO',
                              'MS','MT','NC','ND',
                              'NE','NH','NJ','NM',
                              'NV','NY','OH','OK',
                              'OR','PA','RI','SC',
                              'SD','TN','TX','UT','VA',
                              'WA','WI','WV','WY'), selected='All'),
      conditionalPanel(
        condition = "input.dataset == 'Clean'",
        selectInput("goals",
               h2("Select Goal Status"), 
                  choices = c('All', '2014 Goals', '2018 Goals'),
                  selected = 'All'),
      
      selectInput("percfiber",
                  h2("Select Percentage Fiber"),
                  choices = c('Not applicable', 'No fiber', 'Some fiber', 'All fiber'),
                  selected = 'Not applicable'),
      
      selectInput("subset", h2("Choose a dataset:"),
                  choices = c("Line items", "Deluxe districts")),
                  downloadButton('downloadData', 'Download')),
      width=3
    )),
    mainPanel(
      tabsetPanel(
        navbarPage("STRATEGIC ANALYSIS",
        tabPanel("About", div(p(br(), "For Internal Use Only By EducationSuperHighway.",br(), "Last Pull Date: 02/17/16", br())), width="300px"),
        
        navbarMenu("Cost",
        #tabsetPanel("Cost",
        tabPanel("Cost - Box and Whiskers", imageOutput("distPlot", height="550px", width="1000px"),
                 div(id="test1", class="test", textOutput("n_observations"))),
        tabPanel("Cost - Density Plots", column(12, align = "center", plotOutput("densPlot", height = "500px", width="700px"))),
        #         div(id = "test1", class = "test", textOutput("n_observations"))),
        tabPanel("Cost - Histogram", plotOutput("histPlot", height="550px", width="1000px")),
        tabPanel("Cost - National Comparison", plotOutput("natComparison", height="550px", width="1000px"),
                 div(id="test1", class="test", textOutput("n_observationsComparison")))
        ),
        tabPanel("Bandwidth Projection", plotOutput("bwProjection", height="550px", width="1000px")),
        tabPanel("District Map", fluidRow(column(12, align = "center", plotOutput("gen_map", height="550px", width = "1000px"))),
                 div(id="test1", class="test", textOutput("n_observations_ddt"))),
        tabPanel("Download Subsets", h3(tableOutput('table'))),
      id="condition_panel"
        ) #navbarPage 
      )) #tabsetPanel() & mainPanel()
  ) #sidebarLayout()
))