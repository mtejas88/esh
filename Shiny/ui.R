library(leaflet)

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
                 tabPanel("About", div(p(br(), "For Internal Use Only By EducationSuperHighway.",br(), "Last Data Pull Date: 04/04/16", br())), width="300px"),
                 navbarMenu("ESH Sample",
                            tabPanel("Sample vs. Population: Locale", plotOutput("histogram_locale"), tableOutput("table_locale")),
                            tabPanel("Sample vs. Population: District Size", plotOutput("histogram_size"), tableOutput("table_size"))),
                 navbarMenu("Goals",
                            tabPanel("Districts / Students Meeting IA Goals", plotOutput("histogram_goals"), tableOutput("table_goals")),
                            tabPanel("Districts Meeting Goals, by IA Technology", plotOutput("histogram_meeting_goals_ia"), tableOutput("table_meeting_goals_ia")),
                            tabPanel("Districts Not Meeting Goals, by IA Technology", plotOutput("histogram_not_meeting_goals_ia"), tableOutput("table_not_meeting_goals_ia")),
                            tabPanel("Current WAN Goal Percentage vs. Projected WAN Needs", plotOutput("histogram_projected_wan_needs"), tableOutput("table_projected_wan_needs"))),
                 navbarMenu("Fiber",
                            tabPanel("Distribution of Schools by Infrastructure Type", plotOutput("histogram_schools_on_fiber"), tableOutput("table_schools_on_fiber")),
                            tabPanel("Distribution of Schools by E-Rate Discount Rates", plotOutput("histogram_by_erate_discounts"), tableOutput("table_by_erate_discounts"))),
                 navbarMenu("Affordability",
                            #tabPanel("Frequency of Bandwidths by Line Item", plotOutput("plot")),
                            tabPanel("Monthly Cost Per Circuit", plotOutput("bw_plot"), tableOutput("counts_table"), tableOutput("prices_table")),
                            tabPanel("State-by-State Comparison: Median Cost per Circuit", plotOutput("histogram_cost_comparison_by_state"), tableOutput("table_cost_comparison_by_state")),
                            tabPanel("Districts Not Meeting vs. Meeting Goals: Median Cost per Mbps", plotOutput("histogram_hypothetical_median_cost"), tableOutput("table_hypothetical_median_cost")),
                            tabPanel("Current vs. Ideal Pricing: % Districts Meeting Goals", plotOutput("histogram_hypothetical_ia_goal"), tableOutput("table_hypothetical_ia_goal"), tableOutput("table_hypothetical_median_cost2"))
                            #tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            #tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            #,
                            #tabPanel("Cost: Monthly Cost Per Mbps", plotOutput("hist"))
                            ),
                 navbarMenu("Maps", 
                            tabPanel("Your Selected Districts Map", plotOutput("choose_district")),
                            tabPanel("Districts in Population", plotOutput("map_population"), textOutput("n_ddt")),
                            tabPanel("Clean/Dirty Districts", plotOutput("map_cleanliness"), textOutput("n_ddt2")),
                            tabPanel("Districts Meeting 2014 IA Goal (no oversub)", plotOutput("map_2014_goals"), textOutput("n_ddt3")),
                            tabPanel("Districts Meeting 2018 IA Goal (w/ oversub)", plotOutput("map_2018_goals"), textOutput("n_ddt4")),
                            tabPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")),
                            tabPanel("Price Dispersion: Automatic, in development", plotOutput("map_price_dispersion_automatic")), 
                            tabPanel("Price Dispersion: Lit Fiber IA - 100 mbps", plotOutput("map_price_dispersion_litfiber_ia_100mbps")),
                            tabPanel("District Lookup", leafletOutput("testing_leaflet"), p(), actionButton("districtSelect", "New points"))), #closing navbarMenu
                 tabPanel("View Underlying Data", h3(tableOutput("table")))
      ) #closing navbarPage
    ) #closing mainPanel"
  ) #closing sidebarLayout
    )) #closing shinyUI and fluidPage