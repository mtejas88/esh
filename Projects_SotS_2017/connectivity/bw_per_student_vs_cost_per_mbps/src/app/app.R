
#packages
packages.to.install <- c("ggplot2","dplyr","shiny","purrr","shinythemes","plotly","stringi")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(ggplot2)
library(dplyr)
library(shiny)
library(shinythemes)
library(plotly)
library(stringi)

theme_esh <- function(){
  theme(
    text = element_text(color="#666666", size=13),
    panel.grid.major = element_line(color = "light grey"),
    panel.grid.major.x = element_blank(),
    panel.background = element_rect(fill = "white")
  )
}

districts_exp=read.csv("data/districts_exp.csv", as.is=T,header=T)

#filter out districts with $0 monthly cost & formatting
districts_exp=districts_exp %>% filter(ia_monthly_cost_per_mbps > 0 & ia_monthly_cost_per_mbps > 0)
districts_exp$year=as.character(districts_exp$year)
districts_exp$esh_id=as.character(districts_exp$esh_id)
districts_exp$county=stri_trans_totitle(districts_exp$county)

##########################################################################################################
ui <- fluidPage(
  theme = shinytheme("yeti"),
  tags$style(type="text/css",
             ".shiny-output-error { visibility: hidden; }",
             ".shiny-output-error:before { visibility: hidden; }"
  ),
                
  # Application title
  titlePanel("Cost per Mbps vs. Bandwidth per Student (kbps)"),
  h3("District Level, 2015-2017"),
  
  # Sidebar with a slider input for number of bins
  sidebarPanel(
    width = 2,
    h4("Filters"),
    selectizeInput("state", label = "State",
                   choices = sort(unique(districts_exp$postal_cd)), multiple = T,
                   options = list(maxItems = 10, placeholder = 'Select at least one state'),
                   selected = "PA"),

    selectizeInput("county", label = "County",
                   choices = sort(unique(districts_exp$county)), multiple = T,
                   options = list(maxItems = 10, placeholder = 'Select at least one county'),
                   selected = "Bucks County"),

    selectizeInput("name", label = "District Name",
                   choices = sort(unique(districts_exp$name)), multiple = T,
                   options = list(maxItems = 10, placeholder = 'Select at least one name'),
                   selected = NULL),
    
    sliderInput("students", "Number of Students",
                min = 1, max = 944146, 
                value = c(1,20000)
    ),
    
    helpText("Districts shown are clean for IA and cost analysis in each year, in Universe and Traditional")
  ),
  
  # Plot
  mainPanel(
    plotlyOutput("trendPlot")
  )
)

server <- function(input, output, session) {
  #filters
withProgress(message = 'Loading', value = 0, {
df=reactive({
  if (length(input$state) == 0 & length(input$county) == 0 & length(input$name) == 0) {
    districts_exp
  } 
  else if (length(input$state) == 0 & length(input$county) == 0 & length(input$name) > 0) {
    districts_exp %>% filter((name %in% input$name) & (num_students >= min(input$students) & num_students <= max(input$students)))
  } 
  else if (length(input$state) == 0 & length(input$name) == 0 & length(input$county) > 0) {
    districts_exp %>% filter((county %in% input$county) & (num_students >= min(input$students) & num_students <= max(input$students)))
  }
  else if (length(input$county) == 0 & length(input$name) == 0 & length(input$state) > 0) {
    districts_exp %>% filter((postal_cd %in% input$state) & (num_students >= min(input$students) & num_students <= max(input$students)))
  }
  else if (length(input$state) == 0 & length(input$county) > 0 & length(input$name) > 0) {
    districts_exp %>% filter((county %in% input$county) & (name %in% input$name) & (num_students >= min(input$students) & num_students <= max(input$students)))
  }
  else if (length(input$county) == 0 & length(input$state) > 0 & length(input$name) > 0) {
    districts_exp %>% filter((postal_cd %in% input$state) & (name %in% input$name) & (num_students >= min(input$students) & num_students <= max(input$students)))
  }
  else if (length(input$name) == 0 & length(input$state) > 0 & length(input$county) > 0) {
    districts_exp %>% filter((postal_cd %in% input$state) & (county %in% input$county) & (num_students >= min(input$students) & num_students <= max(input$students)))
  } else{
    districts_exp %>% filter((postal_cd %in% input$state) & (county %in% input$county) & (name %in% input$name) & (num_students >= min(input$students) & num_students <= max(input$students)))
  }
}) 
})
#update the filters
  observe({
  if (nrow(df()) > 0) {
    if (length(input$state) > 0) {
    updateSliderInput(session,"students", min = 1, max=max(districts_exp[districts_exp$postal_cd %in% input$state,]$num_students))}
    if(length(input$state) >= 0 & length(input$name) == 0 & (length(input$county) > 0)) {
      if (length(input$state) > 0) {
      updateSelectInput(session,"county", choices = sort(unique(districts_exp[districts_exp$postal_cd %in% input$state,]$county)),selected=input$county)}
      updateSelectInput(session,"name", choices = sort(unique(df()$name)),selected=input$name)
    }else if(length(input$state) > 0 & length(input$name) == 0 & (length(input$county) == 0)) {
      updateSelectInput(session,"name", choices = sort(unique(df()$name)),selected=input$name)
      updateSelectInput(session,"county", choices = sort(unique(df()$county)),selected=input$county)
    }
    if (length(input$name) > 0 & length(input$state) > 0 & length(input$county) > 0){
      updateSelectInput(session,"state", choices = sort(unique(df()$postal_cd)),selected=input$state)
      updateSelectInput(session,"county", choices = sort(unique(df()$county)),selected=input$county)
      updateSelectInput(session,"name", choices = sort(unique(districts_exp[(districts_exp$postal_cd %in% input$state) & (districts_exp$county %in% input$county),]$name)),selected=input$name)
    } 
    if (length(input$state) == 0 & length(input$county) == 0 & length(input$name) == 0){
    updateSliderInput(session,"students", min = 1, max=944146)
    }
  }
  })
  
    #plot
  withProgress(message = 'Loading', value = 0, {
    output$trendPlot <- renderPlotly({
      if (nrow(df())> 0) {
      q <- ggplot(df(), aes(x = bandwidth_per_student_kbps, y = ia_monthly_cost_per_mbps,group=esh_id))
      ggp = q +  geom_point(aes(color=year,text=paste("Year:", df()$year, "<br>","State:", df()$postal_cd, "<br>", "County:", df()$county, "<br>", "Name:", df()$name, "<br>", "# Students:", df()$num_students,"<br>", "IA $/mbps:", round(df()$ia_monthly_cost_per_mbps,2),"<br>", "IA kbps/student:",round(df()$bandwidth_per_student_kbps,0))), size=2) +
        scale_color_manual(values=c('#d19328' ,'#fdb913', '#fcd56a'))+
        geom_line() +
        scale_x_continuous(breaks=c(0,10,250,1000,5000,50000,250000), labels=c(0,10,250,1000,5000,50000,250000), trans="log2")+
        scale_y_continuous(breaks=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), labels=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), trans="log2")+
        xlab("IA kbps/student")+
        ylab("IA $/mbps")+
        theme_esh()
      
      if (!is.null(ggp)) {
        gg=ggplotly(ggp, tooltip="text")
        
        gg}
      }
    })    
  })  
}

shinyApp(ui, server)