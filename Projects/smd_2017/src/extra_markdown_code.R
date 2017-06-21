
## click-though data
#districts.16.click.through <- read.csv("data/current16_districts_click_through.csv", as.is=T, header=T, stringsAsFactors=F)
#districts.17.click.through <- read.csv("data/current17_districts_click_through.csv", as.is=T, header=T, stringsAsFactors=F)
#conn.click.through <- read.csv("data/connectivity_click_through.csv", as.is=T, header=T, stringsAsFactors=F)
#fiber.click.through <- read.csv("data/fiber_click_through.csv", as.is=T, header=T, stringsAsFactors=F)
#affordability.click.through <- read.csv("data/affordability_click_through.csv", as.is=T, header=T, stringsAsFactors=F)

## fiber targets list
#conn.targets <- read.csv("data/connectivity_targets.csv", as.is=T, header=T, stringsAsFactors=F)
#fiber.targets <- read.csv("data/fiber_targets.csv", as.is=T, header=T, stringsAsFactors=F)

## list of districts that upgraded
#districts_upgraded <- read.csv("data/districts_upgraded.csv", as.is=T, header=T, stringsAsFactors=F)

## snapshot data
#snapshots <- read.csv("data/snapshots.csv", as.is=T, header=T, stringsAsFactors=F)

## date info
#date <- read.csv("data/date.csv", as.is=T, header=T, stringsAsFactors=F)




#sots16_dd <- reactive({sots.districts.2016 %>% filter(postal_cd %in% input$state)})
#current16_dd <- reactive({current16_districts %>% filter(exclude_from_ia_analysis == FALSE & postal_cd %in% input$state)})
#current16_dd_all <- reactive({dd.2017 %>% filter(postal_cd %in% input$state)})

## districts deluxe by connectivity status
## current '16: districts deluxe IA subset
#current16_dd_ia <- reactive({current16_districts_ia %>% filter(postal_cd %in% input$state)})
## current '16: districts deluxe WAN subset
#current16_dd_wan <- reactive({current16_districts_wan %>% filter(postal_cd %in% input$state)})
## current '16: districts deluxe IA cost subset
#current16_dd_ia_cost <- reactive({current16_districts_ia_cost %>% filter(postal_cd %in% input$state)})
## current '16: districts deluxe WAN cost subset
#current16_dd_wan_cost <- reactive({current16_districts_wan_cost %>% filter(postal_cd %in% input$state)})
## current '16: districts deluxe fiber subset
#current16_dd_fiber <- reactive({current16_districts_fiber %>% filter(postal_cd %in% input$state)})

## districts deluxe by meeting goals
## sots '16: districts meeting goals
#sots16_mg <- reactive({sots16_dd() %>% filter(meeting_2014_goal_no_oversub == TRUE)})
## current '16: districts meeting goals
#c16_mg <- reactive({current16_dd() %>% filter(meeting_2014_goal_no_oversub == TRUE)})
## current '16: districts IA meeting goals
#c16_ia_mg <- reactive({current16_dd_ia() %>% filter(meeting_2014_goal_no_oversub == TRUE)})
## current '16: districts IA NOT meeting goals
#c16_ia_nmg <- reactive ({current16_dd_ia() %>% filter(meeting_2014_goal_no_oversub == FALSE)})

## districts upgraded table 
#districts_up <- reactive({districts_upgraded %>% filter(postal_cd %in% input$state)})


## target lists
#tl_sub <- reactive({target_list %>% filter(postal_cd %in% input$state)})
#tl_conn_sub <- reactive({conn.targets %>% filter(postal_cd %in% input$state)})
#tl_fiber_sub <- reactive({fiber.targets %>% filter(postal_cd %in% input$state)})

## click-though data
#cl_16_districts <- reactive({ districts.16.click.through %>% filter(postal_cd %in% input$state) })
#cl_16_districts <- reactive({ districts.16.click.through %>% filter(postal_cd %in% input$state) })
#cl_conn_sub <- reactive({ conn.click.through %>% filter(postal_cd %in% input$state) })
#cl_fiber_sub <- reactive({ fiber.click.through %>% filter(postal_cd %in% input$state) })
#cl_affordability_sub <- reactive({ affordability.click.through %>% filter(postal_cd %in% input$state) })



Deep Dive Upgrades {.hidden data-orientation=rows}
===========================================================================
Row
---------------------------------------------------------------------
```{r}

#output$downloadData_upgrades <- downloadHandler(
#  filename = function() { paste('upgrades_deep_dive.csv') },
#  content = function(file) {
#      write.csv(districts_up(), file, row.names=F)
#  })
# downloadLink("downloadData_upgrades", label = "Download Table")

renderDataTable({
  datatable(districts_up(), rownames = FALSE, escape = FALSE, options = list(paging = TRUE, searching = TRUE, scrollX=TRUE))
})
```


Deep Dive Connectivity {.hidden data-orientation=rows}
=====================================================================
  Row 
---------------------------------------------------------------------
  ### 
  ```{r}
renderValueBox({
  valueBox(state_name_caps)
})
```

### Current 2016 Districts Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_districts_mtg2014goal, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_districts_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = '#009296')
})
```

### Current 2016 Schools Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_schools_mtg2014goal, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_schools_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = colors$color[colors$label == 'schools'])
})
```

### Current 2016 Students Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_students_mtg2014goal, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_students_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = colors$color[colors$label == 'students'])
})
```

Row
---------------------------------------------------------------------
  ```{r}
#output$downloadData_connectivity <- downloadHandler(
#  filename = function() { paste('connectivity_deep_dive.csv') },
#  content = function(file) {
#    write.csv(cl_conn_sub(), file, row.names=F)
#  })
#downloadLink("downloadData_connectivity", label = "Download Table")

renderDataTable({
  datatable(cl_conn_sub(), rownames = FALSE, escape = FALSE, options = list(paging = TRUE, searching = TRUE, scrollX=TRUE))
})
```


Deep Dive Fiber {.hidden data-orientation=columns}
=====================================================================
  Column
---------------------------------------------------------------------
  ```{r}
#output$downloadData_fiber <- downloadHandler(
#  filename = function() { paste('fiber_deep_dive.csv') },
#  content = function(file) {
#    write.csv(cl_fiber_sub(), file, row.names=F)
#  })
#downloadLink("downloadData_fiber", label = "Download Table")

renderDataTable({
  datatable(cl_fiber_sub(), rownames = FALSE, escape = FALSE, options = list(paging = TRUE, searching = TRUE, scrollX=TRUE))
})
```


Deep Dive Affordability {.hidden data-orientation=rows}
=====================================================================
  Row 
---------------------------------------------------------------------
  ### 
  ```{r}
renderValueBox({
  valueBox(state_name_caps)
})
```

### Current 2016 Districts Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_districts_mtg_affordability, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_districts_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = '#009296')
})
```

### Current 2016 Schools Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_schools_mtg_affordability, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_schools_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = colors$color[colors$label == 'schools'])
})
```

### Current 2016 Students Meeting Goal
```{r}
renderValueBox({
  val1 <- format(sm_sub()$current16_students_mtg_affordability, big.mark = ",", nsmall = 0, scientific = FALSE)
  val2 <- format(sm_sub()$current16_students_sample, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(paste(val1, val2, sep=' / '), color = colors$color[colors$label == 'students'])
})
```

Row
---------------------------------------------------------------------
  ###
  ```{r}
#output$downloadData_affordability <- downloadHandler(
#  filename = function() { paste('affordability_deep_dive.csv') },
#  content = function(file) {
#    write.csv(cl_affordability_sub(), file, row.names=F)
#  })
#downloadLink("downloadData_affordability", label = "Download Table")

renderDataTable({
  datatable(cl_affordability_sub(), rownames = FALSE, escape = FALSE, options = list(paging = TRUE, searching = TRUE, scrollX=TRUE))
})
```



Target Lists Connectivity {.hidden data-orientation=rows}
============================================================================
  ### Targets and Potential Targets
  ```{r}
## want to filter target list by subject (e.g. connectivity, affordability, etc) and state
#tl_sub2 <<- reactive({ tl_sub() %>% filter(bw_target_status == "Target") })

output$downloadData_connectivity <- downloadHandler(
  filename = function() { paste('connectivity_target_list.csv') },
  content = function(file) {
    write.csv(tl_conn_sub(), file, row.names=F)
  })
downloadLink("downloadData_connectivity", label = "Download Table")

renderDataTable({
  datatable(tl_conn_sub(), rownames = FALSE, escape = FALSE, options = list(paging = TRUE, searching = TRUE, scrollX=TRUE))
})
```


Target Lists Fiber {.hidden data-orientation=rows}
============================================================================
  
  ### Targets and Potential Targets
  ```{r}
## want to filter target list by subject (e.g. connectivity, affordability, etc) and state
#tl_sub3 <<- reactive({ tl_sub() %>% filter(fiber_target_status == "Target") })

output$downloadData_fiber <- downloadHandler(
  filename = function() { paste('fiber_target_list.csv') },
  content = function(file) {
    write.csv(tl_fiber_sub(), file, row.names=F)
  })
downloadLink("downloadData_fiber", label = "Download Table")

#tagList(
#singleton(tags$head(tags$script(src='//cdn.datatables.net/fixedheader/2.1.2/js/dataTables.fixedHeader.min.js',type='text/javascript'))),
#singleton(tags$head(tags$link(href='//cdn.datatables.net/fixedheader/2.1.2/css/dataTables.fixedHeader.css',rel='stylesheet',type='text/css')))
#)

renderDataTable({
  datatable(tl_fiber_sub(), rownames = FALSE, escape = FALSE, #callback='function(oTable) { new FixedHeader(oTable); }',
            options = list(paging = TRUE, searching = TRUE, scrollX=TRUE, fixed=TRUE))
})
```


National Overview {data-orientation=rows}
=================================================================================================
  Row
-------------------------------------------------------------------------------------------------
  ### Cleanliness Ranking (order of states in decreasing order of cleanliness percentage) 
  ```{r}
state_metrics_clean <- arrange(state_metrics, desc(current16_districts_sample_perc)) 

highchart() %>% 
  hc_chart(type = 'column') %>% 
  hc_xAxis(categories = state_metrics_clean$postal_cd) %>% 
  hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
  hc_add_series(data = state_metrics_clean$current15_districts_sample_perc, 
                name = "Current 2016 Cleanliness") %>% 
  hc_add_series(data = state_metrics_clean$current16_districts_sample_perc, 
                name = "Current 2016 Cleanliness") %>% 
  hc_legend(enabled = FALSE) %>%
  hc_tooltip(crosshairs = TRUE, backgroundColor = "white", shared = TRUE, borderWidth = 3)  %>%  
  hc_colors(c(colors$color[colors$label == 'ranking_2016'], colors$color[colors$label == 'ranking_2016']))
```

Row
-----------------------------------------------------------------------------------------------
  ### Connectivity National Ranking 
  ```{r}
state_metrics_conn <- arrange(state_metrics, connectivity_rank_unweighted) 

highchart() %>% 
  hc_chart(type = 'column') %>% 
  hc_xAxis(categories = state_metrics_conn$postal_cd) %>% 
  hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
  hc_add_series(data = state_metrics_conn$sots15_districts_mtg2014goal_perc,
                name = "SotS 2016 % Districts Meeting 2014 Goal") %>% 
  hc_add_series(data = state_metrics_conn$current16_districts_mtg2014goal_perc,
                name = "Current 2016 % Districts Meeting 2014 Goal") %>% 
  hc_legend(enabled = FALSE) %>%
  hc_tooltip(crosshairs = TRUE, backgroundColor = "white", shared = TRUE, borderWidth = 3)  %>%  
  hc_colors(c(colors$color[colors$label == 'ranking_2016'], colors$color[colors$label == 'ranking_2016']))
```

Row
-----------------------------------------------------------------------------------------------
  ### Fiber National Ranking 
  ```{r}
state_metrics_fiber <- state_metrics %>% select(postal_cd, fiber_rank_weighted,
                                                fiber_rank_unweighted, sots15_campuses_on_fiber_perc,
                                                current15_campuses_on_fiber, current15_campuses_on_fiber_perc,
                                                current16_campuses_on_fiber, current16_campuses_on_fiber_perc) %>% arrange(fiber_rank_unweighted)

highchart() %>% 
  hc_chart(type = "column") %>% 
  hc_xAxis(categories = as.character(state_metrics_fiber$postal_cd)) %>%
  hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>%
  hc_add_series(data = state_metrics_fiber$sots15_campuses_on_fiber_perc,
                name = "SotS 2016: % District Meeting Affordability Goal") %>% 
  hc_add_series(data = state_metrics_fiber$current16_campuses_on_fiber_perc,
                name =  "Current 2016: % District Meeting Affordability Goal") %>%
  #hc_series(list(name = "SotS 2016: % Campuses on Fiber",
  #               data = state_metrics_fiber$current15_campuses_on_fiber_perc), 
  #           list(name = "Current 2016: % Campuses on Fiber", 
  #                data = state_metrics_fiber$current16_campuses_on_fiber_perc)) %>%
  hc_legend(enabled = FALSE) %>%
  hc_tooltip(crosshairs = TRUE, backgroundColor = "white", shared = TRUE, borderWidth = 3)  %>%
  hc_colors(c(colors$color[colors$label == 'ranking_2016'], colors$color[colors$label == 'ranking_2016']))
```

Row
-----------------------------------------------------------------------------------------------
  ### Affordability National Ranking
  ```{r}
state_metrics_afford <- state_metrics %>% select(postal_cd, affordability_rank_weighted,
                                                 affordability_rank_unweighted,
                                                 sots15_districts_mtg_affordability,
                                                 sots15_districts_mtg_affordability_perc,
                                                 current15_districts_mtg_affordability,
                                                 current15_districts_mtg_affordability_perc,
                                                 current16_districts_mtg_affordability,
                                                 current16_districts_mtg_affordability_perc) %>% arrange(affordability_rank_unweighted)

highchart() %>% 
  hc_chart(type = 'column') %>% 
  hc_xAxis(categories = state_metrics_afford$postal_cd) %>% 
  hc_yAxis(title = list(text = 'percent'), min = 0, max = 100) %>% 
  hc_add_series(data = state_metrics_afford$current15_districts_mtg_affordability_perc,
                name = "Current 2016: % District Meeting Affordability Goal") %>% 
  hc_add_series(data =state_metrics_afford$current16_districts_mtg_affordability_perc,
                name =  "Current 2016: % District Meeting Affordability Goal") %>% 
  hc_legend(enabled = FALSE) %>%
  hc_tooltip(crosshairs = TRUE, backgroundColor = "white", shared = TRUE, borderWidth = 3)  %>%
  hc_colors(c(colors$color[colors$label == 'ranking_2016'], colors$color[colors$label == 'ranking_2016']))
```


Press Stories (Rural) {data-orientation=rows}
=================================================================================================
  Row 
----------------------------------------------------------------------
  ### 
  ```{r}
renderValueBox({
  ## state lookup
  state_lookup <- data.frame(cbind(name = state_metrics$state_name), code=state_metrics$postal_cd, stringsAsFactors = F)
  state_lookup$name_caps <- toupper(state_lookup$name)
  ## making this global so we can use it in other sections as well
  state_name_caps <<- state_lookup$name_caps[state_lookup$code == sm_sub()$postal_cd]
  valueBox(state_name_caps)
})
```

### 2016 Population of Districts {.no-padding}
```{r}
renderValueBox({
  pop.districts.16 <- format(sm_sub()$current16_districts_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.districts.16, color = colors$color[colors$label == 'districts'])
})
```

### 2016 Population of Schools {.no-padding}
```{r}
renderValueBox({
  pop.schools.16 <- format(sm_sub()$current16_schools_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.schools.16, color = colors$color[colors$label == 'schools'])
})
```

### 2016 Population of Students {.no-padding}
```{r}
renderValueBox({
  pop.students.16 <- format(sm_sub()$current16_students_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.students.16, color = colors$color[colors$label == 'students'])
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### All Districts Upgraded {.no-padding}
  ```{r}
renderPlot({
  text <- format(sm_sub()$num_upgrades_bw_increase, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_overlapping_districts, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_upgrades_bw_increase / sm_sub()$num_overlapping_districts)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(92/255, 0/255, 92/255, 0.8)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### All Schools Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_schools_upgraded, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_schools_eligible_upgrade, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_schools_upgraded / sm_sub()$num_schools_eligible_upgrade)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(133/255, 50/255, 133/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### All Students Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_students_upgraded, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_students_eligible_upgrade, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_students_upgraded / sm_sub()$num_students_eligible_upgrade)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill = rgb(178/255, 102/255, 178/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```  

Row {data-height=350}
------------------------------------------------------------------------
  ### Rural Districts Upgraded {.no-padding}
  ```{r}
renderPlot({
  text <- format(sm_sub()$num_upgrades_bw_increase_rural, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_overlapping_districts_rural, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_upgrades_bw_increase_rural / sm_sub()$num_overlapping_districts_rural)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(92/255, 0/255, 92/255, 0.8)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### Rural Schools Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_schools_upgraded_rural, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_schools_eligible_upgrade_rural, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_schools_upgraded_rural / sm_sub()$num_schools_eligible_upgrade_rural)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(133/255, 50/255, 133/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### Rural Students Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_students_upgraded_rural, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_students_eligible_upgrade_rural, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_students_upgraded_rural / sm_sub()$num_students_eligible_upgrade_rural)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill = rgb(178/255, 102/255, 178/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```  

Row {data-height=350}
------------------------------------------------------------------------
  ### Rural Districts Meeting Connectivity Goals
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>%
    #,paste('Current 2016 with 2016 clean (n=', format(sm_sub()$current16_with_current15_districts_sample, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_districts_mtg2014goal_perc_rural,
                           sm_sub()$current15_districts_mtg2014goal_perc_rural,
                           sm_sub()$current16_districts_mtg2014goal_perc_rural),
                  #,sm_sub()$current16_with_current15_districts_mtg2014goal_perc),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'connectivity1']))
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'connectivity2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### [Connectivity National Ranking](#national-overview){.no-padding}
```{r}
renderPlot({
  text <- paste('#', sm_sub()$connectivity_rank_unweighted, sep = '')
  text2 <- paste('previous ranking: ', '#', sep='')
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 15, color = "white") +
    annotate("text",  x = 2.5, y = 24.85, label = "(unweighted)", size = 10, color = "white") +
    annotate("text",  x = 2.5, y = 24.55, label = text2, size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'connectivity3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Rural Campuses on Fiber
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_pop_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_campuses_on_fiber_perc_rural,
                           sm_sub()$current15_campuses_on_fiber_perc_rural,
                           sm_sub()$current16_campuses_on_fiber_perc_rural),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'fiber1']))
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'fiber2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### [Fiber National Ranking](#national-overview) {.no-padding}
```{r}
renderPlot({
  text <- paste('#', sm_sub()$fiber_rank_unweighted, sep = '')
  text2 <- paste('previous ranking: ', '#', sep='')
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 15, color = "white") +
    annotate("text",  x = 2.5, y = 24.85, label = "(unweighted)", size = 10, color = "white") +
    annotate("text",  x = 2.5, y = 24.55, label = text2, size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'fiber3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Rural Districts Meeting Affordability Goal
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_sample_rural, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_districts_mtg_affordability_perc,
                           sm_sub()$current15_districts_mtg_affordability_perc,
                           sm_sub()$current16_districts_mtg_affordability_perc),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'affordability1'])) 
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'affordability2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### [Affordability National Ranking](#national-overview) {.no-padding}
```{r}
renderPlot({
  text <- paste('#', sm_sub()$affordability_rank_unweighted, sep = '')
  text2 <- paste('previous ranking: ', '#', sep='')
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 15, color = "white") +
    annotate("text",  x = 2.5, y = 24.85, label = "(unweighted)", size = 10, color = "white") +
    annotate("text",  x = 2.5, y = 24.55, label = text2, size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'affordability3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Number of Rural Districts with Adequate Wifi {.no-padding}
  ```{r}
renderPlot({
  text <- text <- format(sm_sub()$current16_districts_with_wifi_rural, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$current16_districts_answered_wifi_rural, big.mark = ",", nsmall = 0, scientific = FALSE), " (", sm_sub()$current16_districts_with_wifi_perc_rural, "%", ")", sep="")
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.85, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi1']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "Ranking Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```


Press Stories (Urban) {data-orientation=rows}
=================================================================================================
  Row 
----------------------------------------------------------------------
  ### 
  ```{r}
## dataset: state metrics  - reactive
renderValueBox({
  ## state lookup
  state_lookup <- data.frame(cbind(name = state_metrics$state_name), code=state_metrics$postal_cd, stringsAsFactors = F)
  state_lookup$name_caps <- toupper(state_lookup$name)
  ## making this global so we can use it in other sections as well
  state_name_caps <<- state_lookup$name_caps[state_lookup$code == sm_sub()$postal_cd]
  valueBox(state_name_caps)
})
```

### 2016 Population of Districts {.no-padding}
```{r}
renderValueBox({
  pop.districts.16 <- format(sm_sub()$current16_districts_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.districts.16, color = colors$color[colors$label == 'districts'])
})
```

### 2016 Population of Schools {.no-padding}
```{r}
renderValueBox({
  pop.schools.16 <- format(sm_sub()$current16_schools_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.schools.16, color = colors$color[colors$label == 'schools'])
})
```

### 2016 Population of Students {.no-padding}
```{r}
renderValueBox({
  pop.students.16 <- format(sm_sub()$current16_students_pop, big.mark = ",", nsmall = 0, scientific = FALSE)
  valueBox(pop.students.16, color = colors$color[colors$label == 'students'])
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### All Districts Upgraded {.no-padding}
  ```{r}
renderPlot({
  text <- format(sm_sub()$num_upgrades_bw_increase, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_overlapping_districts, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_upgrades_bw_increase / sm_sub()$num_overlapping_districts)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(92/255, 0/255, 92/255, 0.8)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### All Schools Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_schools_upgraded, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_schools_eligible_upgrade, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_schools_upgraded / sm_sub()$num_schools_eligible_upgrade)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(133/255, 50/255, 133/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### All Students Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_students_upgraded, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_students_eligible_upgrade, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_students_upgraded / sm_sub()$num_students_eligible_upgrade)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill = rgb(178/255, 102/255, 178/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```  

Row {data-height=350}
------------------------------------------------------------------------
  ### Urban Districts Upgraded {.no-padding}
  ```{r}
renderPlot({
  text <- format(sm_sub()$num_upgrades_bw_increase_urban, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_overlapping_districts_urban, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_upgrades_bw_increase_urban / sm_sub()$num_overlapping_districts_urban)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill =  rgb(92/255, 0/255, 92/255, 0.8)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### Urban Schools Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_schools_upgraded_urban, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_schools_eligible_upgrade_urban, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_schools_upgraded_urban / sm_sub()$num_schools_eligible_upgrade_urban)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    #theme(panel.background = element_rect(fill = "#fbe9bc"),
    theme(panel.background = element_rect(fill =  rgb(133/255, 50/255, 133/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### Urban Students Upgraded {.no-padding}
```{r}
renderPlot({
  text <- format(sm_sub()$num_students_upgraded_urban, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$num_students_eligible_upgrade_urban, big.mark = ",", nsmall = 0, scientific = FALSE),
                 " (", round((sm_sub()$num_students_upgraded_urban / sm_sub()$num_students_eligible_upgrade_urban)*100, 0), "%", ")", sep='')
  
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 17, color = "white") +
    annotate("text",  x = 2.5, y = 24.65, label = text2, size = 12, color = "white") +
    theme(panel.background = element_rect(fill = rgb(178/255, 102/255, 178/255, 0.9)),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```  

Row {data-height=350}
------------------------------------------------------------------------
  ### Urban Districts Meeting Connectivity Goals
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>%
    #,paste('Current 2016 with 2016 clean (n=', format(sm_sub()$current16_with_current15_districts_sample, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_districts_mtg2014goal_perc_urban,
                           sm_sub()$current15_districts_mtg2014goal_perc_urban,
                           sm_sub()$current16_districts_mtg2014goal_perc_urban),
                  #,sm_sub()$current16_with_current15_districts_mtg2014goal_perc),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'connectivity1']))
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'connectivity2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "Ranking Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'connectivity3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Urban Campuses on Fiber
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_pop_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_campuses_on_fiber_perc_urban,
                           sm_sub()$current15_campuses_on_fiber_perc_urban,
                           sm_sub()$current16_campuses_on_fiber_perc_urban),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'fiber1']))
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'fiber2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "Ranking Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'fiber3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Urban Districts Meeting Affordability Goal
  ```{r}
renderHighchart({
  highchart() %>% 
    hc_chart(type = 'column') %>% 
    hc_xAxis(categories = c(paste('SotS 2016 (n=', format(sm_sub()$sots15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current15_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''),
                            paste('Current 2016 (n=', format(sm_sub()$current16_districts_sample_urban, big.mark = ",", nsmall = 0, scientific = FALSE), ')', sep=''))) %>% 
    hc_yAxis(labels = list(format = '{value}%'), min = 0, max = 100) %>% 
    hc_add_series(data = c(sm_sub()$sots15_districts_mtg_affordability_perc,
                           sm_sub()$current15_districts_mtg_affordability_perc,
                           sm_sub()$current16_districts_mtg_affordability_perc),
                  dataLabels = list(enabled = TRUE,
                                    format = '{point.y}%')) %>% 
    hc_legend(enabled = FALSE) %>%
    hc_colors(c(colors$color[colors$label == 'affordability1'])) 
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'affordability2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "Ranking Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'affordability3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

Row {data-height=350}
------------------------------------------------------------------------
  ### Number of Urban Districts with Adequate Wifi {.no-padding}
  ```{r}
renderPlot({
  text <- text <- format(sm_sub()$current16_districts_with_wifi_urban, big.mark = ",", nsmall = 0, scientific = FALSE)
  text2 <- paste("of ", format(sm_sub()$current16_districts_answered_wifi_urban, big.mark = ",", nsmall = 0, scientific = FALSE), " (", sm_sub()$current16_districts_with_wifi_perc_urban, "%", ")", sep="")
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = text, size = 20, color = "white") +
    annotate("text",  x = 2.5, y = 24.85, label = text2, size = 15, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi1']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "SP Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi2']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

### 
```{r}
renderPlot({
  ggplot() + 
    ylim(24, 26) +
    annotate("text",  x = 2.5, y = 25.15, label = "Ranking Placeholder", size = 10, color = "white") +
    theme(panel.background = element_rect(fill = colors$color[colors$label == 'wifi3']),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank())
})
```

