# Clear the console
#cat("\014")
# Remove every object in the environment
#rm(list = ls())

#wd <- "~/Google Drive/github/ficher/Shiny"
#setwd(wd)

shinyServer(function(input, output, session) {
  
  ## Create reactive functions for both services received and districts table ##
  ## Note: it is necessary to create two separate reactive datasets for box-and-whiskers (b-w) plot 
  ## and other price comparison plots since b-w plot is limited to popular bandwidths
  
  ## General Line Items for national comparison (national vs. state) and
  ## also one state vs. all other states
  library(shiny)
  library(tidyr)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(grid)
  library(maps)
  library(ggmap)
  library(reshape)
  library(leaflet)
  library(ggvis)
  
  #sapply(lib, function(x) library(x, character.only = TRUE))
  #services <- querydb("~/Google Drive/github/ficher/Shiny/prep_for_Shiny/SQL/services_received.SQL")
  #districts <- querydb("~/Google Drive/github/ficher/Shiny/prep_for_Shiny/SQL/deluxe_districts.SQL")
  services <- read.csv("services_received_shiny.csv", as.is = TRUE)
  districts <- read.csv("districts_shiny.csv", as.is = TRUE)
  locale_cuts <- read.csv("locale_cuts.csv", as.is = TRUE)
  size_cuts <- read.csv("size_cuts.csv", as.is = TRUE)
 
  # factorize
  services$band_factor <- as.factor(services$band_factor)
  services$postal_cd <- as.factor(services$postal_cd)
  locale_cuts$locale <- factor(locale_cuts$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
  size_cuts$district_size <- factor(size_cuts$district_size, levels = c("Mega", "Large", "Medium", "Small", "Tiny"))
  
  # state lookup
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

  ##Main data set to use to any Services Recieved related work: 
  output$bandwidthSelect <- renderUI({
    #sr_data <- sr_all()
    sr_data <- services
    bandwidth_list <- c(unique(sr_data$bandwidth_in_mbps))
    selectizeInput("bandwidth_list", h2("Input Bandwidth Circuit Speed(s) (in Mbps)"), as.list(sort(bandwidth_list)), multiple = T, options = list(placeholder = 'e.g. 100'))
  })
  
  sr_all <- reactive({
    selected_state <- paste0('\"',input$state, '\"')
    selected_bandwidth_list <- paste0(input$bandwidth_list)
    selected_bandwidth_list <- as.numeric(selected_bandwidth_list)
    
    services %>% 
      filter(new_purpose %in% input$purpose,
             new_connect_type %in% input$connection_services,
             district_size %in% input$district_size,
             locale %in% input$locale) %>%
      filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>% 
      filter(bandwidth_in_mbps %in% selected_bandwidth_list)
  })  

  ######
  ## reactive functions for ESH Sample section
  ######
  
  state_subset_locale <- reactive({
    
    # only include options for state selection
    #  selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    sample <- paste0(input$state, " Clean")
    
    locale_cuts %>% 
      filter(postal_cd %in% c(input$state, sample))
    
  })
  
  state_subset_size <- reactive({
    
    # only include options for state selection
    #  selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    sample <- paste0(input$state, " Clean")
    
    size_cuts %>% 
      filter(postal_cd %in% c(input$state, sample))
  })
  
##Keep as main reactive function using district deluxe table
district_subset <- reactive({
      
    selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')

    districts %>% 
      filter_(ifelse(input$dataset == 'All', "1==1", paste("exclude ==", selected_dataset))) %>% 
      filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) %>% 
      filter(new_connect_type %in% input$connection_districts, 
             district_size %in% input$district_size,
             locale %in% input$locale,
             meeting_2014_goal_no_oversub %in% input$meeting_goals)#,
             
  })

# districts not meeting vs. meeting goals:  hypothetical median cost / student goal meeting percentage
hypothetical_median_cost <- reactive({

  districts %>% 
    filter_(ifelse(input$dataset == 'All', "1==1", paste("exclude ==", selected_dataset))) %>% 
    filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) 
  
})

####### OUTPUTS

######
## ESH Sample Dropdown
######

## locale distribution
output$histogram_locale <- renderPlot({
  
  data <- state_subset_locale()
  
  validate(
    need(input$state != 'All', "Please select your state.")
  )
  
  q <- ggplot(data = data) +
       geom_bar(aes(x = factor(postal_cd), y = percent, fill = locale), stat = "identity") +
       theme_classic() + 
       theme(axis.line = element_blank(), 
             axis.text.x=element_text(size=14, colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank()) 
    
  print(q)
  
})

output$table_locale <- renderTable({
  
  data <- state_subset_locale()
  
  validate(
    need(input$state != 'All', "")
  )
  
  data
  
  })
  
## size distribution
output$histogram_size <- renderPlot({
  
  data <- state_subset_size()
  
  validate(
    need(input$state != 'All', "Please select your state.")
  )
  
  q <- ggplot(data = data) +
    geom_bar(aes(x = factor(postal_cd), y = percent, fill = district_size), stat = "identity") +
    theme_classic() + 
    theme(axis.line = element_blank(), 
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  
  print(q)
  
  
})


## size distribution table
output$table_size <- renderTable({
  
  data <- state_subset_size()
  
  validate(
    need(input$state != 'All', "")
  )
  
  data
  
})

######
## Goals Section
######

## Districts and Students Meeting Goals
output$histogram_goals <- renderPlot({
  
  data <- district_subset() %>%
            summarize(n = n(),
                      percent_districts_meeting_goals = round(100 * mean(meeting_goals_district), 2),
                      percent_students_meeting_goals = round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)

  q <- ggplot(data = data[-which(data$variable == "n"), ]) +
         geom_bar(aes(x = variable, y = value), fill="#fdb913", stat = "identity") +
         geom_text(aes(label = paste0(value, "%"), x = variable, y = value), vjust = -1, size = 6) +
         scale_y_continuous(limits = c(0, 100)) +
         theme_classic() + 
         theme(axis.line = element_blank(), 
                axis.text.x=element_text(size=14, colour= "#899DA4"), 
                axis.text.y = element_blank(),
                axis.ticks = element_blank(),
                axis.title.x=element_blank(),
                axis.title.y=element_blank()) 
      
  print(q)
  
})

## Table of numbers in districts / students meeting goals

# Help text for Histogram on Meeting Goals
output$helptext_goals <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
set to ", "<b>", "clean", "</b>", "data, relevant", "<b>", "state", "</b>", ",and", "<b>", 
              "inclusive", "</b>", "of all connection types, locales, and district sizes."))
})

output$table_goals <- renderTable({
  
  data <- district_subset() %>%
           summarize(n = n(),
              percent_districts_meeting_goals = round(100 * mean(meeting_goals_district), 2),
              percent_students_meeting_goals = round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2))
  
  validate(need(nrow(data) > 0, ""))  
  data

})

## Districts Meeting Goals, by Technology
output$helptext_ia_technology <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
             set to clean data, relevant state, goal meeting status, connection types, locales, and district sizes."))
})

output$histogram_districts_ia_technology <- renderPlot({
  
  data <- district_subset() %>%
            group_by(hierarchy_connect_category) %>%
            summarize(n_districts = n()) %>%
            mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
            n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  q <- ggplot(data = data, aes(x = hierarchy_connect_category, y = n_percent_districts)) +
       geom_bar(fill = "#fdb913", stat = "identity") +
       geom_text(aes(label = paste0(n_percent_districts, "%")), 
                 vjust = -1, size = 6) +
       scale_y_continuous(limits = c(0, 100)) +
       scale_x_discrete(limits = c("Other/Uncategorized", "Cable", "DSL", "Copper", "Fixed Wireless", "Fiber")) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
             axis.text.x=element_text(size=14, colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank()) 
  
  print(q)
  
})

output$table_districts_ia_technology <- renderTable({
  
  data <- district_subset() %>%
              group_by(hierarchy_connect_category) %>%
              summarize(n_districts = n()) %>%
              mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
              n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))
  
  validate(need(nrow(data) > 0, ""))  
  data
  
})

## WAN Goals: Current vs. Projected Needs
output$histogram_projected_wan_needs <- renderPlot({
  
  data <- district_subset() %>%
          summarize(n_circuits_1g_wan = sum(gt_1g_wan_lines, na.rm = TRUE),
                    n_circuits_lt_1g = sum(lt_1g_fiber_wan_lines + lt_1g_nonfiber_wan_lines, na.rm = TRUE),
                    percent_current_wan_goals = round(100 * n_circuits_1g_wan / (n_circuits_1g_wan + n_circuits_lt_1g), 2),
                    n_schools_with_proj_wan_needs = sum(n_schools_wan_needs, na.rm = TRUE),
                    n_all_schools_in_wan_needs_calculation = sum(n_schools_in_wan_needs_calculation, na.rm = TRUE),
                    percent_schools_with_proj_wan_needs = round(100 * n_schools_with_proj_wan_needs / n_all_schools_in_wan_needs_calculation, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)
  
  q <- ggplot(data = data[which(data$variable %in% c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs")),],
              aes(x = variable, y = value)) +
       geom_bar(fill="#fdb913", stat = "identity") +
        geom_text(aes(label = paste0(value, "%")), 
                  vjust =-1, size = 6) +
        scale_y_continuous(limits = c(0, 100)) +
        theme_classic() + 
        theme(axis.line = element_blank(), 
              axis.text.x=element_text(size=14, colour= "#899DA4"), 
              axis.text.y = element_blank(),
              axis.ticks = element_blank(),
              axis.title.x=element_blank(),
              axis.title.y=element_blank()) 
      
  print(q)
  
})

output$table_projected_wan_needs <- renderTable({
  
  data <- district_subset() %>%
          summarize(n_circuits_1g_wan = sum(gt_1g_wan_lines, na.rm = TRUE),
                    n_circuits_lt_1g = sum(lt_1g_fiber_wan_lines + lt_1g_nonfiber_wan_lines, na.rm = TRUE),
                    percent_current_wan_goals = round(100 * n_circuits_1g_wan / (n_circuits_1g_wan + n_circuits_lt_1g), 2),
                    n_schools_with_proj_wan_needs = sum(n_schools_wan_needs, na.rm = TRUE),
                    n_all_schools_in_wan_needs_calculation = sum(n_schools_in_wan_needs_calculation, na.rm = TRUE),
                    percent_schools_with_proj_wan_needs = round(100 * n_schools_with_proj_wan_needs / n_all_schools_in_wan_needs_calculation, 2))
        
  
  validate(need(nrow(data) > 0, ""))
  
  data
  
})

## Median Pricing Districts Not Meeting vs. Meeting Goals
output$histogram_hypothetical_median_cost <- renderPlot({
  
  data <- district_subset() 
  
  cost_data <- data %>%
               group_by(meeting_2014_goal_no_oversub) %>%
               summarize(n_districts = n(),
                         median_monthly_ia_cost_per_mbps = round(median(monthly_ia_cost_per_mbps, na.rm = TRUE), 2))
  
  current_pricing_percent_district_meeting_goals <- round(mean(100 *data$meeting_goals_district, na.rm = TRUE), 2)
  
  hypothetical_cost <- cost_data[cost_data$meeting_2014_goal_no_oversub == "Meeting 2014 Goals", ]$median_monthly_ia_cost_per_mbps
  
  not_meeting <- which(data$meeting_2014_goal_no_oversub == "Not Meeting 2014 Goals")
  
  data$hypothetical_kbps_per_student <- (1000 * (data$total_ia_monthly_cost / hypothetical_cost)) / data$num_students
  
  # for districts not meeting goals, replace their current bw with the hypothetical number
  data[not_meeting, ]$ia_bandwidth_per_student <- data[not_meeting, ]$hypothetical_kbps_per_student
  data$new_meeting_goals_district <- ifelse(data$ia_bandwidth_per_student >= 100, 1, 0)
  
  hypothetical_pricing_percent_district_meeting_goals <- round(100 * mean(data$new_meeting_goals_district, na.rm = TRUE), 2)
  
  plot_data1 <- as.data.frame(cbind(current_pricing_percent_district_meeting_goals, hypothetical_pricing_percent_district_meeting_goals))
  plot_data1 <- melt(plot_data1)
  plot_data1$label <- paste0(plot_data1$value, "%")
  
  plot_data2 <- cost_data[, c(1,3)]
  names(plot_data2) <- c("variable", "value")
  plot_data2$label <- paste0(plot_data2$value, "$")
  plot_data <- rbind(plot_data2, plot_data1)
  
    q <- ggplot(data = data) +
       geom_bar(aes(x = meeting_2014_goal_no_oversub, y = median_monthly_ia_cost_per_mbps), fill="#009291", stat = "identity") +
       scale_x_discrete(limits = c("Not Meeting 2014 Goals", "Meeting 2014 Goals")) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
             axis.text.x=element_text(size=14, colour= "#899DA4"), 
             axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  
  print(q)
  
})

output$table_hypothetical_median_cost <- renderTable({
  
  data <- hypothetical_median_cost()
  
})

output$table_hypothetical_median_cost2 <- renderTable({
  
  data <- hypothetical_median_cost()
  
})


## Median Pricing Districts Not Meeting vs. Meeting Goals
output$histogram_hypothetical_ia_goal <- renderPlot({
  
  
  q <- ggplot(data = plot_data) +
    geom_bar(aes(x = variable, y = value), fill="#009291", stat = "identity") +
  #  scale_x_discrete(limits = c("Not Meeting 2014 Goals", "Meeting 2014 Goals")) +
    theme_classic() + 
    theme(axis.line = element_blank(), 
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  
  print(q)
  
})


output$table_hypothetical_ia_goal <- renderTable({
  
    cost <- hypothetical_median_cost()
    data <- hypothetical_ia_goal()
    
    hypothetical_cost <- cost[cost$meeting_2014_goal_no_oversub == "Meeting 2014 Goals", ]$median_monthly_ia_cost_per_mbps
    
    current_pricing_percent_district_meeting_goals <- round(100 * mean(data$meeting_goals_district, na.rm = TRUE), 2)
    
    not_meeting <- which(data$meeting_2014_goal_no_oversub == "Not Meeting 2014 Goals")
    
    data$hypothetical_kbps_per_student <- (1000 * (data$total_ia_monthly_cost / hypothetical_cost)) / data$num_students
    
    # for districts not meeting goals, replace their current bw with the hypothetical number
    data[not_meeting, ]$ia_bandwidth_per_student <- data[not_meeting, ]$hypothetical_kbps_per_student
    data$new_meeting_goals_district <- ifelse(data$ia_bandwidth_per_student >= 100, 1, 0)
    
    hypothetical_pricing_percent_district_meeting_goals <- round(100 * mean(data$new_meeting_goals_district, na.rm = TRUE), 2)
    
    plot_data <- as.data.frame(cbind(current_pricing_percent_district_meeting_goals, hypothetical_pricing_percent_district_meeting_goals))
    plot_data <- melt(plot_data)
    
  
})

######
## Fiber Section
######

output$helptext_schools_on_fiber <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
             set to clean data, relevant state, goal meeting status, connection types, locales, and district sizes."))
})


## Districts and Students Meeting Goals
output$histogram_schools_on_fiber <- renderPlot({
  
  data <- district_subset() %>%
          summarize(num_schools = sum(num_campuses),
                    num_schools_on_fiber = sum(nga_v2_known_scalable_campuses + nga_v2_assumed_scalable_campuses),
                    num_schools_may_need_upgrades = sum(nga_v2_assumed_unscalable_campuses),
                    num_schools_need_upgrades = sum(nga_v2_known_unscalable_campuses),
                    percent_on_fiber = round(100 * num_schools_on_fiber / sum(num_campuses), 2),
                    percent_may_need_upgrades = round(100 * num_schools_may_need_upgrades / sum(num_campuses), 2),
                    percent_need_upgrades = round(100 * num_schools_need_upgrades / sum(num_campuses), 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)
  
  q <- ggplot(data = data[which(data$variable %in% c("percent_on_fiber", "percent_may_need_upgrades", "percent_need_upgrades")), ],
              aes(x = variable, y = value)) +
       geom_bar(fill="#009291", stat = "identity") +
       geom_text(aes(label = paste0(value, "%")), vjust =-1, size = 6) +
       scale_y_continuous(limits = c(0, 100)) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
            axis.text.x=element_text(size=14, colour= "#899DA4"), 
            axis.text.y = element_blank(),
            axis.ticks = element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank()) 
    
  print(q)
  
})

## Table on distribution of schools by infrastructure type
output$table_schools_on_fiber <- renderTable({
  
  data <- district_subset() %>%
          summarize(num_schools = sum(num_campuses),
                    num_schools_on_fiber = sum(nga_v2_known_scalable_campuses + nga_v2_assumed_scalable_campuses),
                    num_schools_may_need_upgrades = sum(nga_v2_assumed_unscalable_campuses),
                    num_schools_need_upgrades = sum(nga_v2_known_unscalable_campuses),
                    percent_on_fiber = round(100 * num_schools_on_fiber / sum(num_campuses), 2),
                    percent_may_need_upgrades = round(100 * num_schools_may_need_upgrades / sum(num_campuses), 2),
                    percent_need_upgrades = round(100 * num_schools_need_upgrades / sum(num_campuses), 2))
        
  validate(need(nrow(data) > 0, ""))  
  
  data
  
})

## Districts - E-rate Discount Rates

output$helptext_by_erate_discounts <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
             set to clean data, relevant state, goal meeting status, connection types, locales, and district sizes."))
})



output$histogram_by_erate_discounts <- renderPlot({
  
  
  data <- district_subset() %>%
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
          summarize(n_unscalable_schools_in_rate_band = n()) %>%
          mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
                 percent_unscalable_schools_in_rate_band = round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2))

  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  

  q <- ggplot(data = data, aes(x = as.factor(c1_discount_rate), y = percent_unscalable_schools_in_rate_band)) +
       geom_bar(fill="#009291", stat = "identity") +
       geom_text(aes(label = paste0(percent_unscalable_schools_in_rate_band, "%")), vjust =-1, size = 6) +
       scale_y_continuous(limits = c(0, 100)) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  
  print(q)
  
})

## Table on distribution of schools by infrastructure type
output$table_by_erate_discounts <- renderTable({
  
  data <- district_subset() %>%
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
          summarize(n_unscalable_schools_in_rate_band = n()) %>%
          mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
                 percent_unscalable_schools_in_rate_band = round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2))
        
  validate(need(nrow(data) > 0, ""))  
  data
  
})



######
 ## Affordability Section
######
 
## Box and Whiskers Plots

output$bw_plot <- renderPlot({
  
  #data <- li_bf()
  #validate(need(nrow(data) > 0, "No circuits in given subset"))
  
  data <- sr_all()
  
  #give.n <- function(x){
  #  return(c(y = median(x) * 0.85, label = length(x))) 
  #  # experiment with the multiplier to find the perfect position
  #}
  
  #meds <- data %>% 
  #        group_by(band_factor) %>% 
  #        summarise(medians = round(median(monthly_cost_per_circuit, na.rm = TRUE), 2))
  
  #dollar_format(largest_with_cents=1)
  
  #ylim1 <- boxplot.stats(data$monthly_cost_per_circuit)$stats[c(1, 5)]   #column 1 and 5 are min and max
  
  p0 <- ggplot(data, aes(x = factor(bandwidth_in_mbps), y = monthly_cost_per_circuit)) + 
        geom_boxplot(fill="#009291", colour="#ABBFC6", outlier.colour=NA, width=.5) 
  #+ stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 5) 
      
  a <- p0 + 
     #  coord_cartesian(ylim = ylim1 * 2.0) + 
     # scale_y_continuous("", labels = dollar) +
     # geom_text(data = meds, aes(x = band_factor, y = medians, label = dollar(medians)), 
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

  data <- sr_all()
  
  data %>% 
    group_by(band_factor) %>% 
    summarise(num_line_items = n(), 
              num_circuits = sum(line_item_total_num_lines))
  
})

output$prices_table <- renderTable({
  

  data <- sr_all()
  
  data %>% 
    group_by(band_factor) %>% 
    summarise(min_cost_per_mbps = round(min(monthly_cost_per_mbps, na.rm = TRUE), 2),
              q25_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.25, na.rm = TRUE), 2),
              median_cost_per_mbps = round(median(monthly_cost_per_mbps, na.rm = TRUE), 2),
              q75_cost_per_mbps = round(quantile(monthly_cost_per_mbps, 0.75, na.rm = TRUE), 2),
              max_cost_per_mbps = round(max(monthly_cost_per_mbps, na.rm = TRUE), 2))
  
})


output$histogram_cost_comparison_by_state <- renderPlot({
  
  data <- sr_all()
  
  plot_data <- data %>%
               group_by(postal_cd) %>%
               summarize(median_cost = median(monthly_cost_per_circuit, na.rm = TRUE))
        
  validate(
    need(nrow(data) > 0, "No district in given subset; please adjust your selection")
  )
  
  validate(
    need(input$state == 'All', "Please adjust your state selection to 'All.'")
  )
  
  q <- ggplot(data = plot_data) +
      geom_bar(aes(x = reorder(factor(postal_cd), median_cost), y = median_cost), 
               fill="#009291", stat = "identity") +
      theme_classic() + 
      theme(axis.line = element_blank(), 
            axis.text.x=element_text(size=14, colour= "#899DA4"), 
            axis.text.y = element_blank(),
            axis.ticks = element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank()) 
    
  print(q)
  
  
})

output$table_cost_comparison_by_state <- renderTable({
  
  data <- sr_all()
  
  plot_data <- data %>%
    group_by(postal_cd) %>%
    summarize(median_cost = round(median(monthly_cost_per_circuit, na.rm = TRUE), 2))
  
  validate(
    need(nrow(data) > 0, "")
  )
  
  plot_data ## 
  
})

## Comparison: Specific State vs. the Rest of the States 
#output$state_vs_rest_comparison <- renderPlot({
  
  #excluding the state that is specifically being compared to rest of the nation
 # data <- li_all() 
  
  #levels(data$postal_cd) <- c(levels(data$postal_cd), "National Excluding Selected State")
  #data$postal_cd[data$postal_cd != input$state] <- "National Excluding Selected State"
  
 
  ##### NOTE: This causes as warning: "Warning in Ops.factor(left, right) : ???>??? not meaningful for factors"
  #validate(
  #  need(nrow(data > 0), "No circuits in given subset")
  #)
  #####
  
  #give.n <- function(x){
  #  return(c(y = median(x) * 0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  #}
  
  #p0 <- ggplot(data, aes(x=postal_cd, y = monthly_cost_per_circuit)) + 
   #     geom_boxplot(fill = "#009291", colour = "#ABBFC6", outlier.colour = NA, width = .5) 
     #   stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
      
  #ylim1 <- boxplot.stats(data$monthly_cost_per_circuit)$stats[c(1, 5)]

#  meds <- data %>% 
 #         group_by(postal_cd) %>% 
  #        summarise(medians = median(monthly_cost_per_circuit))
  
  #dollar_format(largest_with_cents = 1)
  
  #b <- p0 + 
   #   coord_cartesian(ylim = ylim1 * 2.0) +
    #  scale_y_continuous("",labels = dollar) +
     # geom_text(data = meds, aes(x = postal_cd, y = medians, label = dollar(medians)), 
      #          size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) +
      #theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
       #     panel.background = element_blank(), axis.line = element_blank(), 
        #    axis.text.x = element_text(size = 14, colour = "#899DA4"), 
         #   axis.text.y = element_text(size = 14, colour = "#899DA4"),
          #  axis.ticks = element_blank(),
           # axis.title.x = element_blank(),
            #axis.title.y = element_blank())
    #print(b)
  #)


#output$n_observations_comparison <- renderTable({
  
 # data <- li_all() 
  
  #data$postal_cd[data$postal_cd != input$state] <- c('National Excluding Selected State')
  #data$postal_cd <- as.factor(data$postal_cd)
  
#  ns <- data %>% 
 #       group_by(postal_cd) %>% 
  #      summarise(num_line_items = n(),
   #               num_circuits = sum(line_item_total_num_lines))
#})

# Overall National Comparison
#output$overall_national_comparison <- renderPlot({
  
  #excluding the state that is specifically being compared to rest of the nation
 # data <- li_all()
  
  ##### NOTE: This causes as warning: "Warning in Ops.factor(left, right) : ???>??? not meaningful for factors"
#  validate(
 #   need(nrow(data > 0), "No circuits in given subset")
#  )
  #####
  
 # give.n <- function(x){
#    return(c(y = median(x) * 0.85, label = length(x))) 
    # experiment with the multiplier to find the perfect position
  #}
 # 
 # p0 <- ggplot() + #changed x = postal_cd to x="All"
  #      geom_boxplot(data = data, aes(x = national, y = monthly_cost_per_circuit),
   #                  fill = "#009291", colour = "#ABBFC6", outlier.colour = NA, width = .5) +
    #    stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) +
     #   geom_boxplot(data = data[data$postal_cd == input$state,], aes(x = postal_cd, y = monthly_cost_per_circuit), 
                     #fill="#009291", colour = "#ABBFC6", outlier.colour=NA, width=.5) +
        #stat_summary(fun.data = give.n, geom = "text", fun.y = median, size = 4) 
  
  #ylim1 <- boxplot.stats(data$monthly_cost_per_circuit)$stats[c(1, 5)]
  
  #national_median <- data %>% 
   #                  group_by(national) %>%  
    #                 summarise(medians = round(median(monthly_cost_per_circuit, na.rm = TRUE)))
  #state_median <-    data %>% 
   #                  group_by(postal_cd) %>% 
    #                 filter(postal_cd == input$state) %>% 
     #                summarise(medians = round(median(monthly_cost_per_circuit, na.rm = TRUE)))
  #dollar_format(largest_with_cents=1)
  
  #b <- p0 + 
   #    coord_cartesian(ylim = ylim1 * 1.05) +
    #   scale_y_continuous("", labels = dollar) +
     #  geom_text(data = national_median, aes(x = national, y = medians, label = dollar(medians)), 
      #           size = 6, vjust = 0, colour = "#F26B21", hjust=0.5) + 
      # geom_text(data = state_median, aes(x = postal_cd, y = medians, label = dollar(medians)), 
        #         size = 6, vjust = 0, colour= "#F26B21", hjust=0.5) + 
       #theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
         #    panel.background = element_blank(), axis.line = element_blank(), 
          #   axis.text.x=element_text(size=14, colour= "#899DA4"), 
           #  axis.text.y=element_text(size=14, colour= "#899DA4"),
            # axis.ticks=element_blank(),
             #axis.title.x=element_blank(),
             #axis.title.y=element_blank())
       #print(b)
  #})

## n's for overall national comparison
#output$national_n_table <- renderTable({
  
 # data <- li_all() 
  
  #data %>% 
   # group_by(national) %>% 
    #summarise(num_line_items = n(), 
     #         num_circuits = sum(line_item_total_num_lines))
  
#})

#output$state_n_table <- renderTable({
  
 # selected_state <- paste0('\"',input$state, '\"')
  
#  data <- li_all() %>%
  #        filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) 
  
  #data %>% 
   # group_by(postal_cd) %>% 
    #summarise(num_line_items = n(), 
     #         num_circuits = sum(line_item_total_num_lines))
  
#})

###### 
## Maps
######


output$districtSelect <- renderUI({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  district_list <- c(unique(as.character(data$name)))
  
  selectizeInput("district_list", h2("Input District Name(s)"), as.list(district_list), multiple = T, options = list(placeholder = 'e.g. Cave Creek Unified District')) 
})

output$choose_district <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  
  data <- data %>% 
          filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position=c(0.5, 0.5)) +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) 
  
  print(q + coord_map())
  
  
})

# map of districts in population 
output$map_population <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position=c(0.5, 0.5)) +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) #+ #, position = position_jitter(w = 0.07, h = 0.05)) +
  #scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  #scale_color_manual(values = colors)
  print(q + coord_map())
  
})

output$map_cleanliness <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
                               alpha = 0.7, size = 6) + #, position = position_jitter(w = 0.07, h = 0.05)) +
       scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC")) #+
  
  print(q + coord_map())
  
  
})  

output$map_2014_goals <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(need(nrow(data) > 0, "No districts in given subset"))
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)

  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 100k/student Goal", 
                                                                                      "Does Not Meet 100k/student Goal"), values = c("#009296", "#CCCCCC"))
  
  print(q + coord_map())
  
})  

output$map_2018_goals <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(need(nrow(data) > 0, "No districts in given subset"))
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position="bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
                               alpha = 0.7, size = 6) + scale_color_manual(labels = c("Meets 1Mbps/student Goal", 
                                                                                      "Does Not Meet 1Mbps/student Goal"), values = c("#A3E5E6", "#CCCCCC")) #+
  
  print(q + coord_map())
  
})  

# Map of Districts at least 1 Unscalable School
output$map_fiber_needs <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  # limit to districts that have at least one unscalable campus
  ddt_unscalable <- data %>% 
                    filter(not_all_scalable == 1)

  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size = 16), legend.position = "bottom") +
    guides(shape = guide_legend(override.aes=list(size = 7))) 
  
  q <- state_base + 
       geom_point(data = ddt_unscalable, 
                  aes(x = longitude, y = latitude, colour = as.factor(zero_build_cost_to_district)),
                 alpha = 0.8, size = 6) +
       scale_color_manual(values = c("#A3E5E6", "#0073B6"), 
                          breaks = c(0, 1), labels = c("Upgrade at partial cost \n to district", "Upgrade at no cost \n to district \n"))
    
  print(q + coord_map())
  
  
})  

# Price Dispersion Map holding Circuit Size / Technology Constant
# automatic update -- not quite working out
#output$map_price_dispersion_automatic <- renderPlot({
  
 # data <- li_map()
  # data <- data[!is.na(data$bubble_size_beta), ]   # remove those outside of common bandwidths
  
  #validate(
   # need(nrow(data) > 0, "No districts in given subset")
  #)

  #state_name <- state_lookup$name[state_lookup$code == input$state] 
  #state_df <- map_data("county", region = state_name)
  
  #set.seed(123) #to control jitter
  #state_base <-  ggplot(data = state_df, aes(x = long, y = lat)) + 
  #  geom_polygon(data = state_df, aes(x = long, y = lat, group = group),
   #              color = 'black', fill = NA) +
  #  theme_classic() +
  #  theme(line = element_blank(), title = element_blank(), 
   #       axis.text.x = element_blank(), axis.text.y = element_blank())
  #                      legend.text = element_text(size = 16), legend.position = "bottom") 
  # guides(shape = guide_legend(override.aes = list(size = 7))) 
  
  #q <- state_base + 
  #  geom_point(data = data, aes(x = longitude, y = latitude, 
   #                             size = factor(bubble_size), 
    #                            order = factor(price_bucket)),
     #          colour = "#009692", alpha = 0.7,  position = position_jitter(w = 0.07, h = 0.05)) +
    #scale_size_manual(values = data$bubble_size, 
     #                 limits = data$bubble_size, 
      #                label = data$price_bucket) + 
    #guides(col = guide_legend(nrow = 5)) 
    #ggtitle("100 mbps Lit Fiber IA Price Dispersion\n(Filters are inactive in this view)\n\n\n")
  #     theme(legend.position="bottom")
  
  #print(q + coord_map())
  #})  


general_monthly_cpm <- reactive({
  sr_all() %>% 
    ggvis(~monthly_cost_per_mbps) %>% 
    layer_histograms(width = 50, fill := "#009296", fillOpacity := 0.4)
  
})

general_monthly_cpm %>% bind_shiny("gen_m_cpm")

price_disp_cpc <- reactive({

    data <- sr_all()
    data$monthly_cost_per_circuit <- as.numeric(as.character(data$monthly_cost_per_circuit))
    percentiles <- quantile(data$monthly_cost_per_circuit, c(.25, .50, .75), na.rm = TRUE)  
    perc_tab <- as.data.frame(percentiles)  
    add_perc <- c("25th","Median", "75th")
    perc_tab <- cbind(perc_tab, add_perc)
    perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
 
    print(str(perc_tab))
  
    perc_tab %>% 
    ggvis(x = ~add_perc, y = ~percentiles, fill := "#FDB913", fillOpacity := 0.6) %>% 
    layer_bars(strokeWidth := 0) %>%    
    layer_rects(fill:="white") %>%
    add_axis("x", title = "Percentile", title_offset = 50) %>% 
    add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75)
    #hide_axis("y")
  
})

price_disp_cpc %>% bind_shiny("price_disp_cpc")


price_disp_cpm <- reactive({
  
  data <- sr_all()
  data$monthly_cost_per_mbps <- as.numeric(as.character(data$monthly_cost_per_mbps))
  percentiles <- quantile(data$monthly_cost_per_mbps, c(.25, .50, .75), na.rm = TRUE)  
  perc_tab <- as.data.frame(percentiles)  
  add_perc <- c("25th","Median", "75th")
  perc_tab <- cbind(perc_tab, add_perc)
  perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
  
  print(str(perc_tab))
  
  perc_tab %>% 
    ggvis(x = ~add_perc, y = ~percentiles, fill := "#009296", fillOpacity := 0.6) %>% 
    layer_bars(strokeWidth := 0) %>%    
    layer_rects(fill:="white") %>%
    add_axis("x", title = "Percentile", title_offset = 50) %>% 
    add_axis("y", title = "Monthly Cost per Mbps ($)", title_offset = 75)
  #hide_axis("y")
  
})

price_disp_cpm %>% bind_shiny("price_disp_cpm")

output$helptext_price_cpc <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that filters are set
             to clean data, relevant state, connection types, and bandwidth in mbps."))
})

output$helptext_price_cpm <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that filters are set
             to clean data, relevant state, connection types, and bandwidth in mbps."))
})

output$helptext_price_cpm_scatter <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that filters are set
             to clean data, relevant state, connection types, and bandwidth in mbps."))
})

# Function for generating tooltip text
#output$bandwidthSelect <- renderUI({
#  sr_data <- sr_all()
#  bandwidth_list <- c(unique(sr_data$bandwidth_in_mbps))
#  selectInput("bandwidth_list", h2("Select Bandwidth Speeds (in Mbps)"), as.list(sort(bandwidth_list)), multiple = T)
#})


district_tooltip <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.null(x$recipient_name)) return(NULL)
  all_sr <- isolate(sr_all())
  services_rec <- all_sr[all_sr$recipient_name == x$recipient_name,]
  
  paste0("<b>", "District Name: ", services_rec$recipient_name, "</b><br>",
         "Monthly Cost per Circuit: $", format(services_rec$monthly_cost_per_circuit, big.mark = ",", scientific = FALSE),"<br>",
         "# of Circuits: ", services_rec$quantity_of_lines_received_by_district, "<br>",
         "Connect Type: ", services_rec$connect_type, "<br>")
}

vis <- reactive({

    sr_all() %>% 
    ggvis(x = ~bandwidth_in_mbps, y = ~monthly_cost_per_circuit) %>% 
    layer_points(size := 100, size.hover := 200, fill = ~factor(bandwidth_in_mbps),
               fillOpacity := 0.4, fillOpacity.hover := 0.75,
                key := ~recipient_name) %>% 
    add_tooltip(district_tooltip, "hover")  %>%
    add_axis("x", title = "Bandwidth in Mbps", title_offset = 50) %>% 
    add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75) %>% 
    set_options(width = 800, height = 500)

  
})

vis %>% bind_shiny("plot1")

# District Lookup



##Trying leaflet: 
output$testing_leaflet <- renderLeaflet({
  
  data <- district_subset()
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  
  d <- data %>% 
    filter_(paste("name %in%", selected_district_list))
  
  content <- paste0("<b>", d$name, "</b><br>",
                   "# of students:", format(d$num_students, big.mark = ",", scientific = FALSE),"<br>",
                   "IA Connection: ", d$hierarchy_connect_category, "<br>",
                   "Total IA monthly cost: $", format(d$total_ia_monthly_cost, big.mark = ",", scientific = FALSE)
  )
  
  leaflet() %>% 
    addTiles() %>% 
    addMarkers(data = d, lng = ~longitude, lat = ~latitude, popup = ~paste(content)) 

})




output$n_ddt <- renderText({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  paste("n(districts) =", toString(nrow(data)))
  
})

output$n_ddt2 <- renderText({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  paste("n(districts) =", toString(nrow(data)))
  
})

output$n_ddt3 <- renderText({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  paste("n(districts) =", toString(nrow(data)))
  
})

output$n_ddt4 <- renderText({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  paste("n(districts) =", toString(nrow(data)))
  
})

output$n_ddt5 <- renderText({
  
  data <- district_subset() %>% 
          filter(!(postal_cd %in% c('AK', 'HI'))) %>%
          filter(not_all_scalable == 1)
  paste("n(districts) =", toString(nrow(data)))
  
})

#For downloadable subsets

datasetInput <- reactive({
  
  district_data <- district_subset()
  line_data <- sr_all()               
  
 #validate(
#  need(nrow(district_subset()) > 0, "No districts in given subset")
# )
  
#  validate(
 #  need(nrow(sr_all()) > 0, "No line items in given subset")
 # )
  
  
  #selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  #district_subset_specific <- district_subset() %>% filter_(paste("name %in%", selected_district_list))
  
  #validate(
   # need(nrow(district_subset_specific) > 0, "No districts in given subset")
  #)
  
  switch(input$download_dataset,
         "districts_table" = district_data,
         "line_items_table" = line_data)
  
})

output$table <- renderTable({
  
  datasetInput()
  
})

output$downloadData <- downloadHandler(
  filename = function(){
    paste(input$download_dataset, '_', Sys.Date(), '.csv', sep = '')},
  content = function(file){
    write.csv(datasetInput(), file)
  }
)

}) #closing shiny server function
