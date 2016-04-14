lib <- c("dplyr", "shiny", "shinyBS", "tidyr", "ggplot2", "scales", "grid", "maps", "ggmap", "ggvis")
sapply(lib, function(x) require(x, character.only = TRUE))

wd <- "~/Google Drive/github/ficher/Shiny"
setwd(wd)

services <- read.csv("services_received_shiny.csv", as.is = TRUE)
districts <- read.csv("districts_shiny.csv", as.is = TRUE)

# factorize
services$band_factor <- as.factor(services$band_factor)
services$postal_cd <- as.factor(services$postal_cd)

shinyServer(function(input, output, session) {
  
  ## Create reactive functions for both services received and districts table ##
  ## Note: it is necessary to create two separate reactive datasets for box-and-whiskers (b-w) plot 
  ## and other price comparison plots since b-w plot is limited to popular bandwidths
  
  ## General Line Items for national comparison (national vs. state) and
  ## also one state vs. all other states
  
li_all <- reactive({

    services %>% 
      filter(new_purpose %in% input$purpose,
             new_connect_type %in% input$connection_services, 
             district_size %in% input$district_size,
             locale %in% input$locale)
  
})
  
## Line Items with filter that now includes banding circuits by most popular circuit speeds
li_bf <- reactive({
    
    selected_state <- paste0('\"',input$state, '\"')
    
    services %>% 
      filter(band_factor %in% input$bandwidths,
             new_purpose %in% input$purpose,
             district_size %in% input$district_size,
             locale %in% input$locale,
             new_connect_type %in% input$connection_services) %>%
      filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) 
}) 
  
district_subset <- reactive({
      
    selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')

  districts %>% 
    filter_(ifelse(input$dataset == 'All', "1==1", paste("exclude ==", selected_dataset))) %>% 
    filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>% 
    filter(new_connect_type %in% input$connection_districts, 
           district_size %in% input$district_size,
           locale %in% input$locale,
           !(postal_cd %in% c('AK', 'HI')))

  })
  
## Histogram for banded factors ##
output$plot <- renderPlot({
  
  data <- li_bf()
  
  validate(need(nrow(data) > 0, "No circuits in given subset"))  
  p <- ggplot(data = data) + 
       geom_histogram(aes(x = band_factor), alpha = 0.5, position = "identity", binwidth = 25) 
    
  print(p)
  
  })

## Box and Whiskers Plot
## use li_bf, only for selected circuit sizes

output$bw_plot <- renderPlot({
  
  data <- li_bf()
  validate(need(nrow(data) > 0, "No circuits in given subset"))
  
  give.n <- function(x){
    return(c(y = median(x) * 0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  }
  
  meds <- data %>% 
          group_by(band_factor) %>% 
          summarise(medians = round(median(monthly_cost_per_circuit, na.rm = TRUE)))
  
  dollar_format(largest_with_cents=1)
  
  ylim1 <- boxplot.stats(data$monthly_cost_per_circuit)$stats[c(1, 5)]   #column 1 and 5 are min and max
  
  p0 <- ggplot(data, aes(x = band_factor, y = monthly_cost_per_circuit)) + 
        geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) 
  #+ 
   #     stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 5) 
      
  a <- p0 + 
       coord_cartesian(ylim = ylim1 * 2.0) + 
       scale_y_continuous("",labels=dollar) +
    #   geom_text(data = meds, aes(x = band_factor, y = medians, label = dollar(medians)), 
     #            size = 5, vjust = -.3, colour= "#F26B21", hjust=.5)+
       theme_classic() + 
       theme(axis.line = element_blank(), 
              axis.text.x=element_text(size=14, colour= "#899DA4"), 
              axis.text.y=element_text(size=14, colour= "#899DA4"),
              axis.ticks=element_blank(),
              axis.title.x=element_blank(),
              axis.title.y=element_blank())
    
     print(a)
     print(nrow(data))

})

output$counts_table <- renderTable({
  
  data <- li_bf()
  
  data %>% 
    group_by(band_factor) %>% 
    summarise(num_line_items = n(), 
              num_circuits = sum(line_item_total_num_lines))
  
})

output$prices_table <- renderTable({
  
  data <- li_bf()
  
  data %>% 
    group_by(band_factor) %>% 
    summarise(min_cost_per_mbps = round(min(monthly_cost_per_mbps, na.rm = TRUE)),
              q25_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.25, na.rm = TRUE)),
              median_cost_per_mbps = round(median(monthly_cost_per_mbps, na.rm = TRUE)),
              q75_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.75, na.rm = TRUE)),
              max_cost_per_mbps = round(max(monthly_cost_per_mbps, na.rm = TRUE)))
  
})



## Comparison: Specific State vs. All Other States 
output$state_vs_rest_comparison <- renderPlot({
  
  #excluding the state that is specifically being compared to rest of the nation
  li_all2 <- li_all() 
  
  levels(li_all2$postal_cd) <- c(levels(li_all2$postal_cd), "National")
  li_all2$postal_cd[li_all2$postal_cd != input$state] <- "National"
  
  str(li_all2$postal_cd)
  
  ##### NOTE: This causes as warning: "Warning in Ops.factor(left, right) : ‘>’ not meaningful for factors"
  validate(
    need(nrow(li_all2 > 0), "No circuits in given subset")
  )
  #####
  
  give.n <- function(x){
    return(c(y = median(x)*0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  }
  
  p0 <- ggplot(li_all2, aes(x=postal_cd, y = monthly_cost_per_circuit)) + 
        geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
        stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
      
  ylim1 <- boxplot.stats(li_all2$monthly_cost_per_circuit)$stats[c(1, 5)]

  meds <- li_all2 %>% 
          group_by(postal_cd) %>% 
          summarise(medians = median(monthly_cost_per_circuit))
  
  dollar_format(largest_with_cents=1)
  
  b <- p0 + 
      coord_cartesian(ylim = ylim1*2.0) +
      scale_y_continuous("",labels=dollar) +
      geom_text(data = meds, aes(x = postal_cd, y = medians, label = dollar(medians)), 
                size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_text(size=14, colour= "#899DA4"), 
            axis.text.y=element_text(size=14, colour= "#899DA4"),
            axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank())
    print(b)
  })


output$n_observations_comparison <- renderText({
  li_all2 <- li_all() 
  
  li_all2$postal_cd[li_all2$postal_cd != input$state] <- 'National'
  print(unique(li_all2$postal_cd))
  li_all2$postal_cd <- factor(li_all2$postal_cd, level=c('National', input$state))
  print(unique(li_all2$postal_cd))
  ns <- li_all2 %>% group_by(postal_cd) %>% summarise(len = length(monthly_cost_per_circuit))
  print(ns$len)
  paste("Number of line items: ", ns[1,2], ns[2,2])
})

#traditional way of national comparison
output$trad_nat_comparison <- renderPlot({
  
  #excluding the state that is specifically being compared to rest of the nation
  li_all2 <- li_all()
  
  ##### NOTE: This causes as warning: "Warning in Ops.factor(left, right) : ‘>’ not meaningful for factors"
  validate(
    need(nrow(li_all2 > 0), "No circuits in given subset")
  )
  #####
  
  #CREATE A BW FOR NATIONAL MEDIAN AND PUT IT SIDE BY SIDE SPECIFIC STATE BW
  
  #use <- subset(li3, postal_cd == input$state)
  #print(head(use$postal_cd))
  
  li_all2$national <- rep("National", nrow(li_all2))
  #View(li3)
  
  give.n <- function(x){
    return(c(y = median(x)*0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  }
  
  p0 <- ggplot() + #changed x = postal_cd to x="All"
        geom_boxplot(data = li_all2, aes(x=national, y = monthly_cost_per_circuit), fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
        stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) +
        geom_boxplot(data=li_all2[li_all2$postal_cd==input$state,], aes(x= postal_cd, y = monthly_cost_per_circuit), fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
        stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
  
  
  ylim1 <- boxplot.stats(li_all2$monthly_cost_per_circuit)$stats[c(1, 5)]
  
  meds <- li_all2 %>% group_by(national) %>%  summarise(medians = median(monthly_cost_per_circuit))
  meds2 <- li_all2 %>% group_by(postal_cd) %>% filter(postal_cd==input$state) %>% summarise(medians = median(monthly_cost_per_circuit))
  dollar_format(largest_with_cents=1)
  
  b <- p0 + 
       coord_cartesian(ylim = ylim1*1.05) +
      scale_y_continuous("",labels=dollar) +
      geom_text(data = meds, aes(x = national, y = medians, label = dollar(medians)), 
                size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) + #"#F26B21" +
      geom_text(data = meds2, aes(x = postal_cd, y = medians, label = dollar(medians)), 
                size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) + 
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            panel.background = element_blank(), axis.line = element_blank(), 
            axis.text.x=element_text(size=14, colour= "#899DA4"), 
            axis.text.y=element_text(size=14, colour= "#899DA4"),
            axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank())
    print(b)
  })

output$hist <- renderPlot({
  
  data <- li_bf()
  
  validate(need(nrow(data) > 0, "No circuits in given subset"))
  
  ggplot(li_bf(), aes(x = monthly_cost_per_mbps)) + geom_histogram(fill="#009291", colour="#FFFFFF") +
    scale_x_continuous(labels=dollar) + xlab("Monthly Cost Per Mbps") +
    theme_classic() + 
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
          plot.margin = unit(c(1,1,1,1), "cm"))
  
},res=140)  

output$districtSelect <- renderUI({
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  district_list <- c(unique(as.character(district_subset()$name)))
  
  #   checkboxGroupInput("district_list", 
  #                      h2("Select District"),
  #                      choices = as.list(district_list),
  #                      selected = c('All'))
  selectInput("district_list", h2("Select District"), as.list(district_list), multiple = T) 
})


output$choose_district <- renderPlot({
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  district_subset <- district_subset() %>% 
                filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(district_subset) > 0, "No districts in given subset")
  )
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position=c(0.5, 0.5)) +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = district_subset, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) #+ #, position = position_jitter(w = 0.07, h = 0.05)) +
  #scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
  
})


output$pop_map <- renderPlot({
  
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position=c(0.5, 0.5)) +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = district_subset(), aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) #+ #, position = position_jitter(w = 0.07, h = 0.05)) +
  #scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
})

output$gen_map <- renderPlot({
  
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = district_subset(), aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
                               alpha = 0.7, size = 6) + #, position = position_jitter(w = 0.07, h = 0.05)) +
       scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
  
})  


output$goals100k_map <- renderPlot({
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)

  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + geom_point(data = district_subset(), aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 100k/student Goal", 
                                                                                      "Does Not Meet 100k/student Goal"), values = c("#009296", "#CCCCCC"))
  
  print(q + coord_map())
  
  
})  


output$goals1M_map <- renderPlot({
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = district_subset(), aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 1Mbps/student Goal", 
                                                                                      "Does Not Meet 1Mbps/student Goal"), values = c("#A3E5E6", "#CCCCCC")) #+
  
  print(q + coord_map())
  
  
})  

# Map of Districts at least 1 Unscalable School
output$unscalable <- renderPlot({
  
  validate(
    need(nrow(district_subset()) > 0, "No districts in given subset")
  )
  
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("state", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  ddt_unscalable <- district_subset() %>% 
                    filter(not_all_scalable == 1)
  
  q <- state_base + geom_point(data = ddt_unscalable, aes(x = longitude, y = latitude, colour = "Districts with at least \n one non-scalable school"), 
                               alpha = 0.8, size = 6) + scale_color_manual(values = c("#0073B6")) 

  
  print(q + coord_map())
  
  
})  


output$n_ddt <- renderText({
  
  district_subset <- district_subset()
  paste("n =", toString(nrow(district_subset)))
  
})

output$n_ddt2 <- renderText({
  
  district_subset <- district_subset()
  paste("n =", toString(nrow(district_subset)))
  
})

output$n_ddt3 <- renderText({
  
  district_subset <- district_subset()
  paste("n =", toString(nrow(district_subset)))
  
})

output$n_ddt4 <- renderText({
  
  district_subset <- district_subset()
  paste("n =", toString(nrow(district_subset)))
  
})

output$n_ddt5 <- renderText({
  
  district_unscalable <- district_subset() %>% filter(percent_scalable_ia != "All Scaleable IA")
  paste("n =", toString(nrow(district_unscalable)))
  
})

#For downloadable subsets
datasetInput <- reactive({
  selected_state <- paste0('\"',input$state, '\"')
  selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')
  
  
  li_bf <- li_bf() %>% 
           filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) 
  
  li_all2 <- li_all()
  #li_subset <- li2() %>% mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%    
  #  filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>%
  #  filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
  
  validate(
    need(nrow(li_bf) > 0, "No districts in given subset")
  )
  
  #li_subset2 <- li2() %>% 
  #              filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state)))
  
  validate(
    need(nrow(li_all2) > 0, "No districts in given subset")
  )
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  district_subset_specific <- district_subset() %>% filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(district_subset_specific) > 0, "No districts in given subset")
  )
  
  switch(input$subset,
         "Line items for B-W" = li_bf,
         "Line items for Comparisons" = li_all,
         "Deluxe districts for Selected Districts" = district_subset_specific)
})

output$table <- renderTable({
  
  datasetInput()
  
})

output$downloadData <- downloadHandler(
  filename = function(){
    paste(input$subset, '.csv', sep = '')},
  content = function(file){
    write.csv(datasetInput(), file)
  }
)

}) #closing shiny server function
