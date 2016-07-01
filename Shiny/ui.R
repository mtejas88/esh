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
                    background-color: white;
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
                    background-color: white;
                    font-family: 'Lato', sans-serif;
                    font-weight: 500;
                    line-height: 1.1;
                    font-size: 16pt;
                    display: inline-block;
                    margin-top: 0px;

                    }
                    
                    .well {
                    background-color: white;
                    }
                    
                    .irs-bar {
                    background-color: white;
                    }
                    
                    .irs-from {
                    background-color: white;
                    }
                    
                    .irs-to {
                    background-color: white;
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
                    top: 154px;
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
                  choices = c('All', 'Clean'), selected = 'Clean', width='200px')), 
  
  #end selectInput() and div()
  div(class = 'horizontalformatting1', #style='display:inline-block', #vertical-align: text-top;',           
      selectInput("state", h2("Select State"),
                  choices = c('All', 'AL', 'AK', 'AR','AZ',
                              'CA','CO','CT', 'DE',
                              'FL','GA', 'HI','IA',
                              'ID','IL','IN','KS',
                              'KY','LA','MA','MD',
                              'ME','MI','MN','MO',
                              'MS','MT','NC','ND',
                              'NE','NH','NJ','NM',
                              'NV','NY','OH','OK',
                              'OR','PA','RI','SC',
                              'SD','TN','TX','UT','VA',
                              'WA','WI','WV','WY'), selected='All', width='200px')), #end selectInput() and div()  

  
titlePanel(title=div(img(src="ESH_logo.png", width = '25%', height = '10%')), "Warchild"),  #div(h1("Warchild"))

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
                          
                          ), #close tabPanel()
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
                                                  
                                                  uiOutput("districtSelect"),
                                                  selectInput(inputId = "tile",
                                                              label = h2("Choose Map Background"),
                                                              choices = c("Color1" = "MapQuestOpen.OSM",
                                                                          "Color2" = "Esri.WorldStreetMap",
                                                                          "Color3" = "Thunderforest.Transport",
                                                                          "Color4" = "Thunderforest.OpenCycleMap",
                                                                          "Gray1" = "CartoDB.Positron",
                                                                          "Gray2" = "Stamen.TonerLite",
                                                                          "Gray3" = "CartoDB.DarkMatter",
                                                                          "Terrain1" =  "Thunderforest.Landscape",
                                                                          "Terrain2" = "Stamen.TerrainBackground",
                                                                          "Terrain3" = "Esri.WorldImagery",
                                                                          "Cool!" = "NASAGIBS.ViirsEarthAtNight2012"),
                                                              selected = "Gray1")) #
                                    
                                    #actionButton("districtSelect", "New Points"))
                                    
                           ), #end of tabPanel() 
                           
                           tabPanel("Maps", br(),  
                                    sidebarLayout(
                                      sidebarPanel(width = 3,
                                                   div(id = "map_filters", 
                                                       h2(strong("Any filters and selections applied will affect all charts on this tab.")),
                                                       selectInput(inputId = "map_view", 
                                                                   label = h2("Choose Map View:"),
                                                                   choices = c("All Districts", "Clean/Dirty Districts", 
                                                                               "Goals: 100 kbps/Student", "Goals: 1 Mbps/Student",
                                                                               "Fiber Build Cost to Districts"),
                                                                   selected = "All Districts"),
                                                       
                                                       selectInput(inputId = "tile2",
                                                                   label = h2("Choose Map Background:"),
                                                                   choices = c("Color1" = "MapQuestOpen.OSM",
                                                                               "Color2" = "Esri.WorldStreetMap",
                                                                               "Color3" = "Thunderforest.Transport",
                                                                               "Color4" = "Thunderforest.OpenCycleMap",
                                                                               "Gray1" = "CartoDB.Positron",
                                                                               "Gray2" = "Stamen.TonerLite",
                                                                               "Gray3" = "CartoDB.DarkMatter",
                                                                               "Terrain1" =  "Thunderforest.Landscape",
                                                                               "Terrain2" = "Stamen.TerrainBackground",
                                                                               "Terrain3" = "Esri.WorldImagery",
                                                                               "Cool!" = "NASAGIBS.ViirsEarthAtNight2012"),
                                                                   selected = "Gray1"), #
                                                       
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
                                        
                                        
                                        fluidRow(
                                          htmlOutput("text_maps"), br(),  #  column(12, align = "left",   
                                          column(12, splitLayout(cellWidths = c("50%", "50%"), plotOutput("map_population", height = "500px"), 
                                                                 leafletOutput("population_leaflet", height = "500px"), style="width: 125% ; height: 500px",
                                                                 cellArgs = list(style = "padding: 12px")), br(), br(), br(), br()), #end column() 
                                          p(HTML(paste0("Please visit the ", a("IRT", href = "http://irt.educationsuperhighway.org", target = "_blank"), 
                                                        " to see more information  about a particular district."))),
                                          br(), textOutput("n_ddt"), br(), br(),
                                          div(dataTableOutput("table_testing"), style = "height:100px;;font-size:60%"), br(), br())) #end of fluidRow()
                                      
                                      #wellPanel("Clean/Dirty Districts", br(), plotOutput("map_cleanliness"), textOutput("n_ddt2")),
                                      #wellPanel("Districts Meeting 2014 IA Goal (no oversub)", br(), plotOutput("map_2014_goals"), textOutput("n_ddt3")),
                                      #wellPanel("Districts Meeting 2018 IA Goal (w/ oversub)", br(), plotOutput("map_2018_goals"), textOutput("n_ddt4")),
                                      #wellPanel("Fiber Build Costs to Unscalable Districts", plotOutput("map_fiber_needs"), textOutput("n_ddt5")))
                                    )))
                ,
                 
                 #navbarMenu("Demographics",
                            tabPanel("Demographics", br(),
                                     
                            wellPanel(
                                      fluidRow(
                                        column(12, align = "left", h4("DISTRICT LOCALE DISTRIBUTION: ALL VS. CLEAN"), br(), 
                                              p("This chart shows the distribution of districts by their locale
                                              classification according to NCES.")), br(),
                                        column(12, align = "center", plotOutput("histogram_locale", width = "50%")), br(), br(), 
                                              dataTableOutput("table_locale"), br(), br())  #close fluidRow
                                      ), # close wellPanel
                            wellPanel(
                                      fluidRow(
                                      column(12, align = "left", h4("DISTRICT SIZE DISTRIBUTION: ALL VS. CLEAN"), br(), 
                                            p("This chart shows the distribution of districts by their size 
                                               classification based on number of schools in the district. The definitions are as 
                                               follows: Tiny (1 school); Small (2-5 schools); Medium (6-15 schools); 
                                               Large (16-50 schools); Mega (51+ schools).")), br(),
                                      column(12, align = "center", plotOutput("histogram_size", width = "50%")), br(), br(), 
                                      dataTableOutput("table_size"))#fluidRow
                                      ) #close wellPanel
                            #), #was for navbarMenu() which we aren't using anymore
                            ), # close tabPanel

                 #navbarMenu("Goals",
                            tabPanel("Goals", br(), #htmlOutput("helptext_goals"), br(), br(), 
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
                                    wellPanel(
                                     h4("DISTRICTS/STUDENTS MEETING THE 2014 FCC INTERNET ACCESS GOAL"), br(), 
                                     p("A district is meeting the 2014 FCC Goal if its total bandwidth is greater than or equal to 100 kbps per student. 
                                       Percentage of students meeting goals represents the percentage of students in the districts meeting the 2014 goal."), br(),
                                     plotOutput("histogram_goals"), br(), dataTableOutput("table_goals")), br(), br(), br(),
                                     
                                     wellPanel(
                                      h4("DISTRICTS, BROKEN OUT BY HIGHEST INTERNET ACCESS TECHNOLOGY"), br(), 
                                         p("This chart shows the percentage of 2014 goal meeting districts, broken out by the highest internet
                                            access technology in each district. (e.g. if the district has 1 fiber line and 1 DSL line, the district would be 
                                            accounted for in the fiber category)."), 
                                         p("Unknown/Error will only apply districts that do not have clean data."), 
                                          #checkboxInput("district_filters", "Choose 2014 Goal Meeting Status"),
                                          h2(strong("Note: this filter only affects this chart.")),
                                          #conditionalPanel(condition = "input.district_filters == true",
                                                           checkboxGroupInput(inputId = "meeting_goal", 
                                                                              h2("Select whether District is Meeting the 2014 FCC Goal"),
                                                                              choices = c("Meeting Goal", "Not Meeting Goal"), 
                                                                              selected = c("Meeting Goal", "Not Meeting Goal")), br(), #) for ending conditionalPanel()
                                          downloadButton('ia_tech_downloadData', 'Download'), br(),
                                          plotOutput("histogram_districts_ia_technology"), br(), br(), dataTableOutput("table_districts_ia_technology")), br(), br(), br(),
                                     
                                    wellPanel(
                                    h4("SCHOOLS THAT ARE CURRENTLY OR NEED TO BE MEETING THE FCC WAN GOAL"), br(),
                                        p("Percentage of schools currently meeting the FCC WAN Goal is represented by the percentage of WAN connections that are at least 1 Gbps. 
                                          Percentage of schools that should be meeting the FCC WAN Goal is estimated by the percentage of schools that have more than 100 students in 
                                          school districts that have at least three schools."), 
                                        p("Estimates for WAN needs may not be available for some states. Please reach out to Strategic Analysis Team for the estimate, if needed."), br(),
                                        plotOutput("histogram_projected_wan_needs"), br(), 
                                        dataTableOutput("table_projected_wan_needs")), br(), br(), br(),
                                   #     fluidRow(
                                    #       column(12, plotOutput("hypothetical_ia_price")),
                                     #      column(12, plotOutput("hypothetical_ia_goal"))
                                      #  ), br(), dataTableOutput("table_hypothetical_ia_goal"), br(), br(),
                                  
                                    wellPanel(
                                     h4(" HYPOTHETICAL PRICING ANALYSIS: DISTRICTS MEETING THE 2014 FCC GOAL"), br(),
                                     p("This chart compares the percentage of districts currently meeting the 2014 FCC Goal
                                          and the percentage of districts
                                          that would be meeting the goal if districts currently not meeting the goal were to
                                  have access to more affordable internet access."), 
                                     p("You can adjust the IA cost per Mbps assumption by using the scale."), br(),
                                          sliderInput(width = '300px', inputId = "set_price", 
                                                  label = h2("Pricing Assumption: IA Cost per Mbps"), 
                                                  min=0, 
                                                  max=15, 
                                                  value=3,
                                                  step=1),   
                                        br(),
                                        column(12, align = "center", fluidRow(ggvisOutput("hyp_plot")), br(), br()), 
                                        dataTableOutput("table_hyp_cost")), br(), br(), br()
))#close mainPanel and sidebarLayout
                    
                                     ),#),

                 #navbarMenu("Fiber",
                            tabPanel("Fiber", br(), #htmlOutput("helptext_schools_on_fiber"), br(), br(), 
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
                                      
                                      wellPanel(
                                        h4("DISTRIBUTION OF SCHOOLS BY INFRASTRUCTURE TYPE"), br(), 
                                        p("This chart breaks out distribution of schools into the following buckets: Schools that have
                                          associated fiber circuits or in districts assumed to have dark fiber, schools that may have
                                          associated cable, fixed wireless, or other circuits, and schools that only have associated 
                                          copper or DSL circuits."), br(),
                                            plotOutput("histogram_schools_on_fiber"), br(), 
                                            dataTableOutput("table_schools_on_fiber")), br(), br(), br(),
                                      
                                      wellPanel(
                                        h4("DISTRIBUTION OF UNSCALABLE SCHOOLS BY DISTRICT E-RATE DISCOUNT RATES"), br(), 
                                        p("This chart shows the distribution of schools that need or may need upgrades 
                                          according to the e-rate discount rates for C1 items."), br(),
                                            plotOutput("histogram_by_erate_discounts"), br(), dataTableOutput("table_by_erate_discounts")))
                                        
                                    )),#),
                 
                # navbarMenu("Affordability",
                            tabPanel("Affordability", br(), #htmlOutput("helptext_price_cpc"), br(), 
                                  sidebarLayout( sidebarPanel(width = 3,
                                                              h2(strong("Please select circuit size(s) below. 
                                                                        Any filters and selections applied will affect all charts on this tab.")),
                                  div(id = "affordability_filters", 
                                        uiOutput("bandwidthSelect"), 
                                       
                                        
                                        checkboxGroupInput(inputId = "purpose", 
                                                        label = h2("Select Purpose(s)"),
                                                        choices = c('Internet', 'Upstream', 'WAN', 'ISP Only'),
                                                        selected = c('Internet')),
                                        
                                        checkboxGroupInput(inputId = "connection_services", 
                                                        h2("Select Connection Type(s)"),
                                                        choices = c("Dark Fiber", "Lit Fiber", "Fixed Wireless",
                                                                    "Cable", "DSL", "Copper", "Other / Uncategorized"),
                                                        selected = c("Lit Fiber")),
                                        
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
                                       #fluidRow(
                                         
                                    wellPanel(     
                                     column(12, align = "left", h4("DISTRIBUTION OF MONTHLY COST PER CIRCUIT"), br()), 
                                     column(12, align = "left", p("This chart shows the 25th percentile, median, and 75th percentile of monthly cost per circuit
                                       for selected services."), br(), br(), br(), br()),  
                                     column(12, align = "center", plotOutput("cpc_sidebars", width = '800px', height = '500px'), br()),
                                     dataTableOutput("disp_cpc_table")), br(), br(), br(),
                                    
                                    wellPanel(
                                      h4("DISTRIBUTION OF MONTHLY COST PER MBPS"),
                                      column(12, align = "center", plotOutput("price_disp_cpm_sidebars", width = '800px', height = '500px')),
                                      br(), dataTableOutput("disp_cpm_table")
                                    ), 
                                     #column(12, align = "left", h4("DISTRIBUTION OF MONTHLY COST PER MBPS"), br()), 
                                     #column(12, align = "left", p("This chart shows the 25th percentile, median, and 75th percentile of monthly cost per Mbps
                                     #  for selected services."), br()), 
                                     #column(12, align = "center", plotOutput("price_disp_cpm_sidebars", width = '800px', height = '500px'), br(), dataTableOutput("disp_cpm_table")), 
                                     br(), br(), br(),
                                    
                                    #),# close fluidRow 
                        
                                     
                                
                                     h4("SCATTERPLOT OF MONTHLY COST PER CIRCUIT"), br(),#), 
                                    p("This vertical scatterplot shows the entire distribution of monthly cost per circuit for selected services
                                       at different circuit sizes."),
                                    p(HTML(paste0("Please visit the ", a("IRT", href = "http://irt.educationsuperhighway.org", target = "_blank"), " to see more information
                                                   about a particular district."))), br(),
                                     #column(12, align = "left", p("This vertical scatterplot shows the entire distribution of monthly cost per circuit for selected services
                                    #   at different circuit sizes.")),
                                     #column(12, align = "left", p(HTML(paste0("Please visit the ", a("IRT", href = "http://irt.educationsuperhighway.org", target = "_blank"), " to see more information
                                      #             about a particular district."))), br()),
                                     #column(12, align = "center", ggvisOutput("plot1"), br())),#close last column & closing wellPanel
                                     column(12, align = "center", ggvisOutput("plot1"), br()), 
                                     div(dataTableOutput("plot1_table"), style = "font-size:60%"), br(), br(), br() 

                            ##tabPanel("Histogram: Monthly Cost Per Mbps", htmlOutput("helptext_price_cpm"), align = "left", ggvisOutput("price_disp_cpm"), align = "center"),
                            ##tabPanel("Scatterplot: Monthly Cost Per Circuit", htmlOutput("helptext_price_cpm_scatter"), align = "left", ggvisOutput("plot1"), align = "center")
                             #tabPanel("Histogram: Median Cost per Circuit by State", plotOutput("histogram_cost_comparison_by_state"), tableOutput("table_cost_comparison_by_state"))#,
                            #tabPanel("Current vs. Ideal Pricing: % Districts Meeting Goals", plotOutput("histogram_hypothetical_ia_goal"), tableOutput("table_hypothetical_ia_goal"), tableOutput("table_hypothetical_median_cost2"))
                            #tabPanel("Comparison: Overall National", plotOutput("overall_national_comparison"), tableOutput("national_n_table"), tableOutput("state_n_table")),
                            #tabPanel("Comparison: Your State vs. Rest", plotOutput("state_vs_rest_comparison"), tableOutput("n_observations_comparison"))
                            
                                     ))
                            )#, 
                # tabPanel("View Underlying Data", p(), 
                #            fluidPage(
                #                  wellPanel(tags$style(type="text/css", '#leftPanel { width:300px; float:left;}'),
                #                            id = "leftPanel",
                #                            selectInput(inputId = "download_dataset", 
                #                                            label = h2("Choose a dataset:"),
                #                                            choices = c("districts_table", 
                #                                                        "line_items_table")),
                #                  downloadButton('downloadData', 'Download'))), h3(tableOutput("table")))
                 
                )
) #closing tabsetPanel() and div()

  
  



  
  )
) #closing fluidPage() and shinyUI()
