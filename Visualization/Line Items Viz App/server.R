shinyServer(function(input, output, session) {
  library(ggplot2)
  library(scales)
  library(shiny)
  library(dplyr)
  library(grid)
  library(tidyr)
  
  
  li <- read.csv("li_shiny_1_14.csv")
  us_ddt <- read.csv("us_ddt.csv")
  li$num_students <- as.numeric(as.character(li$num_students))
  li$bandwidth_in_mbps <- as.numeric(as.character(li$bandwidth_in_mbps))
  li$ia_bandwidth_per_student <- as.numeric(as.character(li$ia_bandwidth_per_student))
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
                 filter(cost_per_line < 40000) %>%
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
      scale_x_continuous(labels=dollar) + xlab("Cost Per Mbps") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_text(size=7, colour= "#899DA4"), 
            axis.text.y=element_text(size=7, colour= "#899DA4"),
            axis.ticks=element_blank(),
            axis.title.x=element_text(size=9, colour= "#899DA4", vjust=-1),
            axis.title.y=element_blank(),
            panel.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            plot.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            legend.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
            plot.margin = unit(c(1,1,1,1), "cm")
      )
  },res=140)


output$natComparison <- renderPlot({
  selected_purpose <- paste0('\"',input$purpose, '\"')
  selected_size <- paste0('\"',input$size, '\"')
  selected_locale <- paste0('\"',input$locale, '\"')
  selected_connection <- paste0('\"',input$connection, '\"')
  selected_state <- toString(input$state)
  selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')
  
  li_subset <- li %>% filter_(ifelse(input$size == 'All', "1==1", paste("district_district_size ==", selected_size))) %>%
    filter_(ifelse(input$locale == 'All', "1==1", paste("district_locale ==", selected_locale))) %>%
    filter_(ifelse(input$connection == 'All', "1==1", paste("connect_category ==", selected_connection))) %>%
    filter_(ifelse(input$purpose == 'All', "1==1", paste("new_purpose ==", selected_purpose))) %>%
    filter(cost_per_line < 40000) %>%
    mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%           
    filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
  
  
    li_subset$district_postal_cd[li_subset$district_postal_cd != selected_state] <- 'National'
    li_subset$district_postal_cd <- factor(li_subset$district_postal_cd, level=c('National', selected_state))
  
  validate(
    need(nrow(li_subset) > 0, "No circuits in given subset")
  )
  
  meds <- li_subset %>% group_by(district_postal_cd) %>% summarise(medians = median(cost_per_line))
  dollar_format(largest_with_cents=1)
  print(ggplot(li_subset, aes(x=district_postal_cd, y=cost_per_line)) + geom_boxplot(fill="#009291", colour="#ABBFC6", 
                                                                              outlier.colour="#009291", width=.5) +
          scale_y_continuous("",labels=dollar) +
          geom_text(data = meds, aes(x = district_postal_cd, y = medians, label = dollar(medians)), 
                    size = 4, vjust = -2, colour= "#F26B21", hjust=2.1)+
          theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
                panel.background = element_blank(), axis.line = element_blank(), 
                axis.text.x=element_text(size=14, colour= "#899DA4"), 
                axis.text.y=element_text(size=14, colour= "#899DA4"),
                axis.ticks=element_blank(),
                axis.title.x=element_blank(),
                axis.title.y=element_blank()
          ))
})

### Sujin's
output$mg_map <- renderPlot({
  
  width  <- session$clientData$output_distPlot_width
  height <- session$clientData$output_distPlot_height
  #us_ddt_subset <- us_ddt
  #colnames(us_ddt_subset)

  
  if(input$state == 'All') {
    us_ddt_subset <- subset(us_ddt, us_ddt$postal_cd != 'AK' & us_ddt$postal_cd != 'HI')
    state_map <- map_data("state", region = ".")
    zoom <- 4
  }
  else {
    us_ddt_subset <- subset(us_ddt, us_ddt$postal_cd == input$state)
    state_lookup <- data.frame(cbind(name = c('california', 'oregon', 'washington', 'nevada', 
                                              'iowa', 'nebraska', 'new mexico', 'colorado', 
                                              'montana' , 'minnesota', 'north dakota', 'south dakota', 
                                              'illinois', 'wisconsin', 'indiana', 'pennsylvania','new york', 
                                              'michigan', 'new jersey', 'florida', 'maine', 'new hampshire', 'massachusetts', 
                                              'rhode island', 'delaware', 'maryland', 'montana', 'north carolina', 'south carolina',
                                              'virginia', 'west virginia', 'louisiana', 'missouri', 'arkansas',
                                              'mississippi', 'kansas', 'georgia', 'texas'), 
                                     code = c('CA', 'OR', 'WA', 'NV', 
                                              'IA', 'NE', 'NM', 'CO', 
                                              'MT' , 'MN', 'ND', 'SD', 
                                              'IL', 'WI', 'IN', 'PA','NY', 
                                              'MI', 'NJ', 'FL', 'ME', 'NH', 'MA', 
                                              'RI', 'DE', 'MD', 'MT', 'NC', 'SC',
                                              'VA', 'WV', 'LS', 'MO', 'AR',
                                              'MS', 'KS', 'GA', 'TX')), stringsAsFactors = F)
    state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
    state_map <- map_data("state", region = state_name)
  }
  
  
  #state_map <- map_data("state", region = ".")
  state_base <- ggplot(state_map, aes(x = long, y = lat)) #long and lat are names within state_map dataset
  q <- state_base + geom_point(data = us_ddt_subset, aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), alpha=0.7, size = 4, position = position_jitter(w = 0.03, h = 0.03)) +
    #coord_fixed(1.3) +
    geom_polygon(data = state_map, aes(x = long, y= lat, group = group), color = 'black', fill = NA) +
    theme_classic() + 
    ggtitle("District - Clean Versus Not Clean") +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16)) +
    guides(shape=guide_legend(override.aes=list(size=7))) +
   coord_map()
  
  print(q) #pink: false, blue: true
  
  })
output$bwProjection <- renderPlot({
  selected_size <- paste0('\"',input$size, '\"')
  selected_locale <- paste0('\"',input$locale, '\"')
  selected_state <- paste0('\"',input$state, '\"')
  
  li_subset <- li %>% filter_(ifelse(input$size == 'All', "1==1", paste("district_district_size ==", selected_size))) %>%
    filter_(ifelse(input$locale == 'All', "1==1", paste("district_locale ==", selected_locale))) %>%
    filter_(ifelse(input$state == 'All', "1==1", paste("district_postal_cd ==", selected_state))) %>%
    filter(connect_category != 'Fiber')
    
  validate(
    need(nrow(li_subset) > 0, "No circuits in given subset")
  )
  
  need_fiber <- li_subset %>% mutate(adj_bw = ifelse(ia_bandwidth_per_student < 100, 100, ia_bandwidth_per_student)) %>% 
    mutate(bw2016 = adj_bw * num_students) %>% mutate(f2016 = ifelse(bw2016 >= 100000, 1, 0)) %>%
    mutate(bw2017 = bw2016 * 1.5) %>% mutate(f2017 = ifelse(bw2017 >= 100000, 1, 0)) %>%
    mutate(bw2018 = bw2017 * 1.5) %>% mutate(f2018 = ifelse(bw2018 >= 100000, 1, 0)) %>%
    mutate(bw2019 = bw2018 * 1.5) %>% mutate(f2019 = ifelse(bw2019 >= 100000, 1, 0)) %>%
    mutate(bw2020 = bw2019 * 1.5) %>% mutate(f2020 = ifelse(bw2020 >= 100000, 1, 0)) %>%
    mutate(bw2021 = bw2020 * 1.5) %>% mutate(f2021 = ifelse(bw2021 >= 100000, 1, 0)) %>%
    mutate(bw2022 = bw2021 * 1.5) %>% mutate(f2022 = ifelse(bw2022 >= 100000, 1, 0)) %>%
    mutate(bw2023 = bw2022 * 1.5) %>% mutate(f2023 = ifelse(bw2023 >= 100000, 1, 0)) %>%
    mutate(bw2024 = bw2023 * 1.5) %>% mutate(f2024 = ifelse(bw2024 >= 100000, 1, 0)) %>%
    mutate(bw2025 = bw2024 * 1.5) %>% mutate(f2025 = ifelse(bw2025 >= 100000, 1, 0)) %>%
    select(c(f2016, f2017, f2018, f2019, f2020, f2021, f2022, f2023, f2024, f2025)) %>%
    summarise_each(funs(mean(., na.rm = TRUE))) %>%
    t() %>% data.frame() %>% mutate(Year=as.factor(c(2016:2025)))

  colnames(need_fiber) <- c("Need_Fiber", "Year")

  ggplot(need_fiber, aes(x=Year, y=Need_Fiber, group=1)) + geom_line(colour="#F26B21") +
    xlab("Year") +
    ggtitle("Percentage of Schools Needing Fiber") +
    scale_y_continuous(labels=percent) +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.line = element_blank(), 
          axis.text.x=element_text(size=7, colour= "#899DA4"), 
          axis.text.y=element_text(size=7, colour= "#899DA4"),
          axis.ticks=element_blank(),
          plot.title=element_text(size=9, colour= "#899DA4", vjust=1),
          axis.title.x=element_text(size=9, colour= "#899DA4", vjust=-1),
          axis.title.y=element_blank(),
          panel.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
          plot.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
          legend.background = element_rect(colour = "#FFFFFF", fill ="#FFFFFF"),
          plot.margin = unit(c(1,1,1,1), "cm")
    )
},res=140)

})
  
  
  
  
  
  