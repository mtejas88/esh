library(leaflet)
library(ggvis)
library(shinydashboard)
library(DT) #for datatables
library(shinyjs) #for reset button
library(mapview)


shinyUI(fluidPage(
  useShinyjs(),
  
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
                    
                    
                    h2 {
                    font-family: 'Lato', sans-serif;
                    font-weight: 300;
                    line-height: 1.1;
                    font-size: 12pt;
                    color: #899DA4;
                    }
                    
                    h3 {
                    font-family: 'Lato', sans-serif;
                    font-weight: 600;
                    line-height: 1.1;
                    font-size: 12pt;
                    color: #899DA4;
                    
                    }

                    h4 {
                    background-color: #FFFFFF;
                    font-family: 'Lato', sans-serif;
                    font-weight: 500;
                    line-height: 1.1;
                    font-size: 16pt;
                    display: inline-block;
                    margin-top: 0px;

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


                   input[type=number] {
                     max-width: 80%;
                    }
                    
                    div.outer {
                    position: fixed;
                    top: 120px;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    overflow: hidden;
                    padding: 0;
                    }
                    

                    div.horizontalformatting{
                    display: inline-block; 
                    vertical-align: text-top;
                    }

                                        
                    #controls {
                    /* Fade out while not hovering */
                    opacity: 0.65;
                    zoom: 0.9;
                    transition: opacity 500ms 1s;
                    }

                    #controls:hover {
                    /* Fade in while hovering */
                    opacity: 0.95;
                    transition-delay: 0;
                    }
                    
                    

                        
                    "))
    ),


  
  titlePanel(h1("SHINY for EducationSuperHighway")),#close title panel
                #tabsetPanel(
                #  id="panels",
                 
                #tabPanel("About", 
                          
                          #fluidRow(

  
  
  tabsetPanel(
    id="panels",
    
                tabPanel("About", 
                         #div(class = "horizontalformatting",
                             selectInput("state", 
                                         h3("Select State"),
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
                                                     'WA','WI','WV','WY'), selected='All', width = '200px'),#)),
                         
                         #absolutePanel(fixed = TRUE, #class = "panel panel-default", 
                         #                                          draggable = TRUE, top = 0, left = "auto", right = 10, bottom = "auto",
                         #                                          width = "auto", height = "auto",                              
                         #tags$div(class="span8",
                         #div(style = "display: inline-block; vertical-align: text-top;",
                         #div(class = "horizontalformatting",
                             selectInput("dataset",
                                         h3("Select Data Cleanliness"),
                                         choices = c('All', 'Clean'), selected = 'All', width = '200px'),
                         
                         
                          column(12,
                                 h2("Before you toggle over to the other tabs, please select your state of interest and data cleanliness."),  br(),
                                 includeHTML("include.html")
                          )
                          
                          #) # close fluid row
                          
                          ),
                
                 
                 navbarMenu("ESH Data",
                            tabPanel("Overview of ESH Data Composition", 
                                     
                            wellPanel(h4("All vs. Clean: Locale"), br(), plotOutput("histogram_locale", width = "50%"), align = "center", br(), br(), dataTableOutput("table_locale")), br(), br(),
                            wellPanel(h4("All vs. Clean: District Size"), br(), plotOutput("histogram_size", width = "50%"), align = "center", br(), br(), dataTableOutput("table_size")))),

                 navbarMenu("Goals",
                            tabPanel("Goals Breakdown", br(), htmlOutput("helptext_goals"), br(), br(), 
                                     sidebarLayout(
                                       sidebarPanel(width = 3, 
                                       div(id = "goals_filters", 
                                         checkboxGroupInput(inputId = "connection_districts_goals", 
                                                            h2("Select Connection Type(s)"),
                                                            choices = c("Fiber", "Cable", "DSL",
                                                                        "Fixed Wireless", "Copper", "Other / Uncategorized"), 
                                                            selected = c("Fiber", "Cable", "DSL", "Fixed Wireless",
                                                                         "Copper", "Other / Uncategorized")), 
                                         #checkboxInput("district_size2", "Select District Size"),
                                         #conditionalPanel(condition = "input.district_size2 == true",
                                         checkboxGroupInput(inputId = "district_size_goals", 
                                                            label = h2("Select District Size(s)"),
                                                            choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                            selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                         
                                         #checkboxInput("district_locale", "Select District Locale"),
                                         #conditionalPanel(condition = "input.district_locale == true",
                                         checkboxGroupInput(inputId = "locale_goals", 
                                                            label = h2("Select Locale(s)"),
                                                            choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                            selected = c("Rural", "Small Town", "Suburban", "Urban"))),
                                         actionButton("goals_reset_all", "Reset All Filters")#
                                         ),
                                  mainPanel(
                                     h4("Districts / Students Meeting IA Goals"), br(), plotOutput("histogram_goals"), br(), dataTableOutput("table_goals"), br(), br(), br(),
                                     h4("Districts by IA Technology"), br(), 

                                               checkboxInput("district_filters", "Filter for Meeting Goals Status"),
                                               conditionalPanel(condition = "input.district_filters == true",
                                                                
                                                                checkboxGroupInput(inputId = "meeting_goals", 
                                                                                   h2("Select whether District is Meeting 2014 Goals"),
                                                                                   choices = c("Meeting 2014 Goals", "Not Meeting 2014 Goals"), 
                                                                                   selected = c("Meeting 2014 Goals", "Not Meeting 2014 Goals"))), br(),
                                               downloadButton('ia_tech_downloadData', 'Download'), br(),
                                               
                                               plotOutput("histogram_districts_ia_technology"), br(), dataTableOutput("table_districts_ia_technology"), br(), br(), br(),
                                     h4("Current WAN Goal Percentage vs. Projected WAN Needs"), br(), plotOutput("histogram_projected_wan_needs"), br(), dataTableOutput("table_projected_wan_needs"), br(), br(), br(),
                                     h4("Districts Not Meeting vs. Meeting Goals: Median Cost per Mbps"), br(),
                                     fluidRow(
                                       column(12, plotOutput("hypothetical_ia_price")),
                                       column(12, plotOutput("hypothetical_ia_goal"))
                                     ), br(), dataTableOutput("table_hypothetical_ia_goal"), br(), br()))#close mainPanel and sidebarLayout
                                     
                                     )),

                 navbarMenu("Fiber",
                            tabPanel("Fiber Charts", br(), htmlOutput("helptext_schools_on_fiber"), br(), br(), 
                                    
                                     
                                     sidebarLayout( sidebarPanel(width = 3,
                                                div(id = "fiber_filters", 
                                                #checkboxInput("district_size2", "Select District Size"),
                                                #conditionalPanel(condition = "input.district_size2 == true",
                                                                 checkboxGroupInput(inputId = "district_size_fiber", 
                                                                                    label = h2("Select District Size(s)"),
                                                                                    choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                                                    selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                                
                                                #checkboxInput("district_locale", "Select District Locale"),
                                                #conditionalPanel(condition = "input.district_locale == true",
                                                                 checkboxGroupInput(inputId = "locale_fiber", 
                                                                                    label = h2("Select Locale(s)"),
                                                                                    choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                                                    selected = c("Rural", "Small Town", "Suburban", "Urban")),#,
                                                actionButton("fiber_reset_all", "Reset All Filters")
                                       )),
                                       
                                     
                                     
                                    mainPanel( 
                                    h4("Distribution of Schools by Infrastructure Type"), br(), plotOutput("histogram_schools_on_fiber"), br(), dataTableOutput("table_schools_on_fiber"), br(), br(), br(),
                                    h4("Distribution of Schools by E-Rate Discount Rates"), br(), plotOutput("histogram_by_erate_discounts"), br(), dataTableOutput("table_by_erate_discounts"))
                                     
                                    
                                    ))),
                 
                 navbarMenu("Affordability",
                          
                            #tabPanel("Box and Whiskers: Monthly Cost Per Circuit", plotOutput("bw_plot"), tableOutput("counts_table"), tableOutput("prices_table")),
                            tabPanel("Bar Charts + Scatterplot: Price Dispersion", br(), htmlOutput("helptext_price_cpc"), br(), align = "left", br() , 
                                     
                                  sidebarLayout( sidebarPanel(width = 3,
                                  div(id = "affordability_filters", 
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
                                                                     "Cable", "DSL", "Copper", "Other / Uncategorized")),
                                        
                                        checkboxGroupInput(inputId = "district_size_affordability", 
                                                           label = h2("Select District Size(s)"),
                                                           choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                           selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                        
                                        #checkboxInput("district_locale", "Select District Locale"),
                                        #conditionalPanel(condition = "input.district_locale == true",
                                        checkboxGroupInput(inputId = "locale_affordability", 
                                                           label = h2("Select Locale(s)"),
                                                           choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                           selected = c("Rural", "Small Town", "Suburban", "Urban"))),#
                                       
                                       actionButton("affordability_reset_all", "Reset All Filters"),  
                                       downloadButton('affordability_downloadData', 'Download')), # closing sidebar panel,
                                     
                                     #splitLayout(cellWidths = c("50%", "50%"), ggvisOutput("price_disp_cpc"), ggvisOutput("price_disp_cpm")),
                                     mainPanel(
                                     h4("Price Dispersion: Monthly Cost per Circuit"), br(), br(), ggvisOutput("price_disp_cpc"), br(), br(), textOutput("n_sr"), br(), textOutput("n_circuits"), br(), dataTableOutput("disp_cpc_table"), br(), br(),
                                     h4("Price Dispersion: Monthly Cost per Mbps"), br(), br(), ggvisOutput("price_disp_cpm"), br(), dataTableOutput("disp_cpm_table"), br(), br(),
                                     h4("Scatterplot: Monthly Cost per Circuit"), br(), br(), ggvisOutput("plot1"), br(), div(dataTableOutput("plot1_table"), style = "font-size:60%"), br(), br() 
                            ##tabPanel("Histogram: Monthly Cost Per Mbps", htmlOutput("helptext_price_cpm"), align = "left", ggvisOutput("price_disp_cpm"), align = "center"),
                            ##tabPanel("Scatterplot: Monthly Cost Per Circuit", htmlOutput("helptext_price_cpm_scatter"), align = "left", ggvisOutput("plot1"), align = "center")
                             #tabPanel("Histogram: Median Cost per Circuit by State", plotOutput("histogram_cost_comparison_by_state"), tableOutput("table_cost_comparison_by_state"))#,
                            #tabPanel("Current vs. Ideal Pricing: % Districts Meeting Goals", plotOutput("histogram_hypothetical_ia_goal"), tableOutput("table_hypothetical_ia_goal"), tableOutput("table_hypothetical_median_cost2"))
                            #tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            #tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            
                                     ))
                            )),#),
                 navbarMenu("Maps", id = "nav",
                           # tabPanel("Your Selected Districts Map", plotOutput("choose_district")),
                            tabPanel("District Lookup", #htmlOutput("helptext_leaflet_map"), br(), br(),
                                    # tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
                                
                                    div(class = "outer",
                                    
                                     leafletOutput("testing_leaflet", width = "100%", height = "100%")
                                     , 
                                     
                                     #verbatimTextOutput("selected"),
                                    absolutePanel(id = "controls", class = "panel panel-default", #fixed = TRUE,
                                                 draggable = TRUE, top = 130, left = "auto", right = 20, bottom = "auto",
                                                 width = 330, height = "auto",
                                                 
                                                 uiOutput("districtSelect"), align = "center")#,

                                     #actionButton("districtSelect", "New Points"))
                                     
                                     )), #end of tabPanel() and div()
                         
                           tabPanel("District Population Maps", br(),  
                           sidebarLayout(
                                    sidebarPanel(width = 3,
                                    div(id = "map_filters", 
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
                                                                     "Copper", "Other / Uncategorized")), 
                                      #checkboxInput("district_size2", "Select District Size"),
                                      #conditionalPanel(condition = "input.district_size2 == true",
                                      checkboxGroupInput(inputId = "district_size_maps", 
                                                         label = h2("Select District Size(s)"),
                                                         choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                         selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                      
                                      #checkboxInput("district_locale", "Select District Locale"),
                                      #conditionalPanel(condition = "input.district_locale == true",
                                      checkboxGroupInput(inputId = "locale_maps", 
                                                         label = h2("Select Locale(s)"),
                                                         choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                         selected = c("Rural", "Small Town", "Suburban", "Urban"))),
                                                 actionButton("map_reset_all", "Reset All Filters"),#
                                                 downloadButton('downloadData', 'Download')), #'map_downloadData'
                                     mainPanel(
                                     
                                     h4("District Maps"), br(), plotOutput("map_population"), align = "center", textOutput("n_ddt"), align = "center", br(), br(),
                                     div(dataTableOutput("table_testing"), style = "font-size:60%"), br(), br())#,  map_tables
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
  
  
  
  
  
  
  #absolutePanel(fixed = TRUE, draggable = FALSE, top = 0, left = "auto", right = 100, bottom = "auto",
  #              width = "auto", height = "auto",
                #column(4,
                #       wellPanel(width = 2,
                #tags$div(class = "row-fluid", 
                #  tags$div(class = "span8",
                #div(style = "display: inline-block;  vertical-align: text-top;",

  
  
  
  
  
  
  
  
  
  
  
  
  
  
                
                
                
  #) #clost absolute panel & fluid row
  
  
  
      #) #closing navbarPage
    #) #closing mainPanel"
  #) #closing sidebarLayout
    )) #closing shinyUI and fluidPage
