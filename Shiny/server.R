# Clear the console
#cat("\014")
# Remove every object in the environment
#rm(list = ls())

#wd <- "~/Desktop/ficher/Shiny"
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
  library(DT)
  library(shinydashboard)
  #library(RPostgreSQL)
  
  #drv <- dbDriver("PostgreSQL")
  #con <- dbConnect(drv, dbname = "daddkut7s5671q",
                 #  host = "ec2-54-204-38-194.compute-1.amazonaws.com", port = 5572,
                #   user = "u3v583a3p2pp85", password = "p6omsea0tv60mlfjnosesb7ereu")
  
  #querydb <- function(query_name) {
   # query <- readChar(query_name, file.info(query_name)$size)
  #  data <- dbGetQuery(con, query)
   # return(data)
  #}
  
  #districts <- querydb("/prep_for_Shiny/SQL/deluxe_districts.SQL")
  
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
             district_size %in% input$district_size_affordability,
             locale %in% input$locale_affordability) %>%
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
    
    #to create independent filters for goals section
   # districts$new_connect_type_goals <- districts$new_connect_type
    districts$district_size2 <- districts$district_size
    districts$locale2 <- districts$locale
    
    #to create independent filters for fiber section
    districts$district_size3 <- districts$district_size
    districts$locale3 <- districts$locale
    
    #to create independent filters for maps section
    districts$new_connect_type_map <- districts$new_connect_type
    
    districts %>% 
      filter_(ifelse(input$dataset == 'All', "1==1", paste("exclude ==", selected_dataset))) %>% 
      filter_(ifelse(input$state == 'All', "1==1", paste("postal_cd ==", selected_state))) #%>% 
      #filter(#new_connect_type %in% input$connection_districts, 
             #district_size %in% input$district_size,
             #locale %in% input$locale,
            # meeting_2014_goal_no_oversub %in% input$meeting_goals)
             
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
       scale_fill_manual(labels = c("Rural", "Small Town", "Suburban", "Urban"), 
                          values = c("#f09300", "#f4b400", "#f7cb4d", "#fce8b2")) +
       geom_hline(yintercept = 0) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
             axis.line.x = element_blank(),
             axis.text.x=element_text(size=14, colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank()) 
    
  print(q)
  
})

output$table_locale <- renderDataTable({
  
  data <- state_subset_locale()
  data$percent <- round(data$percent, 2)
  colnames(data) <- c("Postal Code", "Locale", "# of Districts in Locale", "# of Districts in the State", "% of Districts in Locale")
  
  validate(
    need(input$state != 'All', "")
  )
  
  datatable(data, caption = 'Use the Search bar for the data table below.', options = list(paging = FALSE))
  
  })
  
## size distribution
output$histogram_size <- renderPlot({
  
  data <- state_subset_size()
  
  validate(
    need(input$state != 'All', "Please select your state.")
  )
  
  q <- ggplot(data = data) +
    geom_bar(aes(x = factor(postal_cd), y = percent, fill = district_size), stat = "identity") +
    scale_fill_manual(labels = c("Tiny", "Small", "Medium", "Large", "Mega"), 
                       values = c("#a1887f", "#f09300", "#f4b400", "#f7cb4d", "#fce8b2")) +
    geom_hline(yintercept = 0) +
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
output$table_size <- renderDataTable({
  
  data <- state_subset_size()
  data$percent <- round(data$percent, 2)
  colnames(data) <- c("Postal Code", "District Size", "# of Districts in Size Bucket", "# of Districts in the State", "% of Districts in Size Bucket")
  validate(
    need(input$state != 'All', "")
  )
  
  datatable(data, caption = 'Use the Search bar for the data table below.', 
                   options = list(paging = FALSE))
  
})

######
## Goals Section
######

## Districts and Students Meeting Goals
output$histogram_goals <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                       district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
            summarize(percent_districts_meeting_goals = round(100 * mean(meeting_goals_district), 2),
                      percent_students_meeting_goals = round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
      
  data <- melt(data)

  q <- ggplot(data = data) +
         geom_bar(aes(x = variable, y = value), width = .5, fill="#fdb913", stat = "identity") +
         geom_text(aes(label = paste0(value, "%"), x = variable, y = value), vjust = -1, size = 6) +
         scale_x_discrete(breaks=c("percent_districts_meeting_goals", "percent_students_meeting_goals"),
                     labels=c("Districts", "Students")) +
         scale_y_continuous(limits = c(0, 110)) +
         geom_hline(yintercept = 0) +
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

output$table_goals <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                           district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
          summarize(n = n(),
              percent_districts_meeting_goals = round(100 * mean(meeting_goals_district), 2),
              n_students = sum(num_students),
              percent_students_meeting_goals = round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2))
  colnames(data) <- c("# of districts", "% of districts meeting goals", "# of students", "% of students meeting goals")

  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), options = list(paging = FALSE, searching = FALSE))
  
})

## Districts Meeting Goals, by Technology
output$helptext_ia_technology <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
             set to clean data, relevant state, goal meeting status, connection types, locales, and district sizes."))
})


districts_ia_tech_data <- reactive({
  
  d_ia_tech_data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
  district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals, meeting_2014_goal_no_oversub %in% input$meeting_goals) #%>% 
  #group_by(new_connect_type_goals) %>%
  #summarize(n_districts = n()) %>%
  #mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
         #n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))

  d_ia_tech_data
  
  })

output$histogram_districts_ia_technology <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
            district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals, meeting_2014_goal_no_oversub %in% input$meeting_goals) %>% 
            group_by(new_connect_type_goals) %>%
            summarize(n_districts = n()) %>%
            mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
            n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  q <- ggplot(data = data, aes(x = new_connect_type_goals, y = n_percent_districts)) +
       geom_bar(fill = "#fdb913", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(n_percent_districts, "%")), 
                 vjust = -1, size = 6) +
       scale_y_continuous(limits = c(0, 110)) +
       scale_x_discrete(limits = c("Other / Uncategorized", "Cable", "DSL", "Copper", "Fixed Wireless", "Fiber")) +
       geom_hline(yintercept = 0) +
       theme_classic() + 
       theme(axis.line = element_blank(), 
             axis.text.x=element_text(size=14, colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank()) 
  
  print(q)
  
  #districts_ia_tech <- as.data.frame(data)
  
})

output$table_districts_ia_technology <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
              district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals, 
              meeting_2014_goal_no_oversub %in% input$meeting_goals) %>% 
              group_by(new_connect_type_goals) %>%
              summarize(n_districts = n()) %>%
              mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
              n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))
  
  colnames(data) <- c("IA Connect Category", "# of Districts", "# of Districts in Goal Meeting Status", "% of Districts")
  
  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), caption = 'Use the Search bar for the data table below.', 
                  options = list(paging = FALSE))
  
})

## WAN Goals: Current vs. Projected Needs
output$histogram_projected_wan_needs <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
          district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
          summarize(n_circuits_1g_wan = sum(gt_1g_wan_lines, na.rm = TRUE),
                    n_circuits_lt_1g = sum(lt_1g_fiber_wan_lines + lt_1g_nonfiber_wan_lines, na.rm = TRUE),
                    percent_current_wan_goals = round(100 * n_circuits_1g_wan / (n_circuits_1g_wan + n_circuits_lt_1g), 2),
                    n_schools_with_proj_wan_needs = sum(n_schools_wan_needs, na.rm = TRUE),
                    n_all_schools_in_wan_needs_calculation = sum(n_schools_in_wan_needs_calculation, na.rm = TRUE),
                    percent_schools_with_proj_wan_needs = round(100 * n_schools_with_proj_wan_needs / n_all_schools_in_wan_needs_calculation, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)
  
  #q <- ggplot(data = data[which(data$variable %in% c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs")),],
  #            aes(x = variable, y = value)) +
    
 #   q <- ggplot(data = plot_data) +
#    geom_bar(aes(x = variable, y = value, fill = variable),  width = .5, stat = "identity") +
#    geom_text(aes(label = label, x = variable, y = value), vjust = -1, size = 6) +
    
    q <- ggplot(data = data[which(data$variable %in% c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs")),]) +
       geom_bar(aes(x = variable, y = value, fill=variable), stat = "identity", width = .5) +
        geom_text(aes(label = paste0(value, "%"), x = variable, y = value),  vjust =-1, size = 6) +
        scale_x_discrete(breaks=c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs"),
                     labels=c("Schools with >= 1G WAN", "Schools w/ Projected Need of >= 1G WAN")) +
        scale_y_continuous(limits = c(0, 110)) +
        scale_fill_manual(values = c("#fdb913", "#f26b21")) + 
        geom_hline(yintercept = 0) +
        theme_classic() + 
        theme(axis.line = element_blank(), 
              axis.text.x=element_text(size=14, colour= "#899DA4"), 
              axis.text.y = element_blank(),
              axis.ticks = element_blank(),
              axis.title.x=element_blank(),
              axis.title.y=element_blank(),
              legend.position = "none") 
      
  print(q)
  
})

output$table_projected_wan_needs <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                   district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
          summarize(n_circuits_1g_wan = sum(gt_1g_wan_lines, na.rm = TRUE),
                    n_circuits_lt_1g = sum(lt_1g_fiber_wan_lines + lt_1g_nonfiber_wan_lines, na.rm = TRUE),
                    percent_current_wan_goals = round(100 * n_circuits_1g_wan / (n_circuits_1g_wan + n_circuits_lt_1g), 2),
                    n_schools_with_proj_wan_needs = sum(n_schools_wan_needs, na.rm = TRUE),
                    n_all_schools_in_wan_needs_calculation = sum(n_schools_in_wan_needs_calculation, na.rm = TRUE),
                    percent_schools_with_proj_wan_needs = round(100 * n_schools_with_proj_wan_needs / n_all_schools_in_wan_needs_calculation, 2))
  colnames(data) <- c("# of >=1G WAN circuits", "# of <1G WAN circuits", "current WAN goals %", "# of schools w/ projected WAN need", "# of schools in WAN need calculation", "% of schools w/ projected WAN need")
  #print(names(data))
  
  validate(need(nrow(data) > 0, ""))
  
  datatable(format(data, big.mark = ",", scientific = FALSE), options = list(paging = FALSE, searching = FALSE))
  
})

## Median Pricing Districts Not Meeting vs. Meeting Goals
output$hypothetical_ia_price  <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                       district_size2 %in% input$district_size_goals, 
                                       locale2 %in% input$locale_goals)
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  cost_data <- data %>%
               group_by(meeting_2014_goal_no_oversub) %>%
               summarize(n_districts = n(),
                         median_monthly_ia_cost_per_mbps = round(median(monthly_ia_cost_per_mbps, na.rm = TRUE), 2))
  
  # Price
  plot_data <- cost_data[, c(1,3)]
  names(plot_data) <- c("variable", "value")
  plot_data$label <- paste0("$", plot_data$value)
  
  #plot_data <- rbind(plot_data2, plot_data1)
  
  q <- ggplot(data = plot_data) +
         geom_bar(aes(x = variable, y = value, fill = variable),  width = .5, stat = "identity") +
         geom_text(aes(label = label, x = variable, y = value), vjust = -1, size = 6) +
         scale_y_continuous(limits = c(0, 1.1 * max(plot_data$value))) +
         scale_x_discrete(limits = c("Not Meeting 2014 Goals", "Meeting 2014 Goals")) +
         scale_fill_manual(values = c("#fdb913", "grey")) + 
         geom_hline(yintercept = 0) +
         theme_classic() + 
         theme(legend.position = "none",
           axis.line = element_blank(), 
            axis.text.x = element_text(size=14, colour= "#899DA4"), 
            axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 

  print(q)
})

output$hypothetical_ia_goal <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                       district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) 
  
  validate(need(nrow(data) > 0, ""))
  
  cost_data <- data %>%
    group_by(meeting_2014_goal_no_oversub) %>%
    summarize(n_districts = n(),
              median_monthly_ia_cost_per_mbps = round(median(monthly_ia_cost_per_mbps, na.rm = TRUE), 2))
  
  current_pricing_percent_district_meeting_goals <- round(mean(100 * data$meeting_goals_district, na.rm = TRUE), 2)
  
  hypothetical_cost <- cost_data[cost_data$meeting_2014_goal_no_oversub == "Meeting 2014 Goals", ]$median_monthly_ia_cost_per_mbps
  
  not_meeting <- which(data$meeting_2014_goal_no_oversub == "Not Meeting 2014 Goals")
  
  data$hypothetical_kbps_per_student <- (1000 * (data$total_ia_monthly_cost / hypothetical_cost)) / data$num_students
  
  # for districts not meeting goals, replace their current bw with the hypothetical number
  data[not_meeting, ]$ia_bandwidth_per_student <- data[not_meeting, ]$hypothetical_kbps_per_student
  data$new_meeting_goals_district <- ifelse(data$ia_bandwidth_per_student >= 100, 1, 0)
  
  hypothetical_district_meeting_goals <- round(100 * mean(data$new_meeting_goals_district, na.rm = TRUE), 2)
  
  # Goal %
  plot_data1 <- as.data.frame(cbind(current_pricing_percent_district_meeting_goals, hypothetical_district_meeting_goals))
  names(plot_data1) <- c("% Districts \nCurrently Meeting Goals", "% Districts Meeting Goals \nUnder Ideal Pricing")
  plot_data1 <- melt(plot_data1)
  plot_data1$label <- paste0(plot_data1$value, "%")
  
  goals <- ggplot(data = plot_data1) +
    geom_bar(aes(x = variable, y = value), fill = "#fdb913", width = .5, stat = "identity") +
    geom_text(aes(label = label, x = variable, y = value), vjust = -1, size = 6) +
    scale_y_continuous(limits = c(0, 110)) +
    scale_x_discrete(breaks = c("% Districts \nCurrently Meeting Goals", "% Districts Meeting Goals \nUnder Ideal Pricing"), 
                     labels = c("% Districts \nCurrently Meeting Goals", "% Districts Meeting Goals \nUnder Median Meeting 2014 Goals Pricing")) +
    geom_hline(yintercept = 0) +
    theme_classic() + 
    theme(axis.line = element_blank(), 
          axis.text.x = element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  print(goals)
})

output$table_hypothetical_ia_goal <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                       district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) 
  cost_data <- data %>%
    group_by(meeting_2014_goal_no_oversub) %>%
    summarize(n_districts = n(),
              median_monthly_ia_cost_per_mbps = round(median(monthly_ia_cost_per_mbps, na.rm = TRUE), 2))
  
  current_pricing_percent_district_meeting_goals <- round(mean(100 * data$meeting_goals_district, na.rm = TRUE), 2)
  hypothetical_cost <- cost_data[cost_data$meeting_2014_goal_no_oversub == "Meeting 2014 Goals", ]$median_monthly_ia_cost_per_mbps
  not_meeting <- which(data$meeting_2014_goal_no_oversub == "Not Meeting 2014 Goals")
  data$hypothetical_kbps_per_student <- (1000 * (data$total_ia_monthly_cost / hypothetical_cost)) / data$num_students
  
  # for districts not meeting goals, replace their current bw with the hypothetical number
  data[not_meeting, ]$ia_bandwidth_per_student <- data[not_meeting, ]$hypothetical_kbps_per_student
  data$new_meeting_goals_district <- ifelse(data$ia_bandwidth_per_student >= 100, 1, 0)
  
  hypothetical_district_meeting_goals <- round(100 * mean(data$new_meeting_goals_district, na.rm = TRUE), 2)
  
  plot_data1 <- as.data.frame(cbind(current_pricing_percent_district_meeting_goals, hypothetical_district_meeting_goals))
  names(plot_data1) <- c("% Districts \nCurrently Meeting Goals", "% Districts Meeting Goals Under Median Meeting 2014 Goals Pricing")
  plot_data1 <- melt(plot_data1)
  plot_data1$label <- paste0(plot_data1$value, "%")
  
  plot_data <- cost_data[, c(1,3)]
  names(plot_data) <- c("variable", "value")
  plot_data$label <- paste0("$", plot_data$value)
  
  table_data <- as.data.frame(rbind(plot_data, plot_data1))
  table_data[which(table_data$variable == "Meeting 2014 Goals"),]$variable <- "Median Cost per Mbps for Districts Meeting IA Goal"
  table_data[which(table_data$variable == "Not Meeting 2014 Goals"),]$variable <- "Median Cost per Mbps for Districts Not Meeting IA Goal"
  table_data$value <- NULL
  datatable(table_data, options = list(paging = FALSE, searching = FALSE))
  
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
  
  data1 <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
                                        locale3 %in% input$locale_fiber)
  
  data <- data1 %>% 
          summarize(num_all_schools = sum(num_schools),
                   num_schools_on_fiber = sum(schools_on_fiber),
                   num_schools_may_need_upgrades = sum(schools_may_need_upgrades),
                   num_schools_need_upgrades = sum(schools_need_upgrades),
                   percent_on_fiber = round(100 * num_schools_on_fiber / num_all_schools, 2),
                   percent_may_need_upgrades = round(100 * num_schools_may_need_upgrades / num_all_schools, 2),
                   percent_need_upgrades = round(100 * num_schools_need_upgrades / num_all_schools, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)
  
  q <- ggplot(data = data[which(data$variable %in% c("percent_on_fiber", "percent_may_need_upgrades", "percent_need_upgrades")), ],
              aes(x = variable, y = value)) +
       geom_bar(fill="#009291", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(value, "%")), vjust =-1, size = 6) +
       scale_x_discrete(breaks=c("percent_on_fiber", "percent_may_need_upgrades", "percent_need_upgrades"),
                     labels=c("Have Fiber", "May Need Upgrades", "Need Upgrades")) +
       scale_y_continuous(limits = c(0, 110)) +
       geom_hline(yintercept = 0) +
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
output$table_schools_on_fiber <- renderDataTable({
  
  data <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
                                           locale3 %in% input$locale_fiber) %>% 
    
      summarize(num_all_schools = sum(num_schools),
                num_schools_on_fiber = sum(schools_on_fiber),
                num_schools_may_need_upgrades = sum(schools_may_need_upgrades),
                num_schools_need_upgrades = sum(schools_need_upgrades),
                percent_on_fiber = round(100 * num_schools_on_fiber / num_all_schools, 2),
                percent_may_need_upgrades = round(100 * num_schools_may_need_upgrades / num_all_schools, 2),
                percent_need_upgrades = round(100 * num_schools_need_upgrades / num_all_schools, 2))
    
  colnames(data) <- c("# of Schools", "# of Schools on Fiber", "# of Schools That May Need Upgrades", 
                      "# of Schools That Need Upgrades", "% of Schools on Fiber", "% of Schools That May Need Upgrades", "% of Schools That Need Upgrades")
        
  validate(need(nrow(data) > 0, ""))  
  
  datatable(format(data, big.mark = ",", scientific = FALSE), options = list(paging = FALSE, searching = FALSE))
  
})

## Districts - E-rate Discount Rates

output$helptext_by_erate_discounts <- renderUI({
  HTML(paste("User Note:  When using this view for Gov Preps/Connectivity Reports, check that the filters are
             set to clean data, relevant state, goal meeting status, connection types, locales, and district sizes."))
})



output$histogram_by_erate_discounts <- renderPlot({
  
  
  data <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
                                 locale3 %in% input$locale_fiber) %>% 
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
          summarize(n_unscalable_schools_in_rate_band = sum(schools_need_upgrades + schools_may_need_upgrades)) %>%
          mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
                 percent_unscalable_schools_in_rate_band = round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2))

  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  

  q <- ggplot(data = data, aes(x = as.factor(c1_discount_rate), y = percent_unscalable_schools_in_rate_band)) +
       geom_bar(fill="#009291", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(percent_unscalable_schools_in_rate_band, "%")), vjust = -1, size = 6) +
       scale_y_continuous(limits = c(0, 110)) +
       geom_hline(yintercept = 0) +
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
output$table_by_erate_discounts <- renderDataTable({
  
  data <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
                                           locale3 %in% input$locale_fiber) %>% 
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
    summarize(n_unscalable_schools_in_rate_band = round(sum(schools_need_upgrades + schools_may_need_upgrades))) %>%
    mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
           percent_unscalable_schools_in_rate_band = round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2))
  
  colnames(data) <- c("C1 Discount Rate", "# of Unscalable Schools in Discount Rate Group", "# of All Unscalable Schools in Calculation", "% of Unscalable Schools in Discount Rate Group") 
    
  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), options = list(paging = FALSE, searching = FALSE))
  
})



######
 ## Affordability Section
######
 
## Box and Whiskers Plots

output$bw_plot <- renderPlot({
  
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
               fill="#009291", stat = "identity", width = .5) +
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
# District Lookup

output$helptext_leaflet_map <- renderUI({
  HTML(paste("User Note: Useful for District Callouts. Type in your districts of interest."))
})




output$districtSelect <- renderUI({
  
  districtSelect_data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  validate(
    need(nrow(districtSelect_data) > 0, "No districts in given subset")
  )
  
#  #district_list <- c(unique(as.character(districtSelect_data$name)))
  district_list <- c(unique(as.character(districtSelect_data$name)), "SELECT ALL") #made global

    #"district_list"
  selectizeInput("testing", h2("Input District Name(s)"), as.list(district_list), multiple = TRUE, options = list(placeholder = 'e.g. Cave Creek Unified District')) 

  })


#observe({
#  if ("SELECT ALL" %in% input$districtSelect) {
   # # choose all the choices _except_ "Select All"
    #selected_choices <- setdiff(district_list, "SELECT ALL")
    #selectizeInput(session, "districtSelect", choices = as.list(district_list), selected = selected_choices)
  #}
#})

output$selected <- renderText({
  paste(input$testing, collapse = ", ")
})



##Trying leaflet: 
#observe({
school_districts <- eventReactive(input$testing, {
  d <- district_subset() %>% filter(name %in% input$testing)
  d %>% select(name = name, X = longitude, Y = latitude, num_students, hierarchy_connect_category, total_ia_monthly_cost)
  #dp <- as.data.frame(data_points)
})  
  
output$testing_leaflet <- renderLeaflet({ 
  
  sd_info <- paste0("<b>", school_districts()$name, "</b><br>",
                    "# of students:", format(school_districts()$num_students, big.mark = ",", scientific = FALSE),"<br>",
                    "IA Connection: ", school_districts()$hierarchy_connect_category, "<br>",
                    "Total IA monthly cost: $", format(school_districts()$total_ia_monthly_cost, big.mark = ",", scientific = FALSE))
  
  
  
  leaflet() %>% addProviderTiles("CartoDB.Positron") %>% addMarkers(data = school_districts(), lng = ~X, lat = ~Y, popup = ~paste(sd_info))#%>% addMarkers(data = d, lng = ~longitude, lat = ~latitude, popup = ~name) #popup = ~paste(content)) 
  #default view of leaflet map is addTiles()
})

#})



output$choose_district <- renderPlot({
  
  choose_district_data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')))
  
  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  
  choose_district_data <- choose_district_data %>% 
          filter_(paste("name %in%", selected_district_list))
  
  validate(
    need(nrow(choose_district_data) > 0, "No districts in given subset")
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
       geom_point(data = choose_district_data, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 6) 
  
  print(q + coord_map())
  
  
})

# map of districts 
output$map_population <- renderPlot({
  
  data <- district_subset() %>%
          filter(!(postal_cd %in% c('AK', 'HI')), 
                 new_connect_type_map %in% input$connection_districts,
                 district_size %in% input$district_size_maps,
                 locale %in% input$locale_maps)
  
  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  #hdf <- get_map(state_name, source = 'stamen', maptype = 'toner', zoom = 7, crop = FALSE)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    #ggmap(hdf) +
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
    theme_classic() +
    theme(line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.text = element_text(size=16), legend.position= "bottom") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude), colour = c("#0073B6"),
                               alpha = 0.7, size = 4)
  
    
  qq <- q + coord_map()
  
  r <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#0073B6", "#CCCCCC"))
  rr <- r + coord_map()
  
  
  s <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 100kbps/Student Goal", 
                                                                      "Does Not Meet 100kbps/Student Goal"), values = c("#CCCCCC", "#CB2027"))
  ss <- s + coord_map()
  
  t <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 1Mbps/Student Goal", 
                                                                      "Does Not Meet 1Mbps/Student Goal"), values = c("#CCCCCC", "#CB2027")) #+
  
  tt <- t + coord_map()
  
  ddt_unscalable <- data %>% 
    filter(not_all_scalable == 1)
  
  u <- state_base + 
    geom_point(data = ddt_unscalable, 
               aes(x = longitude, y = latitude, colour = as.factor(zero_build_cost_to_district)),
               alpha = 0.8, size = 4) +
    scale_color_manual(values = c("#A3E5E6", "#0073B6"), 
                       breaks = c(0, 1), labels = c("Upgrade at partial cost \n to district", "Upgrade at no cost \n to district \n"))
  
  uu <- u + coord_map()
  
  switch(input$map_view,
         "General" = print(qq),
         "Clean/Dirty" = print(rr),
         'Goals: 100kbps/Student' = print(ss),
         'Goals: 1Mbps/Student' = print(tt),
         'Fiber Build Cost to Districts' = print(uu))
  
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


#not using ggvis since side-by-side bar chart is not possible
general_monthly_cpm <- reactive({
  sr_all() %>% 
    ggvis(~monthly_cost_per_mbps) %>% 
    layer_histograms(width = 50, fill := "#009296", fillOpacity := 0.4)
  
})

general_monthly_cpm %>% bind_shiny("gen_m_cpm")


#not using ggvis since side-by-side bar chart is not possible
price_disp_cpc <- reactive({

  a <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
                 summarise(p25th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE),
                           Median = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE),
                           p75th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE))
  
   
   bw <- "bandwidth_in_mbps"
   percentile <- "percentiles"
   dispersion <- c("p25th", "Median", "p75th")
   
   b <- gather_(a, bw, percentile, dispersion)
   colnames(b) <- c("bw_mbps", "percentile", "cost" )
   print(b)
  
    data <- sr_all() %>% filter(bandwidth_in_mbps == unique(bandwidth_in_mbps[1]))
    data$monthly_cost_per_circuit <- as.numeric(as.character(data$monthly_cost_per_circuit))
    percentiles <- quantile(data$monthly_cost_per_circuit, c(.25, .50, .75), na.rm = TRUE)  
    perc_tab <- as.data.frame(percentiles)  
    add_perc <- c("25th","Median", "75th")
    bw_mbps <- c(rep(data$bandwidth_in_mbps[1], 3)) #added for TESTING 
    perc_tab <- cbind(perc_tab, add_perc, bw_mbps)
    perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
    #perc_tab_cpc <- perc_tab
    #print(perc_tab_cpc)
    
    if(length(unique(data$bandwidth_in_mbps)) > 1){ 
        data2 <- data %>% filter(bandwidth_in_mbps == unique(bandwidth_in_mbps[2]))
        data2$monthly_cost_per_circuit <- as.numeric(as.character(data2$monthly_cost_per_circuit))
        percentiles <- quantile(data2$monthly_cost_per_circuit, c(.25, .50, .75), na.rm = TRUE)  
        perc_tab2 <- as.data.frame(percentiles)  
        add_perc <- c("25th","Median", "75th")
        bw_mbps2 <- c(rep(data2$bandwidth_in_mbps[2], 3))
        perc_tab2 <- cbind(perc_tab2, add_perc, bw_mbps2)
        perc_tab2$add_perc <- factor(perc_tab2$add_perc, levels = perc_tab2$add_perc[1:3], labels = c("25th", "Median", "75th"))
        perc_tab_cpc2 <- perc_tab2
        print(unique(data2$bandwidth_in_mbps))
        print(perc_tab_cpc2)
        
     data3 <- rbind(perc_tab_cpc, perc_tab_cpc2)    
     #data3 <- left_join(perc_tab_cpc, perc_tab_cpc2, by = c("add_perc" = "add_perc2"))
     print(data3)
    }

    else{
    perc_tab %>% 
    ggvis(x = ~add_perc, y = ~percentiles, fill := "#FDB913", fillOpacity := 0.6) %>% 
    group_by(add_perc) %>% 
    layer_bars(strokeWidth := 0) %>%    
    layer_rects(fill:="white") %>%
    add_axis("x", title = "Percentile", title_offset = 50, grid=FALSE) %>% 
      # commented out title fyi
    #add_axis("x", orient = "top", title = "Price Dispersion: Monthly Cost Per Circuit",
     #          properties = axis_props(axis = list(stroke = "white"), labels = list(fontSize = 0)), 
      #         grid=FALSE)  %>% 
    add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75, grid=FALSE)
    #hide_axis("y")
    }
  
})

price_disp_cpc %>% bind_shiny("price_disp_cpc")








output$cpc_sidebars <- renderPlot({

  a <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
       summarise(p25th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE),
                 Median = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE),
                 p75th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE))
  
  
  bw <- "bandwidth_in_mbps"
  percentile <- "percentiles"
  dispersion <- c("p25th", "Median", "p75th")
  
  b <- gather_(a, bw, percentile, dispersion)
  colnames(b) <- c("bw_mbps", "percentile", "cost" )
  b$percentile <- factor(b$percentile, levels = c("p25th", "Median", "p75th"))
  print(b)

  positions <- c("p25th", "Median", "p75th")
  v <- ggplot(data = b, aes(x=percentile, y=cost, fill=factor(bw_mbps)))+
    geom_bar(stat="identity", position = "dodge") + 
    geom_text(aes(label = format(round(cost, digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE)), vjust = -0.5, position = position_dodge(width = 0.9), size = 5) +
    #scale_x_discrete(limits = positions) +
    scale_x_discrete(breaks=c("Median", "p25th", "p75th"),
                        labels=c("Median", "25th", "75th")) +
                        #guide = guide_legend(title = "Bandwidth Speed (Mbps)")) +
    scale_fill_brewer(palette = "Blues", direction = -1) +
    geom_hline(yintercept = 0) +
    theme_classic() + 
    theme(axis.line = element_blank(), 
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  print(v)

})

#output$n_sr <- renderText({
  
#  n_sr <- nrow(sr_all())
#  n_circuits <- sum(sr_all()$cat.1_allocations_to_district)
#  paste("n(services) =", toString(n_sr))
  
#})


#output$n_circuits <- renderText({

#  n_circuits <- sum(sr_all()$cat.1_allocations_to_district)
#  paste("n(circuits) =", toString(n_circuits))
  
#})


output$disp_cpc_table <- renderDataTable({
  
  #data <- sr_all()
  #data$monthly_cost_per_circuit <- as.numeric(as.character(data$monthly_cost_per_circuit))
  #percentiles <- quantile(data$monthly_cost_per_circuit, c(.25, .50, .75), na.rm = TRUE)  
  #perc_tab <- as.data.frame(percentiles)  
  #add_perc <- c("25th","Median", "75th")
  #perc_tab <- cbind(add_perc, perc_tab)
  #perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
  #colnames(perc_tab) <- c("Percentile", "Monthly Cost Per Circuit ($)")
  
  
  perc_tab <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
              summarise(n_services = n(),
              n_circuits = sum(cat.1_allocations_to_district),
              p25th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              Median = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              p75th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""))
  colnames(perc_tab)<- c("Circuit Size (Mbps)" ,"# of Line Items", "# of Circuits", "25th", "Median", "75th")
  
  datatable(perc_tab, options = list(paging = FALSE, searching = FALSE))

})



#price_disp_cpm <- reactive({
  
#  data <- sr_all()
#  data$monthly_cost_per_mbps <- as.numeric(as.character(data$monthly_cost_per_mbps))
#  percentiles <- quantile(data$monthly_cost_per_mbps, c(.25, .50, .75), na.rm = TRUE)  
#  perc_tab <- as.data.frame(percentiles)  
#  add_perc <- c("25th","Median", "75th")
#  perc_tab <- cbind(perc_tab, add_perc)
#  perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
  
#  print(str(perc_tab))
  
#  perc_tab %>% 
#    ggvis(x = ~add_perc, y = ~percentiles, fill := "#009296", fillOpacity := 0.6) %>% 
#    layer_bars(strokeWidth := 0) %>%    
#    layer_rects(fill:="white") %>%
#    add_axis("x", title = "Percentile", title_offset = 50, grid = FALSE) %>% 
#    add_axis("y", title = "Monthly Cost per Mbps ($)", title_offset = 75, grid = FALSE)
#  #hide_axis("y")
  
#})

#price_disp_cpm %>% bind_shiny("price_disp_cpm")

output$price_disp_cpm_sidebars <- renderPlot({
  
  c <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
    summarise(p25th = quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.25, na.rm = TRUE),
              Median = quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.50, na.rm = TRUE),
              p75th = quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.75, na.rm = TRUE))
  
  
  bw <- "bandwidth_in_mbps"
  percentile <- "percentiles"
  dispersion <- c("p25th", "Median", "p75th")
  
  b2 <- gather_(c, bw, percentile, dispersion)
  colnames(b2) <- c("bw_mbps", "percentile", "cost" )
  b2$percentile <- factor(b2$percentile, levels = c("p25th", "Median", "p75th"))
  print(b2)
  
  positions <- c("p25th", "Median", "p75th")
  v <- ggplot(data = b2, aes(x=percentile, y=cost, fill=factor(bw_mbps)))+
    geom_bar(stat="identity", position = "dodge") + 
    geom_text(aes(label = format(round(cost, digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE)), vjust = -0.5, position = position_dodge(width = 0.9), size = 5) +
    #scale_x_discrete(limits = positions) +
    scale_x_discrete(breaks=c("Median", "p25th", "p75th"),
                     labels=c("Median", "25th", "75th")) +
    #guide = guide_legend(title = "Bandwidth Speed (Mbps)")) +
    scale_fill_brewer(palette = "BuGN", direction = -1) +
    geom_hline(yintercept = 0) +
    theme_classic() + 
    theme(axis.line = element_blank(), 
          axis.text.x=element_text(size=14, colour= "#899DA4"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()) 
  
  print(v)
  
})



output$disp_cpm_table <- renderDataTable({
#data <- sr_all()
#data$monthly_cost_per_mbps <- as.numeric(as.character(data$monthly_cost_per_mbps))
#percentiles <- quantile(data$monthly_cost_per_mbps, c(.25, .50, .75), na.rm = TRUE)  
#perc_tab <- as.data.frame(percentiles)  
#add_perc <- c("25th","Median", "75th")
#perc_tab <- cbind(add_perc, perc_tab)
#perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
#colnames(perc_tab) <- c("Percentile", "Monthly Cost Per Mbps ($)")

  perc_tab <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
    summarise(n_services = n(),
              n_circuits = sum(cat.1_allocations_to_district),
              p25th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.25, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              Median = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.50, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              p75th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.75, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""))
  colnames(perc_tab)<- c("Circuit Size (Mbps)" ,"# of Line Items", "# of Circuits", "25th", "Median", "75th")
  
  
  datatable(perc_tab, options = list(paging = FALSE, searching = FALSE))

  })

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
    if(length(unique(sr_all()$bandwidth_in_mbps)) == 1){
      
      starting_pt <- unique(sr_all()$bandwidth_in_mbps) * 2
      
      sr_all() %>% 
        ggvis(x = ~bandwidth_in_mbps, y = ~monthly_cost_per_circuit) %>% 
        layer_points(size.hover := 200, fill = ~factor(bandwidth_in_mbps),
                     fillOpacity := 0.4, fillOpacity.hover := 0.75,
                     key := ~recipient_name) %>% 
        add_tooltip(district_tooltip, "hover")  %>%
        add_axis("x", title = "Bandwidth in Mbps", title_offset = 50, grid = FALSE) %>% 
        add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75, grid = FALSE) %>% 
        scale_numeric("x", domain = c(0, starting_pt)) %>% 
        set_options(width = 800, height = 500)
    }  
  
  
    else{
    sr_all() %>% 
    ggvis(x = ~bandwidth_in_mbps, y = ~monthly_cost_per_circuit) %>% 
    layer_points(size := 100, size.hover := 200, fill = ~factor(bandwidth_in_mbps),
               fillOpacity := 0.4, fillOpacity.hover := 0.75,
                key := ~recipient_name) %>% 
    add_tooltip(district_tooltip, "hover")  %>%
    add_axis("x", title = "Bandwidth in Mbps", title_offset = 50, grid = FALSE) %>% 
    add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75, grid = FALSE) %>% 
    set_options(width = 800, height = 500)
    }
  
})

vis %>% bind_shiny("plot1")


output$plot1_table <- renderDataTable({
  
  datatable(sr_all())
  
})







output$n_ddt <- renderText({
  
  data <- district_subset() %>%
    filter(!(postal_cd %in% c('AK', 'HI')),
           new_connect_type_map %in% input$connection_districts,
           district_size %in% input$district_size_maps,
           locale %in% input$locale_maps)
  
    data2 <- data %>%
      filter(not_all_scalable == 1)
    
  switch(input$map_view,
         "General" =  paste("n(districts) =", toString(nrow(data))),
         "Clean/Dirty" =  paste("n(districts) =", toString(nrow(data))),
         'Goals: 100kbps/Student' =  paste("n(districts) =", toString(nrow(data))),
         'Goals: 1Mbps/Student' =  paste("n(districts) =", toString(nrow(data))),
         'Fiber Build Cost to Districts' = paste("n(districts) =", toString(nrow(data2))))
})

#output$map_tables <- renderDataTable({
#  map_data <- district_subset() %>%
#    filter(!(postal_cd %in% c('AK', 'HI')),
#           district_size %in% input$district_size_maps,
#           locale %in% input$locale_maps)
  
  
  
#  map_data2 <- data %>%
#    filter(not_all_scalable == 1)
  
  
#  switch(input$map_view,
#         "General" =  datatable(map_data),
#         "Clean/Dirty" =  datatable(map_data),
#         'Goals: 100kbps/Student' =  datatable(map_data),
#         'Goals: 1Mbps/Student' =  datatable(map_data),
#         'Fiber Build Cost to Districts' = datatable(map_data2))

#})




#creating reset functionality for each tab:

#goals section
observeEvent(input$goals_reset_all, {
  reset("goals_filters")
})

#fiber section
observeEvent(input$fiber_reset_all,{
  reset("fiber_filters")
})

#affordability section
observeEvent(input$affordability_reset_all,{
  reset("affordability_filters")
})

#maps section
observeEvent(input$map_reset_all, {
  reset("map_filters")
})






#For downloadable subsets:
output$ia_tech_downloadData <- downloadHandler(
  filename = function(){
    paste('districts_by_ia_tech_dataset', '_20160617', '.csv', sep = '')},
  content = function(file){
    write.csv(districts_ia_tech_data(), file)
  }
)


output$affordability_downloadData <- downloadHandler(
  filename = function(){
    paste('affordability_dataset', '_', Sys.Date(), '.csv', sep = '')},
  content = function(file){
    write.csv(sr_all(), file)
  }
)


#output$map_downloadData <- downloadHandler(
#  filename = function(){
#    paste('map_dataset', '_', Sys.Date(), '.csv', sep = '')},
#  content = function(file){
#    write.csv(district_subset(), file)
#  }
#)


####################################

datasetInput_maps <- reactive({
  
  data <- district_subset() %>%
    filter(!(postal_cd %in% c('AK', 'HI')),
           new_connect_type_map %in% input$connection_districts,
           district_size %in% input$district_size_maps,
           locale %in% input$locale_maps)
  
  data2 <- data %>%
    filter(not_all_scalable == 1)
    
    switch(input$map_view,
        "General" =  data,
        "Clean/Dirty" =  data,
        'Goals: 100kbps/Student' =  data,
        'Goals: 1Mbps/Student' =  data,
        'Fiber Build Cost to Districts' = data2)
  
})

output$table_testing <- renderDataTable({
  map_data <- district_subset() %>%
    filter(!(postal_cd %in% c('AK', 'HI')),
           new_connect_type_map %in% input$connection_districts,
           district_size %in% input$district_size_maps,
           locale %in% input$locale_maps)
  
  
  
  map_data2 <- map_data %>%
    filter(not_all_scalable == 1)
  
  
  switch(input$map_view,
         "General" =  datatable(map_data),
         "Clean/Dirty" =  datatable(map_data),
         'Goals: 100kbps/Student' =  datatable(map_data),
         'Goals: 1Mbps/Student' =  datatable(map_data),
         'Fiber Build Cost to Districts' = datatable(map_data2))
  
})

output$downloadData <- downloadHandler(
  filename = function(){
    paste(input$map_view, '_', Sys.Date(), '.csv', sep = '')},
  content = function(file){
    write.csv(datasetInput_maps(), file)
  }
)


####################################


}) #closing shiny server function
