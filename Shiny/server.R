#Methodology:
#1. For cost per circuit calculation: line_item_total_monthly_cost / line_item_total_num_lines
#2. when spitting out the UNIQUE number of line items --> unique(line_item_id) 
#3. Made b-w view from *1.05 to *2.0


#sub <- li  %>% filter(bandwidth_in_mbps == 50 | bandwidth_in_mbps == 100 | bandwidth_in_mbps == 500 | bandwidth_in_mbps == 1000 | bandwidth_in_mbps == 10000)
#nrow(sub)
#8587 - 163 #163 is NA's in m_cpc
#857 + 2683 + 761 + 3623 +663 #8587

#855+2645+752+3520+645 #8417 is the figure i'm getting in shiny b-w
#sub2 <- sub %>% filter(m_cpc < 40000) #8417 checked!
#we get 8417 sum in shiny box-whiskers because they are controlled for cost outliers @ $40K

#PRICES:
#50: $800
#100: $1250
#500: 2497.3
#1000: 1295
#10000:1375

#sub3 <- li %>% filter(m_cpc < 40000)
#nrow(sub3) #13362

#AZ1k <- sub %>% filter(postal_cd == "AZ" & bandwidth_in_mbps == 1000)
#View(AZ %>% group_by(bandwidth_in_mbps) %>% summarise(n = n(), median = median(m_cpc)))


#setwd("~/Desktop/Shiny_040416")

shinyServer(function(input, output, session) {
  library(dplyr)
  library(shiny)
  library(shinyBS)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(grid)
  library(maps)
  library(ggmap)
  library(ggvis)
  
  
  sr <- read.csv("sr_030816.csv")
  ddt <- read.csv("ddt_030816.csv")
  print(nrow(sr)) #83203
  print(nrow(ddt)) #13025
  
  ### LINE ITEMS DATA: prepping the data to be the correct subset to use ###
  li0 <- sr %>% filter(shared_service == "District-dedicated" & dirty_status == "include clean" & exclude == "FALSE")
  print(nrow(li0)) #15844
  
  print(length(unique(li0$line_item_id))) #13586
  li <- li0[!duplicated(li0[4]),] #13586; checks out
  li <- li[!grepl("exclude_for_cost_only", li$open_flags),] 
  nrow(li) #now, there are 12,966 line items
  
  #converting variable types 
  li$ia_bandwidth_per_student <- as.numeric(as.character(li$ia_bandwidth_per_student))
  li$postal_cd <- as.character(li$postal_cd)
  li$band_factor <- as.factor(li$bandwidth_in_mbps)
  
  #appending new column for purpose type:
  li$new_purpose[li$internet_conditions_met == TRUE] <- "Internet"
  li$new_purpose[li$wan_conditions_met == TRUE] <- "WAN"
  li$new_purpose[li$isp_conditions_met == TRUE] <- "ISP Only"
  li$new_purpose[li$upstream_conditions_met == TRUE] <- "Upstream"
  #View(li) #checked
  
  #appending new column for monthly cost per circuit:
  li$m_cpc <- li$line_item_total_monthly_cost / li$line_item_total_num_lines #used to be called cost_per_line
  li$m_cpm <- li$m_cpc / li$bandwidth_in_mbps
  
  ##   LINE ITEMS DATA: END ##
  
  ### DDT DATA:  prepping the data to be the correct subset to use ###
  ddt$ia_bandwidth_per_student <- as.numeric(as.character(ddt$ia_bandwidth_per_student))
  
  # New Variables for Sujin's Map #
  ddt$exclude <- ifelse(ddt$exclude_from_analysis == "FALSE", "Clean", "Dirty")
  ddt$meeting_2014_goal_no_oversub <- ifelse(ddt$meeting_2014_goal_no_oversub == "TRUE", "Meeting 2014 Goals",
                                             "Not Meeting 2014 Goals")
  ddt$meeting_2018_goal_oversub <- ifelse(ddt$meeting_2018_goal_oversub == "TRUE", "Meeting 2018 Goals",
                                          "Not Meeting 2018 Goals")
  ddt$meeting_2018_goal_oversub <- as.factor(ddt$meeting_2018_goal_oversub)
  ddt$meeting_2014_goal_no_oversub <- as.factor(ddt$meeting_2014_goal_no_oversub)
  
  ##    DDT DATA: END   ##
  
  
  ## creating reactive functions for both li and ddt ##
  
  
  ## General Line Items for national comparison (national vs. state) and also one state vs. all other states
  li_all <- reactive({

    li %>% 
      filter(new_purpose %in% input$purpose,
             connect_type %in% input$connection, 
             district_size %in% input$district_size,
             locale %in% input$locale)
  })
  
  ## Line Items with filter that now includes banding circuits by most popular circuit speeds
  li_bf <- reactive({
  
    li %>% 
      filter(band_factor %in% input$bandwidths, 
             new_purpose %in% input$purpose,
             connect_type %in% input$connection, 
             district_size %in% input$district_size,
             locale %in% input$locale)
  }) 
  
  
  
  ddt_subset <- reactive({
    selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')
  
    ddt %>% 
      filter_(ifelse(input$dataset == 'All', "1==1", paste("exclude ==", selected_dataset))) %>% 
      filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>% 
      filter(hierarchy_connect_category %in% input$connection, 
             district_size %in% input$district_size,
             locale %in% input$locale,
             !postal_cd %in% c('AK', 'HI')) 
  
  })
  
  
  
  
## Histogram for banded factors ##
output$plot <- renderPlot({
  
    validate(need(nrow(li_bf()) > 0, "No circuits in given subset"))  
    p <- ggplot(data=li_bf()) + geom_histogram(aes(x=factor(band_factor)), alpha=0.5,position="identity", binwidth = 25) 
    
    print(p)
  
    })
  


## Only for selected circuit sizes
output$bw_plot <- renderPlot({
  
  selected_state <- paste0('\"',input$state, '\"')
  li_bf <- li_bf() %>% filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) 

  validate(need(nrow(li_bf) > 0, "No circuits in given subset"))
  
  give.n <- function(x){
    return(c(y = median(x)*0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  }
  
  meds <- li_bf %>% group_by(band_factor) %>% summarise(medians = median(m_cpc))
  
  dollar_format(largest_with_cents=1)
  
  ylim1 <- boxplot.stats(li_bf$m_cpc)$stats[c(1, 5)]
  
  p0 <- ggplot(li_bf, aes(x=band_factor, y=m_cpc)) + 
    geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) + 
    stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
  
  a <- p0 + coord_cartesian(ylim = ylim1*2.0) + #changed ylim1*1.05 to ylim1*2.0
    scale_y_continuous("",labels=dollar) +
    geom_text(data = meds, aes(x = band_factor, y = medians, label = dollar(medians)), 
              size = 4, vjust = -.3, colour= "#F26B21", hjust=.5)+
    theme_classic() + 
    theme( axis.line = element_blank(), 
           axis.text.x=element_text(size=14, colour= "#899DA4"), 
           axis.text.y=element_text(size=14, colour= "#899DA4"),
           axis.ticks=element_blank(),
           axis.title.x=element_blank(),
           axis.title.y=element_blank())
  
  print(a)
  
  print(nrow(li_bf))
  #print(table(li_bf$postal_cd))
  #print(li_bf)
  
  
})

output$n_observations <- renderText({

  #for num line items
  ns <- li_bf() %>% group_by(band_factor) %>% summarise(len = length(m_cpc))
  whitespace_size <- 180/(nrow(ns)^1.3)
  whitespace <- paste(rep(" ", whitespace_size), collapse="")
  formatted <- sapply(ns[,2], function(x) paste(x,collapse=whitespace))
  leadspace_size <- 100/(nrow(ns)^2.6)
  leadspace <- paste(rep(" ", leadspace_size), collapse="")
  
  #for num circuits
  ns2 <- li_bf() %>% group_by(band_factor) %>% summarise(len2 = sum(line_item_total_num_lines))
  whitespace_size2 <- 180/(nrow(ns2)^1.3)
  whitespace2 <- paste(rep(" ", whitespace_size2), collapse="")
  formatted2 <- sapply(ns2[,2], function(x) paste(x,collapse=whitespace2))
  leadspace_size2 <- 100/(nrow(ns2)^2.6)
  leadspace2 <- paste(rep(" ", leadspace_size2), collapse="")
  
  print(formatted)
  print(formatted2)
  paste("Number of line items: ", leadspace, formatted) 
  
})  


output$n_circuits_observations <- renderText({
  

  #for num circuits
  ns2 <- li_bf() %>% group_by(band_factor) %>% summarise(len2 = sum(line_item_total_num_lines))
  whitespace_size2 <- 180/(nrow(ns2)^1.3)
  whitespace2 <- paste(rep(" ", whitespace_size2), collapse="")
  formatted2 <- sapply(ns2[,2], function(x) paste(x,collapse=whitespace2))
  leadspace_size2 <- 100/(nrow(ns2)^2.6)
  leadspace2 <- paste(rep(" ", leadspace_size2), collapse="")

paste("Number of circuits: ", leadspace2, formatted2)

})

output$counts_table <- renderTable({

  li_bf() %>% group_by(band_factor) %>% summarise(num_line_items = length(m_cpc), num_circuits = sum(line_item_total_num_lines))
  
})








## Comparison: Specific State vs. All Other States 
output$state_vs_rest_comparison <- renderPlot({
  
  #excluding the state that is specifically being compared to rest of the nation
  li_all2 <- li_all() 
  
  levels(li_all2$postal_cd) <- c(levels(li_all2$postal_cd), "National")
  li_all2$postal_cd[li_all2$postal_cd != input$state] <- "National"
  
  str(li_all2$postal_cd)
  
  #li_all2$postal_cd[li_all2$postal_cd != input$state] <- 'National'     #input$state used to previously be selected_state
  #li_all2$postal_cd <-factor(li_all2$postal_cd, level=c('National', input$state)) #input$state used to previously be selected_state
  
  
  ##### NOTE: This causes as warning: "Warning in Ops.factor(left, right) : ‘>’ not meaningful for factors"
  validate(
    need(nrow(li_all2 > 0), "No circuits in given subset")
  )
  #####
  
  give.n <- function(x){
    return(c(y = median(x)*0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  }
  
  p0 <- ggplot(li_all2, aes(x=postal_cd, y=m_cpc)) + 
    geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
    stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
  
  ylim1 <- boxplot.stats(li_all2$m_cpc)$stats[c(1, 5)]

  meds <- li_all2 %>% group_by(postal_cd) %>% summarise(medians = median(m_cpc))
  dollar_format(largest_with_cents=1)
  b <- p0 + coord_cartesian(ylim = ylim1*2.0) +
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
  ns <- li_all2 %>% group_by(postal_cd) %>% summarise(len = length(m_cpm))
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
    geom_boxplot(data = li_all2, aes(x=national, y=m_cpc), fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
    stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) +
    geom_boxplot(data=li_all2[li_all2$postal_cd==input$state,], aes(x= postal_cd, y=m_cpc), fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) +
    stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
  
  
  ylim1 <- boxplot.stats(li_all2$m_cpc)$stats[c(1, 5)]
  
  meds <- li_all2 %>% group_by(national) %>%  summarise(medians = median(m_cpc))
  meds2 <- li_all2 %>% group_by(postal_cd) %>% filter(postal_cd==input$state) %>% summarise(medians = median(m_cpc))
  dollar_format(largest_with_cents=1)
  
  b <- p0 + coord_cartesian(ylim = ylim1*1.05) +
    scale_y_continuous("",labels=dollar) +
    geom_text(data = meds, aes(x = national, y = medians, label = dollar(medians)), 
              size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) + #"#F26B21" +
    geom_text(data = meds2, aes(x = postal_cd, y = medians, label = dollar(medians)), 
              size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.line = element_blank(), 
          #axis.text.x = element_blank(),
          #axis.text.y = element_blank(),
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y=element_text(size=14, colour= "#899DA4"),
          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank())
  print(b)
})



output$hist <- renderPlot({
  
  validate(need(nrow(li_bf()) > 0, "No circuits in given subset"))
  
  ggplot(li_bf(), aes(x=m_cpm)) + geom_histogram(fill="#009291", colour="#FFFFFF") +
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
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
  )
  district_list <- c(unique(as.character(ddt_subset()$name)))
  
  #   checkboxGroupInput("district_list", 
  #                      h2("Select District"),
  #                      choices = as.list(district_list),
  #                      selected = c('All'))
  selectInput("district_list", h2("Select District"), as.list(district_list), multiple = T) 
})


output$choose_district <- renderPlot({
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  ddt_subset <- ddt_subset() %>% filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(ddt_subset) > 0, "No districts in given subset")
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
  
  q <- state_base + geom_point(data = ddt_subset, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) #+ #, position = position_jitter(w = 0.07, h = 0.05)) +
  #scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
  
})


output$pop_map <- renderPlot({
  
  
  validate(
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
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
  
  q <- state_base + geom_point(data = ddt_subset(), aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) #+ #, position = position_jitter(w = 0.07, h = 0.05)) +
  #scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
  
  
})

output$gen_map <- renderPlot({
  
  
  validate(
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
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
  
  q <- state_base + geom_point(data = ddt_subset(), aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
                               alpha = 0.7, size = 6) + #, position = position_jitter(w = 0.07, h = 0.05)) +
    scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  
  print(q + coord_map())
  
  
})  


output$goals100k_map <- renderPlot({
  
  validate(
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
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
  #ddt_subset$meeting_2018_goal_no_oversub <- as.factor(ddt_subset$meeting_2018_goal_no_oversub)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + geom_point(data = ddt_subset(), aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 100k/student Goal", 
                                                                                      "Does Not Meet 100k/student Goal"), values = c("#009296", "#CCCCCC"))
  
  
  print(q + coord_map())
  
  
})  


output$goals1M_map <- renderPlot({
  
  validate(
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
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
  
  q <- state_base + geom_point(data = ddt_subset(), aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 1Mbps/student Goal", 
                                                                                      "Does Not Meet 1Mbps/student Goal"), values = c("#A3E5E6", "#CCCCCC")) #+
  
  print(q + coord_map())
  
  
})  






output$unscalable <- renderPlot({
  
  validate(
    need(nrow(ddt_subset()) > 0, "No districts in given subset")
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
  
  
  
  ddt_unscalable <- ddt_subset() %>% filter(percent_scalable_ia != "All Scaleable IA")
  
  q <- state_base + geom_point(data = ddt_unscalable, aes(x = longitude, y = latitude, colour = "Districts with at least \n one non-scalable school"), 
                               alpha = 0.8, size = 6) + scale_color_manual(values = c("#0073B6")) 

  
  print(q + coord_map())
  
  
})  







output$n_ddt <- renderText({
  
  ddt_subset <- ddt_subset()
  paste("n =", toString(nrow(ddt_subset)))
  
})

output$n_ddt2 <- renderText({
  
  ddt_subset <- ddt_subset()
  paste("n =", toString(nrow(ddt_subset)))
  
})

output$n_ddt3 <- renderText({
  
  ddt_subset <- ddt_subset()
  paste("n =", toString(nrow(ddt_subset)))
  
})

output$n_ddt4 <- renderText({
  
  ddt_subset <- ddt_subset()
  paste("n =", toString(nrow(ddt_subset)))
  
})


output$n_ddt5 <- renderText({
  
  ddt_unscalable <- ddt_subset() %>% filter(percent_scalable_ia != "All Scaleable IA")
  paste("n =", toString(nrow(ddt_unscalable)))
  
  
  
})

#For downloadable subsets
datasetInput <- reactive({
  selected_state <- paste0('\"',input$state, '\"')
  selected_bandwidths <- paste0("c(",toString(input$bandwidths), ')')
  
  li_subset <- li2() %>% mutate(band_factor = as.factor(bandwidth_in_mbps)) %>%    
    filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>%
    filter_(paste("bandwidth_in_mbps %in%", selected_bandwidths)) 
  
  validate(
    need(nrow(li_subset) > 0, "No districts in given subset")
  )
  
  li_subset2 <- li2() %>% 
    filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state)))
  
  validate(
    need(nrow(li_subset2) > 0, "No districts in given subset")
  )
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  ddt_subset_specific <- ddt_subset() %>% filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(ddt_subset_specific) > 0, "No districts in given subset")
  )
  
  
  # ddt_subset <- ddt_subset() 
  
  #  validate(
  #    need(nrow(ddt_subset) > 0, "No districts in given subset")
  #  )
  
  
  #ddt_subset_map <- ddt_subset()
  
  switch(input$subset,
         "Line items for B-W" = li_subset,
         "Line items for Comparisons" = li_subset2,
         "Deluxe districts for Selected Districts" = ddt_subset_specific)
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
