
## SCRAP CODE FOR ADRIANNA BOGHOZIAN

dta.test <- data.frame(school1 = c("A", "B", "C", "D", "J", "L"), school2 = c("B", "C", "D", "E", "K", "K"))
dta.test.ext <- dta.test[,c("school2", "school1")]
names(dta.test.ext) <- c("school1", "school2")
dta.test <- rbind(dta.test, dta.test.ext)
dta.test$school1 <- as.character(dta.test$school1)
dta.test$school2 <- as.character(dta.test$school2)


master.sch.list <- unique(dta.test$school1)
master <- dta.test
master.match.list <- NULL

## takes ~  to run
final.campus <- data.frame(matrix(NA, nrow=nrow(master), ncol=2))
names(final.campus) <- c("campus.id", "schools")
system.time({
  i <- 1
  while (length(master.sch.list) != 0){
    print(i)
    master.match.list <- NULL
    match.list1 <- master.sch.list[1]
    master.match.list <- append(master.match.list, match.list1)
    match.list2 <- master$school2[master$school1 %in% match.list1]
    while (length(match.list2) != 0){
      master <- master[!master$school1 %in% match.list1 & !master$school2 %in% match.list1,]
      master.match.list <- append(master.match.list, match.list2)
      match.list1 <- match.list2
      master <- master[!master$school2 %in% match.list1,]
      match.list2 <- master$school2[master$school1 %in% match.list1]
    }
    final.campus$campus.id[i] <- i
    final.campus$schools[i] <- paste(unlist(master.match.list), collapse=", ")
    master.sch.list <- master.sch.list[!master.sch.list %in% master.match.list]
    i <- i + 1
  }
})

## write function to extend dataset to all combinations
all.combos <- function(dta){
  dta.ext <- dta[,c("school2", "school1")]
  names(dta.ext) <- c("school1", "school2")
  dta <- rbind(dta, dta.ext)
  return(dta)
}


## extend to all combinations
dta.same.addr.pairs <- all.combos(dta.same.addr.pairs)
dta.same.addr.pairs$combo <- paste(dta.same.addr.pairs$school1, dta.same.addr.pairs$school2, sep='.')


campus.pairs <- all.combos(campus.pairs)
campus.pairs$combo <- paste(campus.pairs$school1, campus.pairs$school2, sep='.')

## which combinations are in the campus.pairs dataset and not in the other
sub.in.campus <- campus.pairs[!campus.pairs$combo %in% dta.same.addr.pairs$combo,]

## which combinations are in the dta.same.addr.pairs dataset and not in the other
sub.in.dta.same <- dta.same.addr.pairs[!dta.same.addr.pairs$combo %in% campus.pairs$combo,]



##*********************************************************************************************************
## OLD CODE:

## merge in district and lat/long information for each school
#dta.same.addr.pairs <- merge(dta.same.addr.pairs, schools[,c("NCESSCH_ADJ", "LEAID", "combined.addr", "LATCOD", "LONCOD")],
#                             by.x="school1", by.y="NCESSCH_ADJ", all.x=T)
#dta.same.addr.pairs <- merge(dta.same.addr.pairs, schools[,c("NCESSCH_ADJ", "LEAID", "combined.addr", "LATCOD", "LONCOD")],
#                             by.x="school2", by.y="NCESSCH_ADJ", all.x=T)
#names(dta.same.addr.pairs) <- c("school1", "school2", "district1", "combined.addr1", "lat1", "long1",
#                     "district2", "combined.addr2", "lat2", "long2")
## only keep the combinations with different district ids, as they will not be captured in the distance algorithm
#dta.same.addr.pairs <- dta.same.addr.pairs[dta.same.addr.pairs$district1 != dta.same.addr.pairs$district2,]
## assign empty distance col to be able to rbind
#dta.same.addr.pairs$distance_hav <- NA

## write out the dataset and read back in, due to error not letting me subset
#write.csv(dta.same.addr.pairs, "../data/same_address_diff_district.csv", row.names=F)
#dta.same.addr.pairs <- read.csv("../data/same_address_diff_district.csv", header=T, as.is=T)
## order the columns the same as dta so can rbind
#dta.same.addr.pairs <- dta.same.addr.pairs[, match(names(dta), names(dta.same.addr.pairs))]
## combine the two datasets
#dta <- rbind(dta, dta.same.addr.pairs)
## subset dta to only the distances that meet the threshold
#dta <- dta[dta$distance_hav <= 0.10,]

## subset data to where the combined addresses are the same
dta.same.addr <- dta[dta$combined.addr1 == dta$combined.addr2,]
## for each unique combined address, create a campus grouping
addr.unique <- unique(dta.same.addr$combined.addr1)
## aggregate school ids for each unique address
campus.dta1 <- aggregate(school1 ~ combined.addr1, data=dta.same.addr, paste, collapse=", ")
campus.dta2 <- aggregate(school2 ~ combined.addr1, data=dta.same.addr, paste, collapse=", ")
## merge the two datasets together
campus.dta <- merge(campus.dta1, campus.dta2, by="combined.addr1", all=T)
## takes ~ 2 sec to run
system.time({
  for (i in 1:nrow(campus.dta)){
    print(i)
    campus.dta$schools[i] <- paste(unique(c(unlist(strsplit(campus.dta$school1[i], split=", ")),
                                            unlist(strsplit(campus.dta$school2[i], split=", ")))), collapse=", ")
  }
})
campus.dta$school1 <- NULL
campus.dta$school2 <- NULL

## for each campus grouping, generate all unique combinations of schools that need to be together
campus.pairs <- data.frame(NULL)
## takes ~ 7 sec to run
system.time({
  for (i in 1:nrow(campus.dta)){
    print(i)
    campus.dta.sub <- unlist(strsplit(campus.dta$schools[i], split=", "))
    campus.pairs <- rbind(campus.pairs, as.data.table(t(combnPrim(campus.dta.sub, 2))))
  }
})
names(campus.pairs) <- c("school1", "school2")
## write out data set
write.csv(campus.pairs, "../data/campus_pairs.csv", row.names=F)
campus.pairs <- read.csv("../data/campus_pairs.csv", as.is=T, header=T)

