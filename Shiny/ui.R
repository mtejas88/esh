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
                    background-color: #FFFCF5;
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
                    color: #F26B23;
                    display: inline-block;
                    margin-top: 0px;
                    }
                    
                    img {
                    font-family: 'Roboto Slab';
                    font-weight: 500;
                    line-height: 1.1;
                    color: #F26B23;
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
                    font-weight: 600;
                    line-height: 1.1;
                    font-size: 12pt;
                    color: #899DA4;
                    
                    }

                    h4 {
                    background-color: #FFFCF5;
                    font-family: 'Lato', sans-serif;
                    font-weight: 500;
                    line-height: 1.1;
                    font-size: 16pt;
                    display: inline-block;
                    margin-top: 0px;

                    }
                    
                    .well {
                    background-color: #FFFCF5;
                    }
                    
                    .irs-bar {
                    background-color: #F26B23;
                    }
                    
                    .irs-from {
                    background-color: #F26B23;
                    }
                    
                    .irs-to {
                    background-color: #F26B23;
                    }
                    
                    a {
                    color: #F26B23;
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
                    top: 125px;
                    left: 0;
                    right: 0;
                    bottom: 0;

                    }
                    
                    div.manualmainpanel{
                    position: auto;
                    top: 90px;

                    }
                    
                    div.horizontalformatting1{
                    float: right;
                    right:  0;
                    bottom: 0;

                    }

                    div.horizontalformatting2{
                    float: right;
                    right: 0;
                    bottom:0;
  
                    }
                    
                    #controls {
                    /* Fade out while not hovering */
                    margin: auto;
                    padding: 20px;
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

  
  
  div(class = 'horizontalformatting2', #style = 'display:inline-block',  #; horizontal-align: text-top;' 
      selectInput("dataset",
                  h2("Select Data Cleanliness"),
                  choices = c('All', 'Clean'), selected = 'All', width='200px')), 

#end selectInput() and div()
div(class = 'horizontalformatting1', #style='display:inline-block', #vertical-align: text-top;',           
    selectInput("state", h2("Select State"),
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
                            'WA','WI','WV','WY'), selected='All', width='200px')), #end selectInput() and div()
  
  
titlePanel(div(h1("Warchild"))),

   #mainPanel(width = 12,
      ##navbarPage("",
  
  div(class = "manualmainpanel",
                tabsetPanel(
                  id="panels",
                 
                tabPanel("About", 
                          
                          fluidRow(
                          column(12,
                                 includeHTML("html/intro.html")
                          )
                          
                          ) # close fluid row
                          
                          ),
                
                 
                 navbarMenu("Demographics",
                            tabPanel("Demographics Breakdown", br(),
                                     
                            wellPanel(
                                      fluidRow(
                                        column(12, align = "left", h4("All vs. CLEAN: DISTRIBUTION BY DISTRICT LOCALE"), br(), 
                                              p("This chart shows the distribution of districts in clean and all data, by their locale
                                              classification according to NCES.")), br(),
                                        column(12, align = "center", plotOutput("histogram_locale", width = "50%")), br(), br(), 
                                              dataTableOutput("table_locale"), br(), br())  #close fluidRow
                                      ), # close wellPanel
                            wellPanel(
                                      fluidRow(
                                      column(12, align = "left", h4("All VS CLEAN: DISTRIBUTION BY DISTRICT SIZE"), br(), 
                                            p("This chart shows the distribution of districts in clean and all data, by their size 
                                               classification based on number of schools in the district. The definitions are as 
                                               follows: Tiny(1 school); Small(2-5 schools); Medium(6-15 schools); 
                                               Large(16-50 schools); Mega(51+ schools).")), br(),
                                      column(12, align = "center", plotOutput("histogram_size", width = "50%")), br(), br(), 
                                      dataTableOutput("table_size"))#fluidRow
                                      ) #close wellPanel
                            )# close tabPanel
                            ), # close navbarMenu

                 navbarMenu("Goals",
                            tabPanel("Goals Breakdown", br(), #htmlOutput("helptext_goals"), br(), br(), 
                                     sidebarLayout(
                                       sidebarPanel(width = 3,
                                       div(id = "goals_filters", 
                                           h2(strong("Any filters and selections applied will affect all charts on this tab.")),
                                         checkboxGroupInput(inputId = "connection_districts_goals", 
                                                            h2("Select Highest IA Connection Type(s) for Districts"),
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
                                                            label = h2("Select District Locale(s)"),
                                                            choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                            selected = c("Rural", "Small Town", "Suburban", "Urban"))),
                                         actionButton("goals_reset_all", "Reset All Filters")#
                                         ),
                                  mainPanel(
                                     h4("PERCENT OF DISTRICTS/STUDENTS MEETING THE 2014 FCC INTERNET ACCESS GOAL"), br(), 
                                     p("A district is meeting the 2014 FCC goal if its total bandwidth is greater than or equal to 100 kbps per student. 
                                       Percentage of students meeting goals represents the percentage of students in the districts meeting the 2014 goal."), br(),
                                     plotOutput("histogram_goals"), br(), dataTableOutput("table_goals"), br(), br(), br(),
                                     
                                     h4("PERCENT OF DISTRICTS, BROKEN OUT BY HIGHEST INTERNET ACCESS TECHNOLOGY"), br(), 
                                         p("This chart shows the percentage of 2014 goal meeting districts, broken out by the highest internet
                                            access technology in each district. (e.g. if the district has 1 fiber line and 1 DSL line, the district would be 
                                            accounted for in the fiber category)."), 
                                         p("Unknown/Error will only apply districts that do not have clean data."), br(),
                                          checkboxInput("district_filters", "Choose 2014 Goal Meeting Status"),
                                          h2(strong("Note: this filter only affects this chart.")),
                                          conditionalPanel(condition = "input.district_filters == true",
                                                           checkboxGroupInput(inputId = "meeting_goal", 
                                                                              h2("Select whether District is Meeting the 2014 FCC Goal"),
                                                                              choices = c("Meeting Goal", "Not Meeting Goal"), 
                                                                              selected = c("Meeting Goal", "Not Meeting Goal"))), br(),
                                          downloadButton('ia_tech_downloadData', 'Download'), br(),
                                          plotOutput("histogram_districts_ia_technology"), br(), br(), dataTableOutput("table_districts_ia_technology"), br(), br(), br(),
                                     h4("PERCENTAGE OF SCHOOLS CURRENTLY MEETING WAN GOAL AND SCHOOLS THAT NEED TO BE MEETING WAN GOAL"), br(),
                                        p("Percentage of schools currently meeting WAN goal is represented by the percentage of WAN connections that are at least 1 gbps. 
                                          Percentage of schools that should be meeting WAN goal is estimated by the percentage of schools that have more than 100 students in 
                                          school districts that have at least three schools."), 
                                        p("As of 6/22/16, estimates for WAN needs may not be available for some states. Please reach out to the Analysis Team for the estimate, if needed.."), br(),
                                        plotOutput("histogram_projected_wan_needs"), br(), 
                                        dataTableOutput("table_projected_wan_needs"), br(), br(), br(),
                                     h4("Districts Not Meeting vs. Meeting Goals: Median Cost per Mbps"), br(),
                                        fluidRow(
                                           column(12, plotOutput("hypothetical_ia_price")),
                                           column(12, plotOutput("hypothetical_ia_goal"))
                                        ), br(), dataTableOutput("table_hypothetical_ia_goal"), br(), br()))#close mainPanel and sidebarLayout
                                     
                                     )),

                 navbarMenu("Fiber",
                            tabPanel("Fiber Breakdown", br(), #htmlOutput("helptext_schools_on_fiber"), br(), br(), 
                                     sidebarLayout( sidebarPanel(width = 3,
                                                div(id = "fiber_filters", 
                                                    h2(strong("Any filters and selections applied will affect all charts on this tab.")),
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
                                        h4("DISTRIBUTION OF SCHOOLS BY INFRASTRUCTURE TYPE"), br(), 
                                        p("PLACEHOLDER"), br(),
                                            plotOutput("histogram_schools_on_fiber"), br(), 
                                            dataTableOutput("table_schools_on_fiber"), br(), br(), br(),
                                        h4("DISTRIBUTION OF UNSCALABLE SCHOOLS BY DISTRICT E-RATE DISCOUNT RATES"), br(), 
                                        p("PLACEHOLDER"), br(),
                                            plotOutput("histogram_by_erate_discounts"), br(), dataTableOutput("table_by_erate_discounts"))
                                         
                                    
                                    ))),
                 
                 navbarMenu("Affordability",
                            tabPanel("Affordability Breakdown", br(), #htmlOutput("helptext_price_cpc"), br(), 
                                  sidebarLayout( sidebarPanel(width = 3,
                                                              h2(strong("Please select circuit size(s) below. 
                                                                        Any filters and selections applied will affect all charts on this tab.")),
                                  div(id = "affordability_filters", 
                                        uiOutput("bandwidthSelect"), 
                                       
                                        
                                        checkboxGroupInput(inputId = "purpose", 
                                                        label = h2("Select Purpose(s)"),
                                                        choices = c('Internet', 'Upstream', 'WAN', 'ISP Only'),
                                                        selected = c('Internet', 'Upstream', 'WAN', 'ISP Only')),
                                        
                                        checkboxGroupInput(inputId = "connection_services", 
                                                        h2("Select Connection Type(s)"),
                                                        choices = c("Dark Fiber", "Lit Fiber", "Fixed Wireless",
                                                                    "Cable", "DSL", "Copper", "Other / Uncategorized"),
                                                        selected = c("Dark Fiber", "Lit Fiber", "Fixed Wireless",
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
                                     h4("DISTRIBUTION OF MONTHLY COST PER CIRCUIT"), br(), 
                                     p("This chart shows the 25th percentile, median, and 75th percentile of monthly cost per circuit
                                       for selected services."), br(), 
                                     plotOutput("cpc_sidebars", width = '800px', height = '500px'), br(),
                                     dataTableOutput("disp_cpc_table"), br(), br(),
                                     h4("DISTRIBUTION OF MONTHLY COST PER MBPS"), br(), 
                                     p("This chart shows the 25th percentile, median, and 75th percentile of monthly cost per mbps
                                       for selected services."), br(), 
                                     plotOutput("price_disp_cpm_sidebars", width = '800px', height = '500px'), br(), dataTableOutput("disp_cpm_table"), br(), br(), 
                                     h4("SCATTERPLOT OF MONTHLY COST PER CIRCUIT"), br(), 
                                     p("This vertical scatterplot shows the entire distribution of monthly cost per circuit for selected services
                                       at different circuit sizes."), br(), 
                                     ggvisOutput("plot1"), br(), 
                                     div(dataTableOutput("plot1_table"), style = "font-size:60%"), br(), br() 
                            ##tabPanel("Histogram: Monthly Cost Per Mbps", htmlOutput("helptext_price_cpm"), align = "left", ggvisOutput("price_disp_cpm"), align = "center"),
                            ##tabPanel("Scatterplot: Monthly Cost Per Circuit", htmlOutput("helptext_price_cpm_scatter"), align = "left", ggvisOutput("plot1"), align = "center")
                             #tabPanel("Histogram: Median Cost per Circuit by State", plotOutput("histogram_cost_comparison_by_state"), tableOutput("table_cost_comparison_by_state"))#,
                            #tabPanel("Current vs. Ideal Pricing: % Districts Meeting Goals", plotOutput("histogram_hypothetical_ia_goal"), tableOutput("table_hypothetical_ia_goal"), tableOutput("table_hypothetical_median_cost2"))
                            #tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            #tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            
                                     ))
                            )),#),
                 navbarMenu("Maps",
                            tabPanel("District Lookup", br(),#htmlOutput("helptext_leaflet_map"), br(), br(),
                                    tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
                                    
                                   # div(class = "outer",
                                    
                                    div(class = "outer", leafletOutput("testing_leaflet", width = '100%', height = '100%')), 
                                     br(),
                                     #verbatimTextOutput("selected"),
                                     absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                                 draggable = TRUE, top = 125, left = "auto", right = 20, bottom = "auto",
                                                 width = 330, height = "auto",
                                                 
                                                 uiOutput("districtSelect"))#,

                                     #actionButton("districtSelect", "New Points"))
                                     
                                     ),#), #end of tabPanel() and div()
                         
                           tabPanel("Maps", br(),  
                           sidebarLayout(
                                    sidebarPanel(width = 3,
                                    div(id = "map_filters", 
                                        h2(strong("Any filters and selections applied will affect all charts on this tab.")),
                                      selectInput(inputId = "map_view", 
                                                 label = h2("Choose Map View:"),
                                                 choices = c("All Districts", "Clean/Dirty Districts", 
                                                             "Goals: 100kbps/Student", "Goals: 1Mbps/Student",
                                                             "Fiber Build Cost to Districts"),
                                                 selected = "All Districts"),
                                      
            
                                      checkboxGroupInput(inputId = "connection_districts", 
                                                        h2("Select Connection Type(s) - map/district view only"),
                                                        choices = c("Fiber", "Cable", "DSL",
                                                                    "Fixed Wireless", "Copper", "Other / Uncategorized"), 
                                                        selected = c("Fiber", "Cable", "DSL", "Fixed Wireless",
                                                                     "Copper", "Other / Uncategorized")), 
                                      checkboxGroupInput(inputId = "district_size_maps", 
                                                         label = h2("Select District Size(s)"),
                                                         choices = c("Tiny", "Small", "Medium", "Large", "Mega"),
                                                         selected = c("Tiny", "Small", "Medium", "Large", "Mega")),#),
                                      checkboxGroupInput(inputId = "locale_maps", 
                                                         label = h2("Select District Locale(s)"),
                                                         choices = c("Rural", "Small Town", "Suburban", "Urban"),
                                                         selected = c("Rural", "Small Town", "Suburban", "Urban"))),
                                                 actionButton("map_reset_all", "Reset All Filters"),#
                                                 downloadButton('downloadData', 'Download')), #'map_downloadData'
                                     mainPanel(
                                     htmlOutput("text_maps"), br(),
                                     plotOutput("map_population"), align = "center", textOutput("n_ddt"), align = "center", br(), br(),
                                     div(dataTableOutput("table_testing"), style = "font-size:60%"), br(), br())#,  map_tables
                                     #wellPanel("Clean/Dirty Districts", br(), plotOutput("map_cleanliness"), textOutput("n_ddt2")),
                                     #wellPanel("Districts Meeting 2014 IA Goal (no oversub)", br(), plotOutput("map_2014_goals"), textOutput("n_ddt3")),
                                     #wellPanel("Districts Meeting 2018 IA Goal (w/ oversub)", br(), plotOutput("map_2018_goals"), textOutput("n_ddt4")),
                                     #wellPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")))
                                     )))
                           

                 
                # tabPanel("View Underlying Data", p(), 
                #            fluidPage(
                #                  wellPanel(tags$style(type="text/css", '#leftPanel { width:300px; float:left;}'),
                #                            id = "leftPanel",
                #                            selectInput(inputId = "download_dataset", 
                #                                            label = h2("Choose a dataset:"),
                #                                            choices = c("districts_table", 
                #                                                        "line_items_table")),
                #                  downloadButton('downloadData', 'Download'))), h3(tableOutput("table")))
                 
                )) #closing tabsetPanel() and div()

  
  



  
  )) #closing fluidPage() and shinyUI()
