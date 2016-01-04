shinyServer(function(input, output, session) {
  library(ggplot2)
  library(scales)
  library(showtext)
  library(sysfonts)
  
  li <- read.csv("li_for_shiny.csv")
  li$district_num_students <- as.numeric(as.character(li$district_num_students))
  li$bandwidth_in_mbps <- as.numeric(as.character(li$bandwidth_in_mbps))
  li$num_lines <- as.numeric(as.character(li$num_lines))
  li$district_locale <- as.factor(li$district_locale)
  li$district_district_size <- as.factor(li$district_district_size)
  li$connect_category <- as.factor(li$connect_category)
  li$district_postal_cd <- as.factor(li$district_postal_cd)
  li$rec_elig_cost <- as.numeric(as.character(li$rec_elig_cost))
  li$cost_per_mbps <- (li$rec_elig_cost / li$num_lines) / li$bandwidth_in_mbps

  output$distPlot <- renderPlot({
    width  <- session$clientData$output_distPlot_width
    height <- session$clientData$output_distPlot_height
  
    if(input$state == 'All') {
      li_subset <- subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                            li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2] &
                            li$district_district_size == input$size)
    }
    else {
      li_subset <- subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                            li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2] &
                            li$district_district_size == input$size & district_postal_cd == input$state)
    }
    validate(
      need(nrow(li_subset) > 0, "No circuits in given subset")
    )
    
    print(ggplot(li_subset, aes(x=3,y=cost_per_mbps)) + geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour="#009291") +
      xlim(1,5) +
      scale_y_continuous("",labels=dollar) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_blank(), 
            axis.text.y=element_text(size=14, colour= "#899DA4"),
            axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank()
            #legend.text = element_text(family="Helvetica", colour="#899DA4"),
            #legend.title = element_text(family="Helvetica", colour="#899DA4"),
            #panel.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            #plot.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            #legend.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            #plot.margin = unit(c(2.3333,.6,2.3333,.6), "cm")
      ))
  }) 
  
  output$n_observations <- renderText({
    if(input$state == 'All') {
    paste("n =", 
          toString(nrow(
            subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                     li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2]&
                     li$district_district_size == input$size))))
    }
    else{
      paste("n =", 
            toString(nrow(
              subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                       li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2]&
                       li$district_district_size == input$size & district_postal_cd == input$state))))
    }
    })
  output$histPlot <- renderPlot({
    if(input$state == 'All') {
      li_subset <- subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                            li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2] &
                            li$district_district_size == input$size)
    }
    else {
      li_subset <- subset(li, li$connect_category == input$connection & li$district_locale == input$locale &
                            li$bandwidth_in_mbps >= input$bandwidth[1] & li$bandwidth_in_mbps <= input$bandwidth[2] &
                            li$district_district_size == input$size & district_postal_cd == input$state)
    }
    validate(
      need(nrow(li_subset) > 0, "No circuits in given subset")
    )
    ggplot(li_subset, aes(x=cost_per_mbps)) + geom_histogram(fill="#009291", colour="#FFFFFF") +
      scale_x_continuous(labels=dollar) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            #axis.text.x=element_text(family="Helvetica"), 
            #axis.text.y=element_text(family="Helvetica"),
            axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank(),
            panel.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            plot.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            legend.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF")
            #plot.margin = unit(c(2.3333,.6,2.3333,.6), "cm")
      )
  },res=140)
  
  })
  
  
  
  
  
  