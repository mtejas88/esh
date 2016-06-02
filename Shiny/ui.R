library(leaflet)
library(ggvis)
library(shinydashboard)

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
  
  #sidebarLayout(
    #sidebarPanel(width = 3,
      ##helpText("Making Shiny more efficient with reactive datasets"),
      
      
     # selectInput("state", 
     #              h2("Select State"), 
     #             choices = c('All', 'AL','AR','AZ',
    #                          'CA','CO','CT',
    #                          'DE','FL','GA', 'IA',
    #                          'ID','IL','IN','KS',
    #                          'KY','LA','MA','MD',
    #                          'ME','MI','MN','MO',
    #                          'MS','MT','NC','ND',
    #                          'NE','NH','NJ','NM',
    #                          'NV','NY','OH','OK',
    #                          'OR','PA','RI','SC',
     #                         'SD','TN','TX','UT','VA',
    #                          'WA','WI','WV','WY'), selected='All'),
      
      
      #checkboxInput("select_districts", "Select District(s)"),
      #conditionalPanel(
      #  condition = "input.select_districts == true",
      #uiOutput("districtSelect")),
      
      #checkboxInput("sr_filters", "Filters Tailored To Services Received Table Only"),
      #conditionalPanel(
      #  condition = "input.sr_filters == true",
        #uiOutput("bandwidthSelect"),

      #checkboxGroupInput(inputId = "purpose", 
      #                   label = h2("Select Purpose(s) (applicable for B-W viz only)"),
      #                   choices = c('Internet', 'Upstream', 'WAN', 'ISP Only'),
      #                   selected = c('Internet', 'Upstream', 'WAN', 'ISP Only')),
      
      #checkboxGroupInput(inputId = "connection_services", 
      #                   h2("Select Connection Type(s) - line item view only"),
      #                   choices = c("Dark Fiber", "Lit Fiber",
      #                               "Cable", "DSL", "Copper", "Other / Uncategorized"),
      #                   selected = c("Dark Fiber", "Lit Fiber",
      #                               "Cable", "DSL", "Copper", "Other / Uncategorized")),#),

      



    
    #selectInput(inputId = "download_dataset", 
    #            label = h2("Choose a dataset:"),
    #            choices = c("districts_table", 
    #                        "line_items_table"))#,
     
     #downloadButton('downloadData', 'Download')    
    #),#closing sidebarPanel
    
    
    mainPanel(
      #navbarPage("",
                tabsetPanel(
                  id="panels",
                 tabPanel("About", div(p(br(), "For Internal Use Only By EducationSuperHighway.",br(), "Last Data Pull Date: 05/17/16", br())), width="300px", br(),
                          "Before you toggle over to the other tabs, please select your state of interest and data cleanliness!", br(),
                          wellPanel(width = 2,
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
                                    selectInput("dataset",
                                                h2("Select Data Cleanliness"),
                                                choices = c('All', 'Clean'), selected = 'All')#,
                                    
                                    #checkboxInput("district_size2", "Select District Size"),
                                    #conditionalPanel(condition = "input.district_size2 == true",
                                    #                 checkboxGroupInput(inputId = "district_size", 
                                    #                                    label = h2("Select District Size(s)"),
                                    #                                    choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                    #                                    selected = c("Tiny", "Small", "Medium", "Large", "Mega"))),
                                    
                                    #checkboxInput("district_locale", "Select District Locale"),
                                    #conditionalPanel(condition = "input.district_locale == true",
                                    #                 checkboxGroupInput(inputId = "locale", 
                                    #                                    label = h2("Select Locale(s)"),
                                    #                                    choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                    #                                    selected = c("Rural", "Small Town", "Suburban", "Urban")))#
                                    )),
                
                 
                 navbarMenu("ESH Sample",
                            tabPanel("Sample vs. Population Bar Charts", 
                                     
                            wellPanel("Sample vs. Population: Locale", br(), plotOutput("histogram_locale"), br(), br(), dataTableOutput("table_locale")), br(), br(),
                            wellPanel("Sample vs. Population: District Size", br(), plotOutput("histogram_size"), br(), br(), dataTableOutput("table_size")))),

                 navbarMenu("Goals",
                            tabPanel("Goals Breakdown", br(), htmlOutput("helptext_goals"), br(), br(), 

                                     wellPanel("Districts / Students Meeting IA Goals", br(), plotOutput("histogram_goals"), br(), dataTableOutput("table_goals")),
                                     wellPanel("Districts by IA Technology", br(), 

                                               checkboxInput("district_filters", "Filter for Meeting Goals Status"),
                                               conditionalPanel(condition = "input.district_filters == true",
                                                                
                                                                checkboxGroupInput(inputId = "meeting_goals", 
                                                                                   h2("Select whether District is Meeting 2014 Goals"),
                                                                                   choices = c("Meeting 2014 Goals", "Not Meeting 2014 Goals"), 
                                                                                   selected = c("Meeting 2014 Goals", "Not Meeting 2014 Goals"))), br(),
                                               downloadButton('ia_tech_downloadData', 'Download'), br(),
                                               
                                               plotOutput("histogram_districts_ia_technology"), br(), dataTableOutput("table_districts_ia_technology")),
                                     wellPanel("Current WAN Goal Percentage vs. Projected WAN Needs", br(), plotOutput("histogram_projected_wan_needs"), br(), dataTableOutput("table_projected_wan_needs")))),

                 navbarMenu("Fiber",
                            tabPanel("Fiber Charts", br(), htmlOutput("helptext_schools_on_fiber"), br(), br(), 
                                    
                                     
                                     sidebarLayout( sidebarPanel(#tags$style(type="text/css", '#topPanel { width:200px; float:top;}'),
                                       #id = "topPanel",
                                       tags$div(class = "row",
                                                #checkboxInput("district_size2", "Select District Size"),
                                                #conditionalPanel(condition = "input.district_size2 == true",
                                                                 checkboxGroupInput(inputId = "district_size", 
                                                                                    label = h2("Select District Size(s)"),
                                                                                    choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                                                    selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                                
                                                #checkboxInput("district_locale", "Select District Locale"),
                                                #conditionalPanel(condition = "input.district_locale == true",
                                                                 checkboxGroupInput(inputId = "locale", 
                                                                                    label = h2("Select Locale(s)"),
                                                                                    choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                                                    selected = c("Rural", "Small Town", "Suburban", "Urban"))#)
                                       )),
                                     
                                     
                                    mainPanel( 
                                    "Distribution of Schools by Infrastructure Type", br(), plotOutput("histogram_schools_on_fiber"), br(), dataTableOutput("table_schools_on_fiber"), br(), br(), br(),
                                    "Distribution of Schools by E-Rate Discount Rates", br(), plotOutput("histogram_by_erate_discounts"), br(), dataTableOutput("table_by_erate_discounts"))
                                     
                                    
                                    ))),
                 
                 navbarMenu("Affordability",
                          
                            #tabPanel("Box and Whiskers: Monthly Cost Per Circuit", plotOutput("bw_plot"), tableOutput("counts_table"), tableOutput("prices_table")),
                            tabPanel("Bar Charts + Scatterplot: Price Dispersion", br(), htmlOutput("helptext_price_cpc"), br(), align = "left", br() , 
                                     
                                  sidebarLayout( sidebarPanel(#tags$style(type="text/css", '#topPanel { width:300px; float:top;}'),
                                                         #id = "topPanel",
                                       tags$div(class = "row",
                                        uiOutput("bandwidthSelect"), 
                                       
                                        
                                        checkboxGroupInput(inputId = "purpose", 
                                                        label = h2("Select Purpose(s)"),
                                                        choices = c('Internet', 'Upstream', 'WAN', 'ISP Only'),
                                                        selected = c('Internet', 'Upstream', 'WAN', 'ISP Only')),
                                        
                                        checkboxGroupInput(inputId = "connection_services", 
                                                        h2("Select Connection Type(s)"),
                                                        choices = c("Dark Fiber", "Lit Fiber",
                                                                    "Cable", "DSL", "Copper", "Other / Uncategorized"),
                                                        selected = c("Dark Fiber", "Lit Fiber",
                                                                     "Cable", "DSL", "Copper", "Other / Uncategorized"))), br(),
                                       downloadButton('affordability_downloadData', 'Download')),
                                     
                                     #splitLayout(cellWidths = c("50%", "50%"), ggvisOutput("price_disp_cpc"), ggvisOutput("price_disp_cpm")),
                                     mainPanel(
                                       
                                     "Price Dispersion: Monthly Cost per Circuit", br(), br(), ggvisOutput("price_disp_cpc"), br(), dataTableOutput("disp_cpc_table"), br(), br(),
                                     "Price Dispersion: Monthly Cost per Mbps", br(), br(), ggvisOutput("price_disp_cpm"), br(), dataTableOutput("disp_cpm_table"), br(), br(),
                                     "Scatterplot: Monthly Cost per Circuit", br(), br(), ggvisOutput("plot1"), br(), dataTableOutput("plot1_table"), br(), br(), br(), br()))
                            ##tabPanel("Histogram: Monthly Cost Per Mbps", htmlOutput("helptext_price_cpm"), align = "left", ggvisOutput("price_disp_cpm"), align = "center"),
                            ##tabPanel("Scatterplot: Monthly Cost Per Circuit", htmlOutput("helptext_price_cpm_scatter"), align = "left", ggvisOutput("plot1"), align = "center")
                     
                            #tabPanel("Histogram: Median Cost per Circuit by State", plotOutput("histogram_cost_comparison_by_state"), tableOutput("table_cost_comparison_by_state"))#,
                            tabPanel("Districts Not Meeting vs. Meeting Goals: Median Cost per Mbps", fluidRow(
                                                                                                                column(8, plotOutput("hypothetical_ia_price")),
                                                                                                                column(8, plotOutput("hypothetical_ia_goal"))
                                                                                                              ), tableOutput("table_hypothetical_ia_goal"))
                            #tabPanel("Current vs. Ideal Pricing: % Districts Meeting Goals", plotOutput("histogram_hypothetical_ia_goal"), tableOutput("table_hypothetical_ia_goal"), tableOutput("table_hypothetical_median_cost2"))
                            #tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            #tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            #,
                            #tabPanel("Cost: Monthly Cost Per Mbps", plotOutput("hist"))
                            )),#),
                 navbarMenu("Maps", 
                           # tabPanel("Your Selected Districts Map", plotOutput("choose_district")),
                            tabPanel("District Lookup", br(), htmlOutput("helptext_leaflet_map"), br(), br(),
                                     sidebarLayout(
                                        sidebarPanel( uiOutput("districtSelect")),
                                     mainPanel(leafletOutput("testing_leaflet"))
                                     #fluidRow(wellPanel(#tags$style(type="text/css", '#topPanel { width:300px; float:top;}'),
                                       #id = "topPanel",
                                       #))#,
                                     #br(), br(), p(),
                                     #wellPanel(leafletOutput("testing_leaflet"))
                                     )), #end of sidebarPanel and tabPanel()

                                      #actionButton("districtSelect", "New points")),
                         
                           tabPanel("District Population Maps", br(),  
                           sidebarLayout(
                                    sidebarPanel(
                                      selectInput(inputId = "map_view", 
                                                 label = h2("Choose Map View:"),
                                                 choices = c("General", "Clean/Dirty", 
                                                             "Goals: 100kbps/Student", "Goals: 1Mbps/Student",
                                                             "Fiber Build Cost to Districts"),
                                                 selected = "General"),
                                      checkboxGroupInput(inputId = "connection_districts", 
                                                        h2("Select Connection Type(s) - map/district view only"),
                                                        choices = c("Fiber", "Cable", "DSL",
                                                                    "Fixed Wireless", "Copper", "Other / Uncategorized"), 
                                                        selected = c("Fiber", "Cable", "DSL", "Fixed Wireless",
                                                                     "Copper", "Other / Uncategorized")), br(), br(),
                                                 downloadButton('map_downloadData', 'Download')),
                                     mainPanel(
                                     
                                     "District Maps", br(), plotOutput("map_population"), textOutput("n_ddt"))#,
                                     #wellPanel("Clean/Dirty Districts", br(), plotOutput("map_cleanliness"), textOutput("n_ddt2")),
                                     #wellPanel("Districts Meeting 2014 IA Goal (no oversub)", br(), plotOutput("map_2014_goals"), textOutput("n_ddt3")),
                                     #wellPanel("Districts Meeting 2018 IA Goal (w/ oversub)", br(), plotOutput("map_2018_goals"), textOutput("n_ddt4")),
                                     #wellPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")))
                                     )))
                           
                                    #tabPanel("District Meeting Goals Maps",
                                     #wellPanel("Districts Meeting 2014 IA Goal (no oversub)", br(), plotOutput("map_2014_goals"), textOutput("n_ddt3")),
                                     #wellPanel("Districts Meeting 2018 IA Goal (w/ oversub)", br(), plotOutput("map_2018_goals"), textOutput("n_ddt4"))),
                                     
                                      #tabPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")))#,
                            #tabPanel("Price Dispersion: Automatic, in development", plotOutput("map_price_dispersion_automatic"))), #closing navbarMenu
                 
                # tabPanel("View Underlying Data", p(), 
                #            fluidPage(
                #                  wellPanel(tags$style(type="text/css", '#leftPanel { width:300px; float:left;}'),
                #                            id = "leftPanel",
                #                            selectInput(inputId = "download_dataset", 
                #                                            label = h2("Choose a dataset:"),
                #                                            choices = c("districts_table", 
                #                                                        "line_items_table")),
                #                  downloadButton('downloadData', 'Download'))), h3(tableOutput("table")))
                 
                ) #closing tabsetPanel()
      #) #closing navbarPage
    ) #closing mainPanel"
  #) #closing sidebarLayout
    )) #closing shinyUI and fluidPage
