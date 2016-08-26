# Clear the console
#cat("\014")
# Remove every object in the environment
#rm(list = ls())

#wd <- "~/Desktop/ficher/Shiny"
#setwd(wd)

#install.packages("shiny")
#install.packages("tidyr")
#install.packages("dplyr")
#install.packages("ggplot2")
#install.packages("scales")
#install.packages("maps")
#install.packages("ggmap")
#install.packages("reshape")
#install.packages("leaflet")
#install.packages("ggvis")
#install.packages("DT")
#install.packages("shinydashboard")
#install.packages("extrafontdb")
#install.packages("extrafont")

shinyServer(function(input, output, session) {
  
  ## Create reactive functions for both services received and districts table ##
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
  library(extrafontdb)
  library(extrafont)
  
  
  #library(RPostgreSQL)
  
  #font_import(pattern="[L/l]ato")
  #font_import(pattern="MuseoSlabW01-700")

  loadfonts()
  
  services <- read.csv("services_received_shiny.csv", as.is = TRUE)
  districts <- read.csv("districts_shiny.csv", as.is = TRUE)
  locale_cuts <- read.csv("locale_cuts.csv", as.is = TRUE)
  size_cuts <- read.csv("size_cuts.csv", as.is = TRUE)
 
  # factorize columns as needed
  services$postal_cd <- as.factor(services$postal_cd)
  districts$new_connect_type_goals <- factor(districts$new_connect_type_goals, 
                                             levels = c("Other / Uncategorized", "Cable", "DSL",
                                                        "Copper", "Fixed Wireless", "Fiber"))
  
  # locale and size cuts
  locale_cuts$locale <- factor(locale_cuts$locale, levels = c("Rural", "Small Town", "Suburban", "Urban"))
  size_cuts$district_size <- factor(size_cuts$district_size, levels = c("Tiny", "Small", "Medium", "Large", "Mega"))
  
    # state lookup
  state_lookup <- data.frame(cbind(name = c('All', 'alabama', 'alaska', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
                                            'deleware', 'florida', 'georgia', 'hawaii', 'idaho', 'illinois', 'indiana',
                                            'iowa', 'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts',
                                            'michigan', 'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire', 'new jersey',
                                            'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
                                            'pennsylvania', 'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
                                            'utah', 'vermont', 'virginia', 'washington', 'west virginia', 'wisconsin', 'wyoming'),
                                   
                                   code = c('.', 'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', "FL", 
                                            "GA", 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 
                                            'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
                                            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
                                            'UT', 'VT', 'VA', 'WA', 'WV', 'WI', "WY")), stringsAsFactors = F)

  ##Main data set to use to any Services Recieved related work: 
  output$bandwidthSelect <- renderUI({
    sr_data <- services
    bandwidth_list <- c(unique(services$bandwidth_in_mbps))

    selectizeInput("bandwidth_list", h2("Select Circuit Size(s) (in Mbps)"), as.list(sort(bandwidth_list)), multiple = T, options = list(placeholder = 'e.g. 100'))
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
    # selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    sample <- paste0(input$state, " Clean")
    
    size_cuts %>% 
      filter(postal_cd %in% c(input$state, sample))
    
  })
  
##Keep as main reactive function using district deluxe table
district_subset <- reactive({
      
    selected_dataset <- paste0('\"', input$dataset, '\"')
    selected_state <- paste0('\"',input$state, '\"')
    
    districts$district_size2 <- districts$district_size
    districts$locale2 <- districts$locale
    
    #to create independent filters for fiber section
    districts$district_size3 <- districts$district_size
    districts$locale3 <- districts$locale
    
    #to create independent filters for maps section
    districts$new_connect_type_map <- districts$new_connect_type_goals
    
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
       geom_bar(aes(x = factor(postal_cd), y = percent, fill = factor(locale)), stat = "identity") +
       scale_fill_manual(name = "",
                         #labels = c("Rural", "Small Town", "Suburban", "Urban"), 
                         values = c("#f26b23", "#f09221", "#fdb913", "#fff1d0")) +
                          #values = c("#fff1d0", "#fdb913", "#f09221", "#f26b23")) +
       geom_hline(yintercept = 0, colour= "#899DA4") +
       theme(plot.background = element_rect(fill = "white"),
             panel.background = element_rect(fill = "white"),
             legend.background = element_rect(fill = "white"),
             axis.line = element_blank(), 
             axis.line.x = element_blank(),
             axis.text.x=element_text(size=14), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank(),
             text=element_text(size = 18, family="Lato")) +
        guides(fill=guide_legend(
                    keywidth = 0.35,
                    keyheight = 0.35,
                    default.unit = "inch"))
    
  print(q)
  
})

output$table_locale <- renderDataTable({
  
  data <- state_subset_locale()
  validate(
    need(input$state != 'All', "")
  )

  data$percent <- paste0(round(data$percent, 2), "%")
  data <- data %>% 
          group_by(postal_cd) %>% 
          arrange(locale)
          select(data, postal_cd, locale, n_districts_locale, n_districts,
                 n_schools, n_students)
  
  colnames(data) <- c("Postal Code", "Locale", "% of Districts in Locale", 
                      "# of Districts in Locale", "# of Districts in the State", "# of Schools in the State",
                      "# of Students in the State")
  
  datatable(format(data, big.mark = ",", scientific = FALSE), caption = 'Use the Search bar for the data table below.', rownames = FALSE, options = list(paging = FALSE))

  })
  
## size distribution
output$histogram_size <- renderPlot({
  
  data <- state_subset_size()
  
  validate(
    need(input$state != 'All', "Please select your state.")
  )
  
  q <- ggplot(data = data) +
    geom_bar(aes(x = factor(postal_cd), y = percent, fill = district_size), stat = "identity") +
    scale_fill_manual(name = "",
                      #labels = c("Tiny", "Small", "Medium", "Large", "Mega"),
                      values = c("#F0643C", "#f09221", "#f4b400", "#fdb913", "#fff1d0")) + 
                    #  values = c("#fff1d0", "#fdb913", "#f4b400", "#f09221", "#F0643C")) +
    geom_hline(yintercept = 0, colour= "#899DA4") +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          axis.line = element_blank(), 
          axis.text.x=element_text(size=14), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),             
          text=element_text(size = 18, family="Lato")) +
   guides(fill=guide_legend(
          #reverse = TRUE,
          keywidth = 0.35,
          keyheight = 0.35,
          default.unit = "inch"))
  
  print(q)
  
  
})


## size distribution table
output$table_size <- renderDataTable({
  
  data <- state_subset_size()
  validate(
    need(input$state != 'All', "")
  )

  data <- data %>% group_by(postal_cd) %>% arrange(district_size)
  data$percent <- paste(round(data$percent, 2), "%", sep ="")
  data <- select(data, postal_cd, district_size, percent, n_districts_size, n_districts,
                 n_schools, n_students)
  colnames(data) <- c("Postal Code", "District Size", "% of Districts in Size Bucket", 
                      "# of Districts in Size Bucket", "# of Districts in the State", 
                      "# of Schools in the State", "# of Students in the State")
  
  datatable(format(data, big.mark = ",", scientific = FALSE), caption = 'Use the Search bar for the data table below.', rownames = FALSE, options = list(paging = FALSE))

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
  
  print(head(data))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
      
  data <- melt(data)

  q <- ggplot(data = data) +
         geom_bar(aes(x = variable, y = value), width = .5, fill="#fdb913", stat = "identity") +
         geom_text(aes(label = paste0(value, "%"), x = variable, y = value), vjust = -1, size = 6) +
         scale_x_discrete(breaks=c("percent_districts_meeting_goals", "percent_students_meeting_goals"),
                     labels=c("Districts", "Students")) +
         scale_y_continuous(limits = c(0, 110)) +
         geom_hline(yintercept = 0, colour= "#899DA4") +
         theme(plot.background = element_rect(fill = "white"),
               panel.background = element_rect(fill = "white"),
               legend.background = element_rect(fill = "white"),
               axis.line = element_blank(), 
               axis.text.x = element_text(size=14), 
               axis.text.y = element_blank(),
               axis.ticks = element_blank(),
               axis.title.x=element_blank(),   
               axis.title.y=element_blank(),
               text=element_text(size = 16, family="Lato"),
               legend.title = element_text(colour = "#636363"),
               legend.text = element_text(colour = "#636363"),
               legend.position = "top", #c(0.5, 0.97),
               legend.box = "horizontal",
               #legend.text.align = ,
               plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
                 ggtitle(paste("Percent of Districts and Students \nMeeting 100 Kbps/Student Goal", "\n\n\n\n")) + 
                 guides(fill=guide_legend(title.position="top",
                                          #keywidth = 0.35,
                                          #keyheight = 0.35,
                                          default.unit = "inch"))
            
  
  
      
  print(q)
  
})

########### TESTING RENDERIMAGE ########################

output$myImage <- renderImage({
    
    #postscriptFonts()
  
    # Read myImage's width and height. These are reactive values, so this
    # expression will re-run whenever they change.
    width  <- session$clientData$output_myImage_width
    height <- session$clientData$output_myImage_height
    
    # For high-res displays, this will be greater than 1
    pixelratio <- session$clientData$pixelratio
    
    # A temp file to save the output.
    # This file will be removed later by renderImage
    outfile <- tempfile(fileext='.png')
  
  
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                       district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
    summarize(percent_districts_meeting_goals = round(100 * mean(meeting_goals_district), 2),
              percent_students_meeting_goals = round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  data <- melt(data)
  
  # Generate the image file
  esh_fonts <- c("Lato", "MuseoSlabW01-700")
  png(outfile, width=width*pixelratio, height=height*pixelratio,
      res=72*pixelratio, antialias = "none")# ,type = "Xlib", fonts = esh_fonts)
  
  
  #postscript("outfile.png", fonts = esh_fonts)#, width=width*pixelratio, height=height*pixelratio,
  #        #  res=72*pixelratio)
  
  q <- ggplot(data = data) +
    geom_bar(aes(x = variable, y = value), width = .5, fill="#fdb913", stat = "identity") +
    geom_text(aes(label = paste0(value, "%"), x = variable, y = value), vjust = -1, size = 6) +
    scale_x_discrete(breaks=c("percent_districts_meeting_goals", "percent_students_meeting_goals"),
                     labels=c("Districts", "Students")) +
    scale_y_continuous(limits = c(0, 110)) +
    geom_hline(yintercept = 0, colour= "#899DA4") +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          axis.line = element_blank(), 
          axis.text.x = element_text(size=14), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),   
          axis.title.y=element_blank(),
          text=element_text(size = 16, family="Lato"),
          legend.title = element_text(colour = "#636363"),
          legend.text = element_text(colour = "#636363"),
          legend.position = "top", #c(0.5, 0.97),
          legend.box = "horizontal",
          #legend.text.align = ,
          plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
    ggtitle(paste("Percent of Districts and Students \nMeeting 100 Kbps/Student Goal", "\n\n\n\n")) + 
    guides(fill=guide_legend(title.position="top",
                             #keywidth = 0.35,
                             #keyheight = 0.35,
                             default.unit = "inch"))
  print(q)

  dev.off()
  
  # Return a list containing the filename
  list(src = outfile,
       contentType = 'image/png',
       width = width,
       height = height,
       alt = "This is alternate text")
}, deleteFile = TRUE)

########## END TESTING RENDERIMAGE #########################

output$table_goals <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                           district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) 
  data$num_stud_mtg_goals <- ifelse(data$meeting_goals_district == 1, data$num_students, 0)
  data <- data %>% 
          summarize(
              n_dists_mg = sum(meeting_goals_district),
              n = n(),
              percent_districts_meeting_goals = paste0(round(100 * mean(meeting_goals_district), 2), "%"),
              n_stud_mg = sum(num_stud_mtg_goals),
              n_students = sum(num_students),
              percent_students_meeting_goals = paste0(round(100 * sum(meeting_goals_district * num_students) / sum(num_students), 2), "%"))
  colnames(data) <- c("# of Districts Meeting Goals", "# of Clean Districts", "% of Districts Meeting Goals", 
                      "# of Students in Districts Meeting Goals", "# of Students in Clean Districts", 
                      "% of Students Meeting Goals")

  
  
  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), options = list(paging = FALSE, searching = FALSE), rownames = FALSE)
  
})

## Districts Meeting Goals, by Technology
districts_ia_tech_data <- reactive({
  
  d_ia_tech_data <- district_subset() %>% 
                    filter(new_connect_type_goals %in% input$connection_districts_goals,
                           district_size2 %in% input$district_size_goals, 
                           locale2 %in% input$locale_goals, 
                           meeting_2014_goal_no_oversub %in% input$meeting_goal) 
  
  d_ia_tech_data
  
  })

output$histogram_districts_ia_technology <- renderPlot({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
            district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals, meeting_2014_goal_no_oversub %in% input$meeting_goal) %>% 
            group_by(new_connect_type_goals) %>%
            summarize(n_districts = n()) %>%
            mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
            n_percent_districts = round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2))
  
  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  
  
  plot_title <- ifelse(input$meeting_goal[1] == c("Meeting Goal") & input$meeting_goal[2] == c("Not Meeting Goal"), "All Districts", 
                       "Districts Not Meeting Goals")
                       #ifelse(length(input$meeting_goal) == 1 & input$meeting_goal == "Meeting Goal", "Districts Meeting 100kbps/Student Goal",
                      #        "Districts Not Meeting 100kbps/Student Goal"))
  
  q <- ggplot(data = data, aes(x = new_connect_type_goals, y = n_percent_districts)) +
       geom_bar(fill = "#fdb913", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(n_percent_districts, "%")), 
                 vjust = -1, size = 6) +
       scale_y_continuous(limits = c(0, 110)) +
       scale_x_discrete(limits = c("Other / Uncategorized", "Cable", "DSL", "Copper", "Fixed Wireless", "Fiber")) +
       geom_hline(yintercept = 0, colour= "#899DA4") +
       theme(plot.background = element_rect(fill = "white"),
             panel.background = element_rect(fill = "white"),
             legend.background = element_rect(fill = "white"),
             axis.line = element_blank(), 
             axis.text.x=element_text(size=14), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank(),
             text=element_text(size = 16, family="Lato"),
             legend.title = element_text(colour = "#636363"),
             legend.text = element_text(colour = "#636363"),
             #legend.position = "top", #c(0.5, 0.97),
             #legend.box = "horizontal",
             #legend.text.align = ,
             plot.title = element_text(size = 22, family="MuseoSlabW01-700")) + 
    ggtitle(paste("Highest IA Connect Types: ", "\n", plot_title
                  
                  #ifelse(input$meeting_goal[1] == "Meeting Goal" & input$meeting_goal[2] == "Not Meeting Goal", "All Districts", 
                  #                                       ifelse(input$meeting_goal[1] == c("Not Meeting Goal"), "Districts Not Meeting 100kbps/Student Goal", #if(input$meeting_goal == "NA") "Districts Meeting 100kbps/Student Goal"))
                  #                                              if(input$meeting_goal[1] == "Meeting Goal" & length(input$meeting_goal) == 1)"Districts Meeting 100kbps/Student Goal"))
                  #                                              #ifelse(input$meeting_goal == c("Meeting Goal"), "Districts Meeting 100kbps/Student Goal", "")))
                                                                ,  "\n\n\n\n")) + 
    guides(fill=guide_legend(title.position="top",
                             #keywidth = 0.35,
                             #keyheight = 0.35,
                             default.unit = "inch"))
  
  print(q)

  
})

output$table_districts_ia_technology <- renderDataTable({
  
  data <- district_subset() %>% 
          filter(new_connect_type_goals %in% input$connection_districts_goals,
                 district_size2 %in% input$district_size_goals, 
                 locale2 %in% input$locale_goals, 
                 meeting_2014_goal_no_oversub %in% input$meeting_goal) %>% 
          group_by(new_connect_type_goals) %>%
          summarize(n_districts = n()) %>%
                  mutate(n_all_districts_in_goal_meeting_status = sum(n_districts),
                  n_percent_districts = paste0(round(100 * n_districts / n_all_districts_in_goal_meeting_status, 2), "%")) %>%
          arrange(new_connect_type_goals)
  
  colnames(data) <- c("Highest IA Technology", "# of Districts", "# of Districts in Goal Meeting Status", "% of Districts")
  
  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), caption = 'Use the Search bar for the data table below.', 
            rownames = FALSE, options = list(paging = FALSE))
  
})

## WAN Goals: Current vs.  Needs
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
  
    q <- ggplot(data = data[which(data$variable %in% c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs")),]) +
       geom_bar(aes(x = variable, y = value, fill=variable), stat = "identity", width = .5) +
        geom_text(aes(label = paste0(value, "%"), x = variable, y = value),  vjust =-1, size = 6) +
        scale_x_discrete(breaks=c("percent_current_wan_goals", "percent_schools_with_proj_wan_needs"),
                     labels=c("Schools that Currently Have >= 1G WAN", "Schools that Need >= 1G WAN")) +
        scale_y_continuous(limits = c(0, 110)) +
        scale_fill_manual(values = c("#fdb913", "#f09221")) + 
        geom_hline(yintercept = 0, colour= "#899DA4") +
      theme(plot.background = element_rect(fill = "white"),
            panel.background = element_rect(fill = "white"),
            legend.background = element_rect(fill = "white"),
            axis.line = element_blank(), 
            axis.text.x = element_text(size=14), 
            axis.text.y = element_blank(),
            axis.ticks = element_blank(),
            axis.title.x=element_blank(),   
            axis.title.y=element_blank(),
            text=element_text(size = 16, family="Lato"),
            legend.position = "none",
            #legend.title = element_blank(),
            #legend.text = element_blank(),
            #legend.position = "top", #c(0.5, 0.97),
            #legend.box = "horizontal",
            #legend.text.align = ,
            plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
      ggtitle(paste("Percent of WAN Connections >= 1 Gbps",  "\n\n\n\n")) + 
      guides(fill=guide_legend(title.position="top",
                               #keywidth = 0.35,
                               #keyheight = 0.35,
                               default.unit = "inch"))
    
      
  print(q)
  
})

output$table_projected_wan_needs <- renderDataTable({
  
  data <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                   district_size2 %in% input$district_size_goals, locale2 %in% input$locale_goals) %>% 
          summarize(n_circuits_1g_wan = sum(gt_1g_wan_lines, na.rm = TRUE),
                    n_circuits_all_wan = sum(lt_1g_fiber_wan_lines + lt_1g_nonfiber_wan_lines, na.rm = TRUE) + n_circuits_1g_wan,
                    percent_current_wan_goals = paste0(round(100 * n_circuits_1g_wan / n_circuits_all_wan, 2), "%"),
                    n_schools_with_proj_wan_needs = sum(n_schools_wan_needs, na.rm = TRUE),
                    n_all_schools_in_wan_needs_calculation = sum(n_schools_in_wan_needs_calculation, na.rm = TRUE),
                    percent_schools_with_proj_wan_needs = paste0(round(100 * n_schools_with_proj_wan_needs / n_all_schools_in_wan_needs_calculation, 2), "%"))
  colnames(data) <- c("# of >=1G WAN Circuits", "# of All WAN Circuits", "% Schools Currently Meeting WAN Goal", 
                      "# of Schools that Need >=1G WAN", "# of Schools in WAN Needs Calculation", 
                      "% of Schools that Need >=1G WAN")
  #print(names(data))
  
  validate(need(nrow(data) > 0, ""))
  
  datatable(format(data, big.mark = ",", scientific = FALSE), rownames = FALSE, options = list(paging = FALSE, searching = FALSE))
  
})


######
## Fiber Section
######

fiber_data <- reactive({
              district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
                               locale3 %in% input$locale_fiber)
})

## Districts and Students Meeting Goals
output$histogram_schools_on_fiber <- renderPlot({
  
  #data1 <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
  #                                      locale3 %in% input$locale_fiber)
  
  data1 <- fiber_data()
  
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
       geom_bar(fill="#fdb913", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(value, "%")), vjust =-1, size = 6) +
       scale_x_discrete(breaks=c("percent_on_fiber", "percent_may_need_upgrades", "percent_need_upgrades"),
                     labels=c("Have Fiber", "May Need Upgrades", "Need Upgrades")) +
       scale_y_continuous(limits = c(0, 110)) +
       geom_hline(yintercept = 0, colour= "#899DA4") +
       theme(plot.background = element_rect(fill = "white"),
             panel.background = element_rect(fill = "white"),
             legend.background = element_rect(fill = "white"),
             axis.line = element_blank(), 
             text=element_text(size = 16, family="Lato"),
             #axis.text.x=element_text(colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             axis.title.x=element_blank(),
             axis.title.y=element_blank(),
             plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
    ggtitle(paste("Distribution of Schools by Infrastructure Type",  "\n\n\n\n")) + 
    guides(fill=guide_legend(title.position="top",
                             #keywidth = 0.35,
                             #keyheight = 0.35,
                             default.unit = "inch"))
  print(q)
  
})

## Table on distribution of schools by infrastructure type
output$table_schools_on_fiber <- renderDataTable({
  
  #data <- district_subset() %>% 
  #        filter(district_size3 %in% input$district_size_fiber,
  #               locale3 %in% input$locale_fiber) %>% 
  #fd <- fiber_data()
  
  
  data <- fiber_data() %>% summarize(num_schools_on_fiber = round(sum(schools_on_fiber), 0),
                     num_schools_may_need_upgrades = round(sum(schools_may_need_upgrades), 0),
                     num_schools_need_upgrades = round(sum(schools_need_upgrades), 0),
                     num_all_schools = sum(num_schools_on_fiber, num_schools_may_need_upgrades, num_schools_need_upgrades),
                     percent_on_fiber = paste0(round(100 * num_schools_on_fiber / num_all_schools, 2), "%"),
                     percent_may_need_upgrades = paste0(round(100 * num_schools_may_need_upgrades / num_all_schools, 2), "%"),
                     percent_need_upgrades = paste0(round(100 * num_schools_need_upgrades / num_all_schools, 2), "%")
                     ) %>%
          select(percent_on_fiber, percent_may_need_upgrades, percent_need_upgrades,
                 num_all_schools, num_schools_on_fiber, num_schools_may_need_upgrades, num_schools_need_upgrades)
        
  colnames(data) <- c("% of Schools on Fiber", "% of Schools That May Need Upgrades", "% of Schools That Need Upgrades",
                      "# of Schools", "# of Schools on Fiber", "# of Schools That May Need Upgrades", 
                      "# of Schools That Need Upgrades")
        
  validate(need(nrow(data) > 0, ""))  
  
  datatable(format(data, big.mark = ",", scientific = FALSE), rownames = FALSE, options = list(paging = FALSE, searching = FALSE))
  
})

## Districts - E-rate Discount Rates
output$histogram_by_erate_discounts <- renderPlot({
  
  
  #data <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
  #                               locale3 %in% input$locale_fiber) %>% 
    
  data <- fiber_data() %>%   
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
          summarize(n_unscalable_schools_in_rate_band = sum(schools_need_upgrades + schools_may_need_upgrades)) %>%
          mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
                 percent_unscalable_schools_in_rate_band = round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2))

  validate(need(nrow(data) > 0, "No district in given subset; please adjust your selection"))  

  q <- ggplot(data = data, aes(x = as.factor(c1_discount_rate), y = percent_unscalable_schools_in_rate_band)) +
       geom_bar(fill="#fdb913", stat = "identity", width = .5) +
       geom_text(aes(label = paste0(percent_unscalable_schools_in_rate_band, "%")), vjust = -1, size = 6) +
       scale_y_continuous(limits = c(0, 110)) +
       geom_hline(yintercept = 0, colour= "#899DA4") +
       theme(plot.background = element_rect(fill = "white"),
             panel.background = element_rect(fill = "white"),
             legend.background = element_rect(fill = "white"),
             axis.line = element_blank(), 
             text=element_text(size = 18, family="Lato"),
             #axis.text.x=element_text(colour= "#899DA4"), 
             axis.text.y = element_blank(),
             axis.ticks = element_blank(),
             #axis.title.x=element_text("Distribution of campuses by E-rate discount rate (%)"),
             axis.title.y=element_blank(), 
             plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
    ggtitle(paste("\nDistribution of campuses by E-rate discount rate (%)", "\n\n\n\n")) +
    guides(fill=guide_legend(title.position="top",
                             #keywidth = 0.35,
                             #keyheight = 0.35,
                             default.unit = "inch"))
  
  print(q)
  
})

## Table on distribution of schools by infrastructure type
output$table_by_erate_discounts <- renderDataTable({
  
 # data <- district_subset() %>% filter(district_size3 %in% input$district_size_fiber,
 #                                           locale3 %in% input$locale_fiber) %>% 
 
   data <- fiber_data() %>%   
          filter(!is.na(c1_discount_rate),
                 not_all_scalable == 1) %>% # only include districts that are unscalable
          group_by(c1_discount_rate) %>%
    summarize(n_unscalable_schools_in_rate_band = round(sum(schools_need_upgrades + schools_may_need_upgrades))) %>%
    mutate(n_all_unscalable_schools_in_calculation = sum(n_unscalable_schools_in_rate_band),
           percent_unscalable_schools_in_rate_band = paste0(round(100 * n_unscalable_schools_in_rate_band / n_all_unscalable_schools_in_calculation, 2), "%")) %>%
    arrange(c1_discount_rate, percent_unscalable_schools_in_rate_band, n_unscalable_schools_in_rate_band, n_all_unscalable_schools_in_calculation)
  
  colnames(data) <- c("C1 Discount Rate", "# of Unscalable Schools in Discount Rate Group", "# of All Unscalable Schools in Calculation", "% of Unscalable Schools in Discount Rate Group") 
    
  validate(need(nrow(data) > 0, ""))  
  datatable(format(data, big.mark = ",", scientific = FALSE), rownames = FALSE, options = list(paging = FALSE, searching = FALSE))
  
})

###### 
## Maps
######
# District Lookup

output$districtSelect <- renderUI({
  
  districtSelect_data <- district_subset() 
  
  validate(need(nrow(districtSelect_data) > 0, "No districts in given subset"))

  district_list <- c(unique(as.character(districtSelect_data$name)), "SELECT ALL") #made global

  selectizeInput("pin_district", h2("Input District Name(s)"), as.list(district_list), multiple = TRUE, options = list(placeholder = 'e.g. Cave Creek Unified District')) 


  })

output$selected <- renderText({
  paste(input$pin_district, collapse = ", ")
})


#switch(input$map_view_lookup,
#       "All Districts" = print(l1),
#       "Clean/Dirty Districts" = print(l2),
#       'Goals: 100 kbps/Student' = print(l3),
#       'Goals: 1 Mbps/Student' = print(l4),
#       'Fiber Build Cost to Districts' = print(l5))

##Trying leaflet: 
#observe({
school_districts <- eventReactive(input$pin_district, {
  d <- district_subset() %>% filter(name %in% input$pin_district)

  d %>% select(name = name, X = longitude, Y = latitude, num_students, ia_bandwidth_per_student, meeting_2014_goal_no_oversub, new_connect_type_goals, total_ia_monthly_cost, monthly_ia_cost_per_mbps)

})  
  
output$testing_leaflet <- renderLeaflet({ 

  sd_info <- paste0("<b>", school_districts()$name, "</b><br>",
                    "# of students:", format(school_districts()$num_students, big.mark = ",", scientific = FALSE),"<br>",
                    "IA connection: ", school_districts()$new_connect_type_goals, "<br>",
                    "IA kbps/student: ", school_districts()$ia_bandwidth_per_student, "<br>",
                    "100 kbps goal status: ", school_districts()$meeting_2014_goal_no_oversub, "<br>",
                    "Total IA monthly cost: $", format(round(school_districts()$total_ia_monthly_cost, 2), big.mark = ",", nsmall = 2, scientific = FALSE), "<br>",
                    "Total IA monthly cost/Mbps: $", format(round(school_districts()$monthly_ia_cost_per_mbps, 2),  big.mark = ",", nsmall = 2, scientific = FALSE))

  leaflet() %>% addProviderTiles(input$tile) %>% addMarkers(data = school_districts(), lng = ~X, lat = ~Y, popup = ~paste(sd_info))#%>% addMarkers(data = d, lng = ~longitude, lat = ~latitude, popup = ~name) #popup = ~paste(content)) 
  #default view of leaflet map is addTiles()
})

#})



reac_map_lookup <- reactive({
  
  data <- district_subset() %>%
    filter(!(postal_cd %in% c('AK', 'HI')), 
            name %in% input$pin_district)
    #       new_connect_type_map %in% input$connection_districts,
    #       district_size %in% input$district_size_maps,
    #       locale %in% input$locale_maps)

  validate(
    need(nrow(data) > 0, "No districts in given subset")
  )
  
  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
  state_df <- map_data("county", region = state_name)
  #hdf <- get_map(state_name, source = 'stamen', maptype = 'toner', zoom = 7, crop = FALSE)
  
  set.seed(123) #to control jitter
  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
    #ggmap(hdf) +
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'white', fill = "#d9d9d9") +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.key = element_blank(),
          legend.text = element_text(size=16, family="Lato"), 
          legend.position= "bottom",
          legend.direction="vertical") +
    guides(shape=guide_legend(override.aes=list(size=7))) 
  
  
  
  q <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude), colour = c("#fdb913"),
               alpha = 0.7, size = 4)
  
  qq <<- q + coord_map()
  
  r <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#fdb913", "#fff1d0"))
  rr <<- r + coord_map()
  
  
  s <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 100kbps/Student Goal", 
                                                                      "Does Not Meet 100kbps/Student Goal"), values = c("#fdb913", "#cb2027"))
  ss <<- s + coord_map()
  
  t <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 1Mbps/Student Goal", 
                                                                      "Does Not Meet 1Mbps/Student Goal"), values = c("#009296", "#fff1d0")) +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white")
    )
  
  tt <<- t + coord_map()
  
  ddt_unscalable <- data %>% 
    filter(not_all_scalable == 1)
  
  u <- state_base + 
    geom_point(data = ddt_unscalable, 
               aes(x = longitude, y = latitude, colour = as.factor(zero_build_cost_to_district)),
               alpha = 0.8, size = 4) +
    scale_color_manual(values = c("#fff1d0", "#fdb913"), 
                       breaks = c(0, 1), labels = c("Upgrade at partial cost to district", "Upgrade at no cost to district"))
  
  uu <<- u + coord_map()
  
  switch(input$map_view_lookup,
         "All Districts" = print(qq),
         "Clean/Dirty Districts" = print(rr),
         'Goals: 100 kbps/Student' = print(ss),
         'Goals: 1 Mbps/Student' = print(tt),
         'Fiber Build Cost to Districts' = print(uu)#,
         #'Connect Category' = print(vv)
  )
  
})








#output$choose_district <- renderPlot({
  
#  choose_district_data <- district_subset() %>%
#          filter(!(postal_cd %in% c('AK', 'HI')))
  
#  selected_district_list <- paste0("c(",toString(paste0('\"', input$district_list, '\"')), ')')  
  
#  choose_district_data <- choose_district_data %>% 
#          filter_(paste("name %in%", selected_district_list))
  
#  validate(
#    need(nrow(choose_district_data) > 0, "No districts in given subset")
#  )
  
#  state_name <- state_lookup$name[state_lookup$code == input$state] #input$state
#  state_df <- map_data("county", region = state_name)
  
#  set.seed(123) #to control jitter
#  state_base <-  ggplot(data = state_df, aes(x = long, y=lat)) + 
#    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'black', fill = NA) +
#    theme_classic() +
#    theme(line = element_blank(), title = element_blank(), 
#          axis.text.x = element_blank(), axis.text.y = element_blank(),
#          legend.text = element_text(size=16), legend.position=c(0.5, 0.5)) +
#    guides(shape=guide_legend(override.aes=list(size=7))) 
  
#  q <- state_base + 
#       geom_point(data = choose_district_data, aes(x = longitude, y = latitude), colour = c("#0073B6"),
#                               alpha = 0.7, size = 6) 
  
#  print(q + coord_map())
  
  
#})

############ map of districts ################### 
output$population_leaflet <- renderLeaflet({ 
  
  data <- district_subset() %>%
           filter(new_connect_type_map %in% input$connection_districts,
           district_size %in% input$district_size_maps,
           locale %in% input$locale_maps)
  
  ddt_unscalable <- data %>% 
    filter(not_all_scalable == 1)

  #for all maps other than fiber build
  sd_info2 <- paste0("<b>", data$name, "</b><br>",
                   "# of students:", format(data$num_students, big.mark = ",", scientific = FALSE),"<br>",
                    "IA connection: ", data$new_connect_type_goals, "<br>",
                    "IA kbps/student: ", data$ia_bandwidth_per_student, "<br>",
                    "100 kbps goal status: ", data$meeting_2014_goal_no_oversub, "<br>",
                    "Total IA monthly cost: $", format(round(data$total_ia_monthly_cost,2), big.mark = ",", nsmall = 2, scientific = FALSE), "<br>",
                    "Total IA monthly cost/Mbps: $", format(round(data$monthly_ia_cost_per_mbps,2), big.mark = ",", nsmall = 2, scientific = FALSE))
  #for unscalable districts:
  sd_info3 <- paste0("<b>", ddt_unscalable$name, "</b><br>",
                     "# of students:", format(ddt_unscalable$num_students, big.mark = ",", scientific = FALSE),"<br>",
                     "IA connection: ", ddt_unscalable$new_connect_type_goals, "<br>",
                     "IA kbps/student: ", ddt_unscalable$ia_bandwidth_per_student, "<br>",
                     "100 kbps goal status: ", ddt_unscalable$meeting_2014_goal_no_oversub, "<br>",
                     "Total IA monthly cost: $", format(round(ddt_unscalable$total_ia_monthly_cost,2), big.mark = ",", nsmall = 2, scientific = FALSE), "<br>",
                     "Total IA monthly cost/Mbps: $", format(round(ddt_unscalable$monthly_ia_cost_per_mbps,2), big.mark = ",", nsmall = 2, scientific = FALSE))

  l1 <- leaflet(data) %>% 
            addProviderTiles(input$tile2) %>% addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = "#fdb913", stroke = FALSE, fillOpacity = 0.9, popup = ~paste(sd_info2))  
  
  l2 <- leaflet(data) %>% 
            addProviderTiles(input$tile2) %>% addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = ~ifelse(exclude_from_analysis == "FALSE", "#fdb913", "#cb2027"), 
                                           stroke = FALSE, fillOpacity = 0.9, popup = ~paste(sd_info2)) %>% 
            addLegend("topright", colors = c("#fdb913", "#cb2027"), labels = c("Clean Districts", "Dirty Districts"),
                        title = "Cleanliness Status of District", opacity = 1)
  
  l3 <- leaflet(data) %>% 
           addProviderTiles(input$tile2) %>% addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = ~ifelse(meeting_2014_goal_no_oversub == "Meeting Goal", "#fdb913", "#cb2027"), 
                                           stroke = FALSE, fillOpacity = 0.9, popup = ~paste(sd_info2)) %>% 
           addLegend("topright", colors = c("#fdb913", "#cb2027"), labels = c("Meets 100kbps/Student Goal", "Does Not Meet 100kbps/Student Goal"),
              title = "Goal Status", opacity = 1)
  
  l4 <- leaflet(data) %>% 
           addProviderTiles(input$tile2) %>% addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = ~ifelse(meeting_2018_goal_oversub == "Meeting 2018 Goals", "#fdb913", "#f26b23"), 
                                           stroke = FALSE, fillOpacity = 0.9, popup = ~paste(sd_info2)) %>% 
           addLegend("topright", colors = c("#fdb913", "#f26b23"), labels = c("Meets 1Mbps/Student Goal", "Does Not Meet 1Mbps/Student Goal"),
              title = "Goal Status", opacity = 1)
  
  l5 <- leaflet(ddt_unscalable) %>% 
                     addProviderTiles(input$tile2) %>% 
                     addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = ~ifelse(zero_build_cost_to_district == 0, "#009296", "#fdb913"), 
                                      stroke = FALSE, fillOpacity = 0.9, popup = ~paste(sd_info3)) %>% 
                    addLegend("topright", colors = c("#009296", "#fdb913", "black"), labels = c("Upgrade at partial cost to district", "Upgrade at no cost to district", "Missing E-rate discount rate"),
                               title = "Cost for Fiber Build", opacity = 1)
  
  #l6 <- leaflet(data) %>% 
  #  addProviderTiles(input$tile2) %>% addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 6, color = ~as.factor(new_connect_type_map), 
  #                                                     stroke = FALSE, fillOpacity = 0.7, popup = ~as.character(name)) %>% 
  #  addLegend("bottomright", title = "Connect Category", opacity = 1)
  
  
  switch(input$map_view,
         "All Districts" = print(l1),
         "Clean/Dirty Districts" = print(l2),
         'Goals: 100 kbps/Student' = print(l3),
         'Goals: 1 Mbps/Student' = print(l4),
         'Fiber Build Cost to Districts' = print(l5))

})

reac_map_pop <- reactive({

#output$map_population <- renderPlot({
  
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
    geom_polygon(data = state_df, aes(x = long, y = lat, group = group), color = 'white', fill = "#d9d9d9") +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          line = element_blank(), title = element_blank(), 
          axis.text.x = element_blank(), axis.text.y = element_blank(),
          legend.key = element_blank(),
          legend.text = element_text(size=16, family="Lato"), 
          legend.position= "bottom",
          legend.direction="vertical") +
    guides(shape=guide_legend(override.aes=list(size=7))) 

  
  
  q <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude), colour = c("#fdb913"),
                               alpha = 0.7, size = 4)
      
  qq <<- q + coord_map()
  
  r <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude, colour = exclude_from_analysis), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Clean District", "Dirty District"), values = c("#fdb913", "#fff1d0"))
  rr <<- r + coord_map()
  
  
  s <- state_base + 
    geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2014_goal_no_oversub), 
               alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 100kbps/Student Goal", 
                                                                      "Does Not Meet 100kbps/Student Goal"), values = c("#fdb913", "#cb2027"))
  ss <<- s + coord_map()
  
  t <- state_base + 
       geom_point(data = data, aes(x = longitude, y = latitude, colour = meeting_2018_goal_oversub), 
                 alpha = 0.7, size = 4) + scale_color_manual(labels = c("Meets 1Mbps/Student Goal", 
                                                                      "Does Not Meet 1Mbps/Student Goal"), values = c("#009296", "#fff1d0")) +
      theme(plot.background = element_rect(fill = "white"),
            panel.background = element_rect(fill = "white"),
            legend.background = element_rect(fill = "white")
      )
  
  tt <<- t + coord_map()
  
  ddt_unscalable <- data %>% 
    filter(not_all_scalable == 1)
  
  u <- state_base + 
    geom_point(data = ddt_unscalable, 
               aes(x = longitude, y = latitude, colour = as.factor(zero_build_cost_to_district)),
               alpha = 0.8, size = 4) +
    scale_color_manual(values = c("#fff1d0", "#fdb913"), 
                       breaks = c(0, 1), labels = c("Upgrade at partial cost to district", "Upgrade at no cost to district"))
  
  uu <<- u + coord_map()
  
  

  #v <- state_base + 
  #    geom_point(data = data, aes(x = longitude, y = latitude, colour = factor(hierarchy_connect_category)),
  #               alpha = 0.7, size = 4)
  #vv <- v + coord_map()

  

  switch(input$map_view,
         "All Districts" = print(qq),
         "Clean/Dirty Districts" = print(rr),
         'Goals: 100 kbps/Student' = print(ss),
         'Goals: 1 Mbps/Student' = print(tt),
         'Fiber Build Cost to Districts' = print(uu)#,
         #'Connect Category' = print(vv)
         )

  
})

output$map_population <- renderPlot({
  print(reac_map_pop()$plot)
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


#not using ggvis since side-by-side bar chart is not possible
price_disp_cpc <- reactive({

  a <- sr_all() %>% 
       group_by(bandwidth_in_mbps) %>% 
       summarise(p25th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE),
                           Median = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE),
                           p75th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE))
  
   
   bw <- "bandwidth_in_mbps"
   percentile <- "percentiles"
   dispersion <- c("p25th", "Median", "p75th")
   
   b <- gather_(a, bw, percentile, dispersion)
   colnames(b) <- c("bw_mbps", "percentile", "cost" )
   #print(b)
  
    data <- sr_all() %>% 
            filter(bandwidth_in_mbps == unique(bandwidth_in_mbps[1]))
    data$monthly_cost_per_circuit <- as.numeric(as.character(data$monthly_cost_per_circuit))
    percentiles <- quantile(data$monthly_cost_per_circuit, c(.25, .50, .75), na.rm = TRUE)  
    perc_tab <- as.data.frame(percentiles)  
    add_perc <- c("25th","Median", "75th")
    bw_mbps <- c(rep(data$bandwidth_in_mbps[1], 3)) #added for TESTING 
    perc_tab <- cbind(perc_tab, add_perc, bw_mbps)
    perc_tab$add_perc <- factor(perc_tab$add_perc, levels = perc_tab$add_perc[1:3], labels = c("25th", "Median", "75th"))
    
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
    }

    else{
    perc_tab %>% 
    ggvis(x = ~add_perc, y = ~percentiles, fill := "#FDB913", fillOpacity := 0.6) %>% 
    group_by(add_perc) %>% 
    layer_bars(strokeWidth := 0) %>%    
    layer_rects(fill:="white") %>%
    add_axis("x", title = "Percentile", title_offset = 50, grid=FALSE) %>% 
    add_axis("y", title = "Monthly Cost per Circuit ($)", title_offset = 75, grid=FALSE) %>% 
    add_legend("stroke", title = "")    
    }
  
})

price_disp_cpc %>% bind_shiny("price_disp_cpc")


output$cpc_sidebars <- renderPlot({

  
  validate(
    need(length(unique(sr_all()$bandwidth_in_mbps)) > 0, "Please select circuit size(s) through the side panel.")
  )
  
  a <- sr_all() %>% 
       group_by(bandwidth_in_mbps) %>% 
       summarise(p25th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE),
                 Median = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE),
                 p75th = quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE))
  
  bw <- "bandwidth_in_mbps"
  percentile <- "percentiles"
  dispersion <- c("p25th", "Median", "p75th")
  
  b <- gather_(a, bw, percentile, dispersion)
  colnames(b) <- c("bw_mbps", "percentile", "cost" )
  b$percentile <- factor(b$percentile, levels = c("p25th", "Median", "p75th"))
  b$cost_label <- paste0("$", round(b$cost, 2))

  positions <- c("p25th", "Median", "p75th")
  
  m <- max(b$cost) * 1.5 #adjusting height of ggplot2 chart
  n <- nrow(b) * 2
  
  v <- ggplot(data = b, aes(x=percentile, y=cost,fill = factor(bw_mbps))) +
    geom_bar(stat="identity", position = "dodge", width = 0.75) + 

    geom_text(aes(label = paste("$", round(cost, digits = 2), sep="")), vjust = -0.5, position = position_dodge(width = 0.9), size = 5, colour = "#636363") +
    #scale_x_discrete(limits = positions) +
    scale_x_discrete(
                     breaks=c("Median", "p25th", "p75th"),
                     labels=c("Median", "25th", "75th")) +
                        #guide = guide_legend(title = "Bandwidth Speed (Mbps)")) +
    scale_fill_brewer(name = "Circuit Size(s) in Mbps", palette = "YlOrRd", direction = -1) +
    geom_hline(yintercept = 0, colour= "#899DA4") +
    coord_cartesian(ylim=c(0, m)) +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          axis.line = element_blank(), 
          axis.text.x=element_text(size=18, colour= "#636363"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          text=element_text(size = 16, family="Lato"),
          legend.title = element_text(colour = "#636363"),
          legend.text = element_text(colour = "#636363"),
          legend.position = "top", #c(0.5, 0.97),
          legend.box = "horizontal",
          #legend.text.align = ,
          plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
    #ggtitle(paste("Price Dispersion: \nMonthly Cost Per Circuit for", input$connection_services, input$purpose, "\n")) + 
    guides(fill=guide_legend(title.position="top",
      #keywidth = 0.35,
      #keyheight = 0.35,
      default.unit = "inch"))

  print(v)

})




output$disp_cpc_table <- renderDataTable({
  
  perc_tab <- sr_all() %>% 
              group_by(bandwidth_in_mbps) %>% 
              summarise(n_services = n(),
              n_circuits = sum(cat.1_allocations_to_district),
              p25th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.25, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              Median = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.50, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              p75th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_circuit)), 0.75, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""))
  colnames(perc_tab)<- c("Circuit Size (Mbps)" ,"# of Line Items", "# of Circuits", "25th Percentile", "Median", "75th Percentile")
  
  datatable(perc_tab, rownames = FALSE, options = list(paging = FALSE, searching = FALSE))

})

output$price_disp_cpm_sidebars <- renderPlot({
  
  validate(
    need(length(unique(sr_all()$bandwidth_in_mbps)) > 0, "Please select circuit size(s) through the side panel.")
  )
  
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
  
  m2 <- max(b2$cost) * 1.5 #adjusting height of ggplot2 
  
  v <- ggplot(data = b2, aes(x=percentile, y=cost, fill=factor(bw_mbps)))+
    geom_bar(stat="identity", position = "dodge", width = 0.75) + 
    geom_text(aes(label = paste0("$", round(cost, digits = 2))
                  #  format(round(cost, digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE)
                  ), vjust = -0.5, position = position_dodge(width = 0.9), size = 5) +
    scale_x_discrete(breaks=c("Median", "p25th", "p75th"),
                     labels=c("Median", "25th", "75th")) +
    scale_fill_brewer(name = "Circuit Size(s) in Mbps", palette = "YlOrRd", direction = -1) +
    geom_hline(yintercept = 0, colour= "#899DA4") +
    coord_cartesian(ylim=c(0, m2)) +
    theme(plot.background = element_rect(fill = "white"),
          panel.background = element_rect(fill = "white"),
          legend.background = element_rect(fill = "white"),
          axis.line = element_blank(), 
          axis.text.x=element_text(size=18, colour= "#636363"), 
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          legend.title = element_text(colour = "#636363"),
          legend.text = element_text(colour = "#636363"),
          legend.position = "top", 
          legend.box = "horizontal",
          text=element_text(size = 16, family="Lato"),
          plot.title = element_text(size = 22, family="MuseoSlabW01-700")) +
    #ggtitle(paste("Price Dispersion: \nMonthly Cost Per Mbps for", input$connection_services, input$purpose, "\n")) +
    guides(fill = guide_legend(title.position="top",
           default.unit = "inch")) 
  
  print(v)
  
})

output$disp_cpm_table <- renderDataTable({

  perc_tab <- sr_all() %>% group_by(bandwidth_in_mbps) %>% 
    summarise(n_services = n(),
              n_circuits = sum(cat.1_allocations_to_district),
              p25th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.25, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              Median = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.50, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""),
              p75th  = paste("$", format(round(quantile(as.numeric(as.character(monthly_cost_per_mbps)), 0.75, na.rm = TRUE), digits = 2), big.mark = ",", nsmall = 2, scientific = FALSE), sep = ""))
  colnames(perc_tab)<- c("Circuit Size (Mbps)" ,"# of Line Items", "# of Circuits", "25th Percentile", "Median", "75th Percentile")
  
  datatable(perc_tab, rownames = FALSE, options = list(paging = FALSE, searching = FALSE))

  })

district_tooltip <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.null(x$recipient_name)) return(NULL)
  all_sr <- isolate(sr_all())
  services_rec <- all_sr[all_sr$recipient_name == x$recipient_name,]
  
  paste0("<b>", "District Name: ", services_rec$recipient_name, "</b><br>",
         "Monthly Cost per Circuit: $", format(services_rec$monthly_cost_per_circuit, big.mark = ",", scientific = FALSE),"<br>",
         "# of Circuits: ", services_rec$quantity_of_lines_received_by_district, "<br>",
         "Connect Type: ", services_rec$new_connect_type, "<br>",
         "Service Provider: ", services_rec$reporting_name, "<br>")
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
        add_legend("fill", title = "") %>% 
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
    add_legend("fill", title = "") %>%         
    set_options(width = 800, height = 500)
    }
  
})

vis %>% bind_shiny("plot1")

output$plot1_table <- renderDataTable({
  
  data <- sr_all() %>%
          select(recipient_id, recipient_name, postal_cd, line_item_id, bandwidth_in_mbps,
                 connect_category, new_connect_type, line_item_district_monthly_cost, line_item_total_monthly_cost, 
                 cat.1_allocations_to_district, line_item_total_num_lines, applicant_id, 
                 applicant_name, reporting_name, monthly_cost_per_circuit, monthly_cost_per_mbps
          )
          
  datatable(data, rownames = FALSE)
  
})


output$text_maps <- renderUI({
    
  text_all <- HTML(paste(h4("MAP OF SCHOOL DISTRICTS"), br(), 
                   p("This map shows the location of all school districts in the United States based on NCES data.
                     You can zoom in on specific districts by clicking on the map."), br()))
  text_clean <- HTML(paste(h4("MAP OF SCHOOL DISTRICTS AND DATA CLEANLINESS STATUS"), br(), 
                     p("This map shows the location of all school districts in the United States and cleanliness of the district data.
                       You can zoom in on specific districts by clicking the map on the right."), br()))
  
  text_2014goals <- HTML(paste(h4("MAP OF SCHOOL DISTRICTS AND MINIMUM GOAL MEETING STATUS"), br(),
                         p("This map shows the location of all school districts and the minimum goal meeting status. 
                           A district is meeting the minimum goal if its total bandwidth is greater than or equal to 100 kbps per student.
                           You can zoom in on specific districts by clicking on the map on the right.")))
  
  text_2018goals <- HTML(paste(h4("MAP OF SCHOOL DISTRICTS AND 2018 GOAL MEETING STATUS"), br(),
                         p("This map shows the location of all school districts and the 2018 FCC goal meeting status. 
                           A district is meeting the 2018 FCC goal if its total bandwidth is greater than or equal to 1 Mbps per student.
                           You can zoom in on specific districts by clicking on the map on the right.")))
  
  text_fiber <- HTML(paste(h4("MAP OF UNSCALABLE SCHOOL DISTRICTS AND FIBER BUILD COSTS"), br(),
                     p("This map shows the location of school districts that have at least one school using unscalable technology. 
                       It also shows whether districts can self-provision fiber with no cost to school districts,
                       assuming availability of a 20% state match fund.
                       You can zoom in on specific districts by clicking on the map on the right."), br()))
  
  switch(input$map_view,
         "All Districts" =  text_all,
         "Clean/Dirty Districts" =  text_clean,
         "Goals: 100 kbps/Student" =  text_2014goals,
         "Goals: 1 Mbps/Student" =  text_2018goals,
         "Fiber Build Cost to Districts" = text_fiber)
  
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
         "All Districts" =  paste("n(districts) =", toString(nrow(data))),
         "Clean/Dirty Districts" =  paste("n(districts) =", toString(nrow(data))),
         'Goals: 100 kbps/Student' =  paste("n(districts) =", toString(nrow(data))),
         'Goals: 1 Mbps/Student' =  paste("n(districts) =", toString(nrow(data))),
         'Fiber Build Cost to Districts' = paste("n(districts) =", toString(nrow(data2))))
})

## Dynamic Viz Testing:

plot2_data <- reactive({

    d_sub <- district_subset() %>% filter(new_connect_type_goals %in% input$connection_districts_goals,
                                          district_size2 %in% input$district_size_goals,
                                          locale2 %in% input$locale_goals)
  
    price <- input$set_price

    
    nmg_data <- d_sub %>% filter(meeting_2014_goal_no_oversub == "Not Meeting Goal") 

    nmg_data2 <- nmg_data %>% mutate(need_kbps = num_students*100,
                                     need_mbps = need_kbps / 1000,
                                     hyp_cost = need_mbps*price,
                                     can_mt_goals = ifelse(hyp_cost <= total_ia_monthly_cost, "Can Meet 100kbps/Student", "Cannot Meet 100kbps/Student"))

    nmg_table <- nmg_data2 %>% group_by(can_mt_goals) %>% summarise(n = n())
    nmg_table <- as.data.frame(na.omit(nmg_table))
    
    can_meet <- nmg_table %>% filter(can_mt_goals == "Can Meet 100kbps/Student")
    
    #districts meeting goals %
    mg <- d_sub %>% filter(meeting_2014_goal_no_oversub == "Meeting Goal")
    pct_mg <- round((nrow(mg)/nrow(d_sub))*100, digits = 2) #63%
    pct_hyp <-  round(((nrow(mg) + can_meet$n) / nrow(d_sub))*100, digits = 2)
    
    med_price <- round(median(mg$monthly_ia_cost_per_mbps, na.rm=TRUE), digits = 2)
    print(med_price)
    
    pct_joined <- c(pct_mg, pct_hyp)
    pct_names <- c("% Districts Currently Meeting Goal", "% Districts Meeting Goal Under Hypothetical Pricing")
    pricing <- c(med_price, input$set_price)
    
    pct_joined2 <- cbind(pct_names, pct_joined, pricing)
    
    pct_joined3 <- as.data.frame(pct_joined2)
    colnames(pct_joined3) <- c("status", "breakdown", "pricing")
    pct_joined3$breakdown <- as.numeric(as.character(pct_joined3$breakdown))
    
    pct_joined3 #added
    print(pct_joined3)
    }) #added


plot2 <- reactive({

      plot2_data() %>%                   
      ggvis(~status, ~breakdown) %>% 
      scale_ordinal('fill', range = c("#fdb913", "#f09221")) %>%
      layer_bars(fill = ~status, strokeWidth := 0) %>% #fillOpacity := 0.4, 
      add_axis("x", title = "Meeting Goals w/ Hypothetical Pricing", title_offset = 50, grid = FALSE) %>% 
      add_axis("y", title = " ", ticks = 0, grid = FALSE, properties = axis_props(axis = list(strokeWidth = 0))) %>%
      scale_numeric("y", domain = c(0, 100)) %>% 
      add_legend("fill", title = "") %>% 
      set_options(width = 850, height = 500)

})



plot2 %>% bind_shiny("hyp_plot")


observe({   
  updateSliderInput(session, "set_price",
                        label = "Pricing $:")
})



output$table_hyp_cost <- renderDataTable({
  
  pct_joined4 <- plot2_data()
  pct_joined4$pct <- paste(format(pct_joined4$breakdown,  nsmall = 2), "%", sep = "")
  pct_joined4$cost <- paste("$", format(pct_joined4$pricing, nsmall=2), sep = "")
  pct_joined5 <- pct_joined4[,-c(2:3)]
  colnames(pct_joined5) <- c("Status", "Goal Meeting Percentage", "Pricing")
  
  validate(need(nrow(pct_joined5) > 0, ""))  
  datatable(pct_joined5, rownames = FALSE, options = list(paging = FALSE, searching = FALSE))
})

# create reset functionality for each tab:

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
    paste('districts_by_ia_tech_dataset', '_20160826', '.csv', sep = '')},
  content = function(file){
    write.csv(districts_ia_tech_data() %>%
                select(nces_cd, name, locale, district_size, num_schools, num_students,
                       frl_percent, address, city, zip, county, postal_cd, latitude, longitude, exclude_from_analysis,
                       ia_bandwidth_per_student, meeting_2014_goal_no_oversub, meeting_2018_goal_oversub,
                       monthly_ia_cost_per_mbps, total_ia_bw_mbps, total_ia_monthly_cost, c1_discount_rate,
                       schools_on_fiber, schools_may_need_upgrades, schools_need_upgrades, not_all_scalable)
              , file, row.names = FALSE)
  }
)

output$fiber_downloadData <- downloadHandler(
  
  filename = function(){
    paste('fiber_dataset', '_20160826', '.csv', sep = '')},
  content = function(file){
    write.csv( fiber_data() %>%
                 select(nces_cd, name, locale, district_size, num_schools, num_students,
                        frl_percent, address, city, zip, county, postal_cd, latitude, longitude, exclude_from_analysis,
                        ia_bandwidth_per_student, meeting_2014_goal_no_oversub, meeting_2018_goal_oversub,
                        monthly_ia_cost_per_mbps, total_ia_bw_mbps, total_ia_monthly_cost, c1_discount_rate,
                        schools_on_fiber, schools_may_need_upgrades, schools_need_upgrades, not_all_scalable), 
               file, row.names = FALSE)
  }
)


output$affordability_downloadData <- downloadHandler(
  filename = function(){
    paste('affordability_dataset', '_20160826
          ', '.csv', sep = '')},
  content = function(file){
    write.csv(sr_all() %>%
                select(recipient_id, recipient_name, postal_cd, line_item_id, bandwidth_in_mbps,
                       connect_category, new_connect_type, line_item_district_monthly_cost, line_item_total_monthly_cost, 
                       cat.1_allocations_to_district, line_item_total_num_lines, applicant_id, 
                       applicant_name, reporting_name, monthly_cost_per_circuit, monthly_cost_per_mbps), 
                       file, row.names = FALSE)
  }
)



output$ESH_logo <- renderImage({
  return(list(
  src = "ESH_logo.png",
  contentType = "image/png"))
  
})


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
        "All Districts" =  data,
        "Clean/Dirty Districts" =  data,
        'Goals: 100 kbps/Student' =  data,
        'Goals: 1 Mbps/Student' =  data,
        'Fiber Build Cost to Districts' = data2,
        'Connect Category' = data)
  
})

output$table_testing <- renderDataTable({
  map_data <- district_subset() %>%
    filter(!(postal_cd %in% c('AK', 'HI')),
           new_connect_type_map %in% input$connection_districts,
           district_size %in% input$district_size_maps,
           locale %in% input$locale_maps) %>%
    select(nces_cd, name, locale, district_size, num_schools, num_students,
           frl_percent, address, city, zip, county, postal_cd, latitude, longitude, exclude_from_analysis,
           ia_bandwidth_per_student, meeting_2014_goal_no_oversub, meeting_2018_goal_oversub,
           monthly_ia_cost_per_mbps, total_ia_bw_mbps, total_ia_monthly_cost, c1_discount_rate,
           schools_on_fiber, schools_may_need_upgrades, schools_need_upgrades, not_all_scalable)
  
  
  
  map_data2 <- map_data %>%
    filter(not_all_scalable == 1)
  
  
  switch(input$map_view,
         "All Districts" =  datatable(map_data),
         "Clean/Dirty Districts" =  datatable(map_data),
         'Goals: 100 kbps/Student' =  datatable(map_data),
         'Goals: 1 Mbps/Student' =  datatable(map_data),
         'Fiber Build Cost to Districts' = datatable(map_data2),
         'Connect Category' = datatable(map_data))
  
})

output$downloadData <- downloadHandler(
  
  filename = function(){
    paste(input$map_view, '_20160826', '.csv', sep = '')},
  content = function(file){
    write.csv(datasetInput_maps() %>%
                select(nces_cd, name, locale, district_size, num_schools, num_students,
                       frl_percent, address, city, zip, county, postal_cd, latitude, longitude, exclude_from_analysis,
                       ia_bandwidth_per_student, meeting_2014_goal_no_oversub, meeting_2018_goal_oversub,
                       monthly_ia_cost_per_mbps, total_ia_bw_mbps, total_ia_monthly_cost, c1_discount_rate,
                       schools_on_fiber, schools_may_need_upgrades, schools_need_upgrades, not_all_scalable), 
              file, row.names = FALSE)
  }
)


#For population maps:

output$downloadMapImage <- downloadHandler(
  filename = function() {paste(input$map_view, '_20160826', '.png', sep='') },
  content = function(file) {
    ggsave(plot = reac_map_pop()$plot, file, type = "cairo-png")
  }

)

#For District Look Up: blank pin point map
output$downloadDistrictLookup <- downloadHandler(
  filename = function() {paste(input$map_view, '_20160826', '.png', sep='') },
  content = function(file) {
    ggsave(plot = reac_map_lookup()$plot, file, type = "cairo-png")
  }
  
)


####################################


}) #closing shiny server function
