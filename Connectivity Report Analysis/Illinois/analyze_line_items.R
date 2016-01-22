# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "ggplot2", "RColorBrewer", "raster", "maps", "mapproj", "gridExtra", "reshape2", "scales", "tidyr")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Google Drive/R/Illinois CR/data/export/for_graphing")

# load csvs
line <- read.csv("~/Google Drive/R/Illinois CR/data/mode/line_items_20160105.csv", as.is = TRUE)
deluxe <- read.csv("~/Google Drive/R/Illinois CR/data/mode/deluxe_districts_20160105.csv", as.is = TRUE)
counties <- read.csv("~/Google Drive/R/Illinois CR/data/mode/il_county_names.csv", as.is = TRUE)

# limit to clean data
line <- filter(line, exclude == FALSE)
# limit to clean districts!
line <- line[line$nces_cd %in% deluxe$nces_cd, ]

# order the locale/district_size factor in a logical way
line$locale <- factor(line$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
line$district_size <- factor(line$district_size, levels = c("Tiny", "Small", "Medium", "Large", "Mega"))

 # create columns and conditions
# cost_per_line: (total_cost / num_lines) / 12 * monthly measure
line$monthly_cost_per_line <- (line$total_cost / line$num_lines) /12

# cost_per_line_mbps: normalize by bandwidth
line$monthly_cost_per_mbps <- line$monthly_cost_per_line / line$bandwidth_in_mbps

# total_bandwidth
line$total_bandwidth_in_mbps <- line$bandwidth_in_mbps * line$num_lines

# new district_size
#line$district_size_new <- ifelse(line$district_size %in% c("Tiny", "Small"), "Small", as.character(line$district_size))
#line$district_size_new <- factor(line$district_size_new, levels = c("Small", "Medium", "Large", "Mega"))

# which conditions
ia <- which(line$internet_conditions_met == TRUE)
wan <- which(line$wan_conditions_met == TRUE)
#upstream <- which(line$upstream_conditions_met == TRUE)

# merge county names
# merge county name data to deluxe table
#line <- merge(line, counties, all.x = TRUE, all.y = FALSE, by = c("nces_cd"))

# merge goal information
#deluxe <- dplyr::select(deluxe, nces_cd, goal_2014 = meeting_2014_goal_no_oversub, ia_cost_per_mbps)

#line <- merge(line, deluxe, all.x = TRUE, all.y = FALSE, by = c("nces_cd"))

# simplify county names
##line$county <- tolower(gsub(" .*$", "", line$CONAME))
#line$CONAME <- NULL

# for mapping -- import Illinois map by county
#usa <- getData('GADM', country="USA", level=2)
#il_map <- usa[usa$NAME_1 == "Illinois",] 
#il_map@data$id <- rownames(il_map@data)
#il_df <- merge(il_map@data, fortify(il_map), by = "id", all.y = TRUE)
#il_df <- il_df[,c("NAME_2", "long", "lat", "group")]
#names(il_df) <- c("county", "long", "lat", "group")
#il_df$county <- tolower(il_df$county)

### analyses
 # IA cost analyses per line / per line and per mbps

target_cost <-
line[ia,] %>%
  summarize(q25 = quantile(monthly_cost_per_mbps, 0.25),
            median = median(monthly_cost_per_mbps),
            q75 = quantile(monthly_cost_per_mbps, 0.75))

target_cost <- melt(target_cost)
target_cost <- cbind(target_cost, rep(3, 3), rep(4, 3))
names(target_cost) <- c("measure", "cost", "target", "national_q25")
# export
write.csv(target_cost, "target_cost.csv", row.names = FALSE)

# cut by locale and size for all items in IA

cost_by_locale_size <-
  line[line$internet_conditions_met == TRUE & line$connect_category == "Fiber", ] %>%
  group_by(district_size, locale) %>%
  summarize(n = n(),
            #min = min(monthly_cost_per_line_mbps),
            #q25 = quantile(monthly_cost_per_line_mbps, 0.25),
            median = median(monthly_cost_per_mbps))
            #q75 = quantile(monthly_cost_per_line_mbps, 0.75),
            #q90 = quantile(monthly_cost_per_line_mbps, 0.90),
            #max = max(monthly_cost_per_line_mbps))


#median_cost <- data.frame(spread(cost_by_locale_size[, c("locale", "n", "district_size", "median")], locale, median))
write.csv(cost_by_locale_size, "median_locale_size_all_ia.csv", row.names = FALSE)

# for 100 mbps lit fiber only
cost_by_locale_size <-
  line[line$connect_category == "Fiber" &
         line$purpose == "Internet" &
         line$bandwidth_in_mbps == 100, ] %>%
  group_by(district_size, locale) %>%
  summarize(n = n(),
            median = median(monthly_cost_per_line_mbps))


# WAN cost per circuit
target_cost <-
  line[wan,] %>%
  summarize(q25 = quantile(monthly_cost_per_line, 0.25),
            median = median(monthly_cost_per_line),
            q75 = quantile(monthly_cost_per_line, 0.75))

target_cost <- melt(target_cost)
target_cost <- cbind(target_cost, rep(750), rep(690, 3))
names(target_cost) <- c("measure", "cost", "target", "national_q25")

# export
write.csv(target_cost, "wan_cost.csv", row.names = FALSE)

# goal vs. affordability

line[ia,] %>%
  group_by(goal_2014) %>%
  summarize(weighted_avg_cost = weighted.mean(ia_cost_per_mbps, total_bandwidth_in_mbps))
  
  summarize(weighted_avg = sum(total_cost / 12) / sum(total_bandwidth_in_mbps))
              

target_cost <- melt(target_cost)
target_cost <- cbind(target_cost, rep(750), rep(690, 3))
names(target_cost) <- c("measure", "cost", "target", "national_q25")


(line$total_cost / 12) / line$total_bandwidth_in_mbps



# exploratory map
ggplot() + 
  geom_polygon(data = il_df, aes(x = long, y = lat, group = group), fill = "white") +
  geom_point(data = map_data, aes(x = longitude, y = latitude, size = monthly_cost_per_line_mbps), color = "#fdb913", alpha = 0.5) +
  #scale_color_manual(name = "", values = c("#4a4a4a", "#fdb913"), breaks = c(0, 1), labels = c("no e-rate", "e-rate")) +
  theme(panel.background = element_rect(fill = 'white', colour = 'white'),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  borders("county", colour="black", alpha = 0.5, size = 0.1, region = "illinois") +
  theme(legend.position = "bottom")


# d







# filter down to most common bandwidth -- 100, 2000, 1000 mbps
 # Lit Fiber
  # condition IA == TRUE
  #  connect: Lit Fiber
  # ETHERNET >= 150 mb

sub <- filter(line[ia, ], bandwidth_in_mbps %in% c(100, 200, 1000) & 
                (connect_type == "Lit Fiber Service" | (connect_type == "Ethernet" & bandwidth_in_mbps >= 150)))


  sum <- 
    sub %>%
    group_by(bandwidth_in_mbps) %>%
    summarize(#min = min(monthly_cost_per_line),
              n = n(),
              q25 = quantile(monthly_cost_per_line, probs = 0.25),
              median = median(monthly_cost_per_line),
              q75 = quantile(monthly_cost_per_line, probs = 0.75)
              #max = max(monthly_cost_per_line)
              )
  
  sum <- melt(sum, id.var = c("bandwidth_in_mbps", "n"))
  sum$stat <- factor(sum$variable, levels = c("q25", "median", "q75"))
  sum$bandwidth_in_mbps <- factor(sum$bandwidth_in_mbps, levels = c("100", "200", "1000"))
    sum$label <- paste0("$", prettyNum(round(sum$value, 0), big.mark = ",", scientific = FALSE))
  
  p_bars <-  
    
    ggplot() + 
             geom_bar(data = sum, aes(x = stat, y = value, order = stat, fill = bandwidth_in_mbps), position = 'dodge', stat = 'identity') +
             geom_text(data = sum, aes(x = stat, y = value, label = label, vjust = 0)) +
            scale_fill_brewer(palette = "YlGnBu") +
              #cale_fill_manual(name = "Bandwidth in MBPS") +
             theme(legend.position = "bottom",
                  panel.background = element_rect(fill = 'white', colour = 'white'),
                  axis.line.y = element_blank(),
                  axis.ticks = element_blank(),
                  axis.line.x = element_line(size = 0.5, colour = "black"),
                  panel.grid.major = element_blank(), 
                  panel.grid.minor = element_blank(),
                  panel.border = element_blank(),
                  axis.title = element_blank(),
                  axis.text.y = element_blank()) +
                  scale_x_discrete(expand = c(0,0), labels = c("25th Quartile", "Median", "75th Quartile")) 


p_bars <- p_bars + ggtitle("Monthly Cost per Circuit for Lit Fiber\nPrice labels must be Fixed")


### normalized to per mbps
## sigh. I'm sad this isn't a function

sum2 <- 
  sub %>%
  group_by(bandwidth_in_mbps) %>%
  summarize(#min = min(monthly_cost_per_line),
    n = n(),
    q25 = quantile(monthly_cost_per_line_mbps, probs = 0.25),
    median = median(monthly_cost_per_line_mbps),
    q75 = quantile(monthly_cost_per_line_mbps, probs = 0.75)
    #max = max(monthly_cost_per_line)
  )

sum2 <- melt(sum2, id.var = c("bandwidth_in_mbps", "n"))
sum2$stat <- factor(sum2$variable, levels = c("q25", "median", "q75"))
sum2$bandwidth_in_mbps <- factor(sum2$bandwidth_in_mbps, levels = c("100", "200", "1000"))
sum2$label <- paste0("$", prettyNum(round(sum2$value, 0), big.mark = ",", scientific = FALSE))

p_bars2 <-  
  
  ggplot() + 
  geom_bar(data = sum2, aes(x = stat, y = value, order = stat, fill = bandwidth_in_mbps), position = 'dodge', stat = 'identity') +
  geom_text(data = sum2, aes(x = stat, y = value, label = label, vjust = 0)) +
  scale_fill_brewer(palette = "YlGnBu") +
  #scale_fill_manual(name = "Bandwidth in MBPS", values = c("#FA8072", "#20B2AA", "#FFFFCC")) +
  theme(legend.position = "bottom",
        panel.background = element_rect(fill = 'white', colour = 'white'),
        axis.line.y = element_blank(),
        axis.ticks = element_blank(),
        axis.line.x = element_line(size = 0.5, colour = "black"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.title = element_blank(),
        axis.text.y = element_blank()) +
  scale_x_discrete(expand = c(0,0), labels = c("25th Quartile", "Median", "75th Quartile")) 


p_bars2 <- p_bars2 + ggtitle("Monthly Cost per Circuit for Lit Fiber -- per MBPS\nPrice labels must be Fixed")

# wan conditions met == TRUE
# first look at lit fiber + 1000 mbps
wan_data <- filter(line[wan, ], bandwidth_in_mbps %in% c(1000) & 
                (connect_type == "Lit Fiber Service" | (connect_type == "Ethernet" & bandwidth_in_mbps >= 150)))

sum3 <- 
  wan_data %>%
  # group_by(bandwidth_in_mbps) %>%
  summarize(#min = min(monthly_cost_per_line),
    n = n(),
    q10 = quantile(monthly_cost_per_line, probs = 0.10),
    q25 = quantile(monthly_cost_per_line, probs = 0.25),
    median = median(monthly_cost_per_line),
    q75 = quantile(monthly_cost_per_line, probs = 0.75),
    q90 = quantile(monthly_cost_per_line, probs = 0.90)
    #max = max(monthly_cost_per_line)
  )

sum3 <- melt(sum3, id.var = c("n"))
sum3$stat <- factor(sum3$variable, levels = c("q10", "q25", "median", "q75", "q90"))
#sum2$bandwidth_in_mbps <- factor(sum2$bandwidth_in_mbps, levels = c("100", "200", "1000"))
sum3$label <- paste0("$", prettyNum(round(sum3$value, 0), big.mark = ",", scientific = FALSE))

p_bars3 <-  
  
  ggplot(data = sum3) + 
  geom_bar(aes(x = stat, y = value, order = stat), stat = 'identity', fill = '#7fcdbb') +
  geom_text(aes(x = stat, y = value, label = label, vjust = 1)) +
  geom_text(aes(x = 0, y = 750, label = "Target Price: $750", vjust = -1)) +
  geom_hline(aes(yintercept = 750), linetype = 2, size = 1, color = "#2c7fb8")  +
  theme(legend.position = "bottom",
        panel.background = element_rect(fill = 'white', colour = 'white'),
        axis.line.y = element_blank(),
        axis.ticks = element_blank(),
        axis.line.x = element_line(size = 0.5, colour = "black"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.title = element_blank(),
        axis.text.y = element_blank()) +
  scale_x_discrete(expand = c(0,0), labels = c("10th Quartile", "25th Quartile", "Median", "75th Quartile", "90th Percentile")) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Monthly WAN Cost per Circuit\n1,000 mbps Lit Fiber")




# state of the states Report -- national median; pages 30 and 31

# analyses
line[ia, ]  %>%
  group_by(connect_type) %>%
  summarize(min = min(cost_per_line),
            median = median(cost_per_line),
            avg = mean(cost_per_line),
            max = max(cost_per_line))
 # connect type seems useful 
 # internet_conditions_met?

line[ia, ]  %>%
  group_by(connect_type) %>%
  summarize(min = min(cost_per_line),
            median = median(cost_per_line),
            avg = mean(cost_per_line),
            max = max(cost_per_line))


# check ICN + local affiliates coverage

data$icn <- ifelse(data$service_provider_name %in% c("Illinois Century Network"), 1, 0)
data$icn_plus_affiliates <- ifelse(data$service_provider_name %in% c("Illinois Century Network", "Illimois Central College", "Northern Illinois University"), 1, 0)

mean(data$icn)
# .0984
mean(data$icn_plus_affiliates)
#.1344

# per Jeff, ICN exclusively provides internet access (as opposed to upstream circuits)
# denominator should be only IA items


check <- data[data$internet_conditions_met == "TRUE",]

mean(check$icn)
x

