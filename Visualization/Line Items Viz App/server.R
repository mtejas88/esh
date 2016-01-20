shinyServer(function(input, output, session) {
  library(ggplot2)
  library(scales)
  library(shiny)
  library(dplyr)
  li <- read.csv("li_shiny_1_14.csv")
  li$num_students <- as.numeric(as.character(li$num_students))
  li$bandwidth_in_mbps <- as.numeric(as.character(li$bandwidth_in_mbps))
  li$district_locale <- as.factor(li$locale)
  li$district_district_size <- as.factor(li$district_size)
  li$connect_category <- as.factor(li$li_connect_category)
  li$district_postal_cd <- as.character(li$postal_cd)
  li$rec_elig_cost <- as.numeric(as.character(li$line_item_recurring_elig_cost))
  li$cost_per_line <- (li$rec_elig_cost / li$line_item_total_num_lines)
  li$cost_per_mbps <-  li$cost_per_line / li$bandwidth_in_mbps
  li$new_purpose[li$internet_conditions_met == 'TRUE'] <- "Internet"
  li$new_purpose[li$wan_conditions_met == 'TRUE'] <- "WAN"
  li$new_purpose[li$isp_conditions_met == 'TRUE'] <- "ISP Only"
  li$new_purpose[li$upstream_conditions_met == 'TRUE'] <- "Upstream"
  #li <- li %>% filter(bandwidth_in_mbps %in% c(50,100,500,1000,10000)) %>% mutate(band_factor = as.factor(bandwidth_in_mbps))


  output$distPlot <- renderPlot({
    selected_purpose <- paste0('\"',input$purpose, '\"')
    selected_size <- paste0('\"',input$size, '\"')
    selected_locale <- paste0('\"',input$locale, '\"')
    selected_connection <- paste0('\"',input$connection, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')

    li_subset <- li %>% filter_(ifelse(input$size == 'All', "1==1", paste("district_district_size ==", selected_size))) %>%
                 filter_(ifelse(input$locale == 'All', "1==1", paste("district_locale ==", selected_locale))) %>%
                 filter_(ifelse(input$connection == 'All', "1==1", paste("connect_category ==", selected_connection))) %>%
                 filter_(ifelse(input$state == 'All', "1==1", paste("district_postal_cd ==", selected_state))) %>%
                 filter_(ifelse(input$purpose == 'All', "1==1", paste("new_purpose ==", selected_purpose))) %>%
                 mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%           
                 filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
                 
    
    
    
    validate(
      need(nrow(li_subset) > 0, "No circuits in given subset")
    )
    
    meds <- li_subset %>% group_by(band_factor) %>% summarise(medians = median(cost_per_line))
    dollar_format(largest_with_cents=1)
    print(ggplot(li_subset, aes(x=band_factor, y=cost_per_line)) + geom_boxplot(fill="#009291", colour="#ABBFC6", 
      outlier.colour="#009291", width=.5) +
      scale_y_continuous("",labels=dollar) +
      geom_text(data = meds, aes(x = band_factor, y = min(medians), label = dollar(medians)), 
                 size = 4, vjust = -1, colour= "#F26B21", hjust=2.1)+
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_text(size=14, colour= "#899DA4"), 
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
    selected_purpose <- paste0('\"',input$purpose, '\"')
    selected_size <- paste0('\"',input$size, '\"')
    selected_locale <- paste0('\"',input$locale, '\"')
    selected_connection <- paste0('\"',input$connection, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')
    
    li_subset <- li %>% filter_(ifelse(input$size == 'All', "1==1", paste("district_district_size ==", selected_size))) %>%
      filter_(ifelse(input$locale == 'All', "1==1", paste("district_locale ==", selected_locale))) %>%
      filter_(ifelse(input$connection == 'All', "1==1", paste("connect_category ==", selected_connection))) %>%
      filter_(ifelse(input$state == 'All', "1==1", paste("district_postal_cd ==", selected_state))) %>%
      filter_(ifelse(input$purpose == 'All', "1==1", paste("new_purpose ==", selected_purpose))) %>%
      mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%           
      filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
    
      paste("n =", toString(nrow(li_subset)))
    })
  
  output$histPlot <- renderPlot({
    selected_purpose <- paste0('\"',input$purpose, '\"')
    selected_size <- paste0('\"',input$size, '\"')
    selected_locale <- paste0('\"',input$locale, '\"')
    selected_connection <- paste0('\"',input$connection, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')
    
    li_subset <- li %>% filter_(ifelse(input$size == 'All', "1==1", paste("district_district_size ==", selected_size))) %>%
      filter_(ifelse(input$locale == 'All', "1==1", paste("district_locale ==", selected_locale))) %>%
      filter_(ifelse(input$connection == 'All', "1==1", paste("connect_category ==", selected_connection))) %>%
      filter_(ifelse(input$state == 'All', "1==1", paste("district_postal_cd ==", selected_state))) %>%
      filter_(ifelse(input$purpose == 'All', "1==1", paste("new_purpose ==", selected_purpose))) %>%
      mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%           
      filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
    
    validate(
      need(nrow(li_subset) > 0, "No circuits in given subset")
    )
    ggplot(li_subset, aes(x=cost_per_mbps)) + geom_histogram(fill="#009291", colour="#FFFFFF") +
      scale_x_continuous(labels=dollar) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_text(size=7, colour= "#899DA4"), 
            axis.text.y=element_text(size=7, colour= "#899DA4"),
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
  
  
  
  
  
  