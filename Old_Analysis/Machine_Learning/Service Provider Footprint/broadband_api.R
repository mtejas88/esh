library(httr)
library(jsonlite)
library(reshape)


get_broadband <- function(x) {
  api_str <- paste0('http://www.broadbandmap.gov/broadbandmap/analyze/jun2014/summary/population/state/ids/',
  toString(x),'?format=json')
  data <- GET(api_str)
  data_transform <- fromJSON(toString(data))
  if(!is.null(data_transform$Results)) {
    data_transform$Results
  }
  else {
    rep("No Data", 119)
  }
}

test <- get_broadband(30)
View(test)
ncol(test)

states <- 1:50
states <- formatC(states, width = 2, format = "d", flag = "0")
states

all_states <- do.call(rbind, lapply(states, function(x) get_broadband(x)))

hist(as.numeric(as.character(
  all_states$numberOfWirelineProvidersEquals1)), 
  main='Percent of Population With One SP', xlab='Percentage of Population', col='dodgerblue',
  border='White')

hist(as.numeric(as.character(
  all_states$numberOfWirelineProvidersEquals2)), 
  main='Percent of Population With Two SPs', xlab='Percentage of Population', col='dodgerblue',
  border='White')

hist(as.numeric(as.character(
  all_states$numberOfWirelineProvidersEquals3)), 
  main='Percent of Population With Three SPs', xlab='Percentage of Population', col='dodgerblue',
  border='White')

hist(as.numeric(as.character(
  all_states$numberOfWirelineProvidersEquals4)), 
  main='Percent of Population With Four SPs', xlab='Percentage of Population', col='dodgerblue',
  border='White')

### By County ###
get_broadband_county <- function(x) {
  api_str <- paste0('http://www.broadbandmap.gov/broadbandmap/analyze/jun2014/summary/population/county/ids/',
                    toString(x),'?format=json')
  data <- GET(api_str)
  data_transform <- fromJSON(toString(data))
  if(!is.null(data_transform$Results)) {
    data_transform$Results
  }
  else {
    rep("No Data", 119)
  }
}

fips_count <- read.csv('fips_county.csv')

fips_count$fipstate <- formatC(fips_count$fipstate, width = 2, format = "d", flag = "0")
fips_count$fipscty <- formatC(fips_count$fipscty, width = 3, format = "d", flag = "0")
fips_count$uniq_county <- paste0(fips_count$fipstate, fips_count$fipscty)

all_county <- do.call(rbind, lapply(fips_count$uniq_county, function(x) get_broadband_county(x)))
colnames(all_county)

counties_dists <- dbGetQuery(con,
                       'select a.id, a."LEAID", a."CONAME", d.*
                       from ag121a a
                       inner join districts d
                       on a."LEAID" = d.nces_cd')


### By County Merge ###
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), tolower(substring(s, 2)),
        sep="", collapse=" ")
}

length(counties_dists$CONAME)
length(unique(counties_dists$CONAME))

counties_dists$CONAME <- sapply(counties_dists$CONAME, function(x) simpleCap(x))
counties_dists$county_state <- paste0(counties_dists$CONAME, ', ', counties_dists$postal_cd)

dists_fips <- merge(counties_dists, fips_count, by.x='county_state', by.y='ctyname')
final <- merge(dists_fips, all_county, by.x='uniq_county', by.y='geographyId')

nrow(final)
colnames(final)
write.csv(final, 'districts_broadband_gov.csv')
### By Zip Merge ###
# zc <- read.csv('zip_county.csv')
# all_county_zip <- merge(all_county, zc, by.x='geographyId', by.y='COUNTY')
# all_county_zip$numberOfWirelineProvidersEquals1 <- as.numeric(as.character(all_county_zip$numberOfWirelineProvidersEquals1))
# dists <- dbGetQuery(con,'
#                      select * from districts')
# length(unique(all_county_zip$ZIP))
# dists_sp <- merge(dists, all_county_zip, by.x='zip', by.y= 'ZIP' )
# write.csv(dists_sp, 'districts_with_sp_info.csv')

### Modeling ###
dists_sp$ia_cost_per_mbps <- as.numeric(as.character(dists_sp$ia_cost_per_mbps))
dists_sp$numberOfWirelineProvidersEquals1 <- as.numeric(as.character(dists_sp$numberOfWirelineProvidersEquals1))
dists_sp$numberOfWirelineProvidersEquals2 <- as.numeric(as.character(dists_sp$numberOfWirelineProvidersEquals2))
dists_sp$numberOfWirelineProvidersEquals3 <- as.numeric(as.character(dists_sp$numberOfWirelineProvidersEquals3))
dists_sp$numberOfWirelineProvidersEquals4 <- as.numeric(as.character(dists_sp$numberOfWirelineProvidersEquals4))

model1 <- lm(ia_cost_per_mbps ~ numberOfWirelineProvidersEquals1, data=dists_sp)
summary(model1)

model2 <- lm(ia_cost_per_mbps ~ numberOfWirelineProvidersEquals2, data=dists_sp)
summary(model2)

model3 <- lm(ia_cost_per_mbps ~ numberOfWirelineProvidersEquals3, data=dists_sp)
summary(model3)

model4 <- lm(ia_cost_per_mbps ~ numberOfWirelineProvidersEquals4, data=dists_sp)
summary(model4)
