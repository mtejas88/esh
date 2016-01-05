# Clear the console
cat("\014")

# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "ggplot2", "RColorBrewer", "raster", "maps", "mapproj", "gridExtra", "reshape2", "scales")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Desktop/R/Illinois CR/data/intermediate")

# load csv
line <- read.csv("~/Desktop/R/Illinois CR/data/mode/line_items.csv", as.is = TRUE)

# limit to clean data
line <- filter(line, exclude == FALSE)
# note: filter for ia_condition_met or wan_condition_met to TRUE depending on analyses

 # create columns and conditions

# cost_per_line: (total_cost / num_lines) / 12 * monthly measure
line$monthly_cost_per_line <- (line$total_cost / line$num_lines) /12

# cost_per_line_mbps: normalize by bandwidth
line$monthly_cost_per_line_mbps <- line$monthly_cost_per_line / line$bandwidth_in_mbps

# which conditions
ia <- which(line$ia_conditions_met == TRUE, 1, 0)
wan <- which(line$wan_conditions_met == TRUE, 1, 0)
upstream <- which(line$upstream_conditions_met == TRUE, 1, 0)

### analyses
 # cost analyses per line / per line and per mbps
 # function using var as an argument fails and i can't dwell on it now

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

