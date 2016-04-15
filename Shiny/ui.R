
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
                    margin-left: 150px;
                    text-align: left;
                    color: #899DA4;
                    white-space: pre
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
  
  titlePanel(div(h1("SHINY for Connectivity Reports"))),
  
  sidebarLayout(
    sidebarPanel(
      #helpText("Making Shiny more efficient with reactive datasets"),
      
    
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
      
      uiOutput("districtSelect"),
      
      selectInput("dataset",
                  h2("Select Dataset (applicable for Maps only)"),
                  choices = c('All', 'Clean'), selected = 'All'),
      checkboxGroupInput(inputId = "bandwidths", 
                         label = h2("Select Circuit Size(s) (applicable for B-W viz only)"),
                         choices = c("50Mbps" = 50, "100Mbps" = 100, "500Mbps" = 500, 
                                     "1Gbps" = 1000, "10Gbps" = 10000),
                         selected = c(50, 100, 500, 1000, 10000)),

      checkboxGroupInput(inputId = "purpose", 
                         label = h2("Select Purpose(s) (applicable for B-W viz only)"),
                         choices = c('Internet', 'Upstream', 'WAN', 'ISP Only'),
                         selected = c('Internet', 'Upstream', 'WAN', 'ISP Only')),
     checkboxGroupInput(inputId = "connection_districts", 
                       h2("Select Connection Type(s) - map/district view only"),
                       choices = c("Fiber", "Cable", "DSL",
                                   "Fixed Wireless", "Copper", "Other / Uncategorized"), 
                       selected = c("Fiber", "Cable", "DSL", "Fixed Wireless",
                                    "Copper", "Other / Uncategorized")), 
     checkboxGroupInput(inputId = "connection_services", 
                       h2("Select Connection Type(s) - line item view only"),
                       choices = c("Dark Fiber", "Lit Fiber",
                                   "Cable", "DSL", "Copper", "Other / Uncategorized"),
                       selected = c("Dark Fiber", "Lit Fiber",
                                    "Cable", "DSL", "Copper", "Other / Uncategorized")), 
      checkboxGroupInput(inputId = "district_size", 
                         label = h2("Select District Size(s)"),
                         choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                         selected = c("Tiny", "Small", "Medium", "Large", "Mega")),
      
      checkboxGroupInput(inputId = "locale", 
                         label = h2("Select Locale(s)"),
                         choices = c("Rural", "Small Town", "Suburban", "Urban"),
                         selected = c("Rural", "Small Town", "Suburban", "Urban"))

      
    ),#closing sidebarPanel
    
    
    
    mainPanel(
      navbarPage("",
                 tabPanel("About", div(p(br(), "For Internal Use Only By EducationSuperHighway.",br(), "Last Pull Date: 04/14/16", br())), width="300px"),
                 navbarMenu("Cost",
                            tabPanel("Cost: Frequency of Bandwidths by Line Item", plotOutput("plot")),
                            tabPanel("Cost: Monthly Cost Per Circuit", plotOutput("bw_plot"), tableOutput("counts_table"), tableOutput("prices_table")),
                            tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            #,
                            #tabPanel("Cost: Monthly Cost Per Mbps", plotOutput("hist"))
                            ),
                 navbarMenu("Maps", 
                            tabPanel("Your Selected Districts Map", plotOutput("choose_district")),
                            tabPanel("Gen. Population Map", plotOutput("pop_map"), textOutput("n_ddt")),
                            tabPanel("Clean/Dirty Map", plotOutput("gen_map"), textOutput("n_ddt2")),
                            tabPanel("100k Goal Map (no oversub)", plotOutput("goals100k_map"), textOutput("n_ddt3")),
                            tabPanel("1Mbps Goal Map (w/ oversub)", plotOutput("goals1M_map"), textOutput("n_ddt4")),
                            tabPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")),
                            tabPanel("testing", plotOutput("map_price_dispersion"))), #closing navbarMenu
                 tabPanel("View Underlying Data", h3(tableOutput("table")))
      ) #closing navbarPage
    ) #closing mainPanel"
  ) #closing sidebarLayout
    )) #closing shinyUI and fluidPage