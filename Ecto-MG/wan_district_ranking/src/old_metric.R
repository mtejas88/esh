##**************************************************************************************************************************************************
## explore holistic cost metric

#dd.2016$cost.metric.1 <- dd.2016$monthly.total.cost.per.student / (dd.2016$ia_bandwidth_per_student_kbps / 100)
## If, instead of dividing the monthly cost per student by the product of bandwidth/100,
## we could multiply then subtract the cost per student.
## This would reverse the scores for the metric so that bigger is better.
## It would also make scores for districts buying less than 100Kbps/student a negative number.
#dd.2016$cost.metric.2 <- dd.2016$monthly.total.cost.per.student * (dd.2016$ia_bandwidth_per_student_kbps / 100)
#dd.2016$cost.metric.3 <- dd.2016$cost.metric.2 - dd.2016$monthly.total.cost.per.student

#range(dd.2016$cost.metric.1)
#quantile(dd.2016$cost.metric.1, probs=seq(0,1,by=0.05))
#range(dd.2016$cost.metric.2)
#quantile(dd.2016$cost.metric.2, probs=seq(0,1,by=0.05))
#range(dd.2016$cost.metric.3)
#quantile(dd.2016$cost.metric.3, probs=seq(0,1,by=0.05))

#dta.mark <- dd.2016[dd.2016$esh_id %in% c(882758, 883745, 903541, 903564, 904483),
#                    c('esh_id', 'name', 'monthly.total.cost.per.student',
#                      'cost.metric.1', 'cost.metric.2', 'cost.metric.3', 'ia_monthly_cost_total',
#                      'wan_monthly_cost_total', 'num_students', 'ia_bandwidth_per_student_kbps')]


## plot the distribution (taking out 313 outliers)
#dta.hist <- dd.2016[which(dd.2016$cost.metric.1 <= 10),]
#pdf("figures/distribution_holistic_cost_metric_1.pdf", height=5, width=6)
#hist(dta.hist$cost.metric.1, xlim=c(0,10),
#     col=rgb(0,0,0,0.6), border=F, breaks=seq(0,10,by=0.10),
#     main="", xlab="", ylab="")
#dev.off()

## plot the distribution (taking out 462 outliers)
#dta.hist2 <- dd.2016[which(dd.2016$cost.metric.2 <= 200),]
#pdf("figures/distribution_holistic_cost_metric_2.pdf", height=5, width=6)
#hist(dta.hist2$cost.metric.2, xlim=c(0,200),
#     col=rgb(0,0,0,0.6), border=F, breaks=seq(0,200,by=2),
#     main="", xlab="", ylab="")
#dev.off()

## plot the distribution (taking out 313 outliers)
#dta.hist <- dd.2016[which(dd.2016$cost.metric.3 <= 200),]
#pdf("figures/distribution_holistic_cost_metric_3.pdf", height=5, width=6)
#hist(dta.hist$cost.metric.3, xlim=c(-200,200),
#     col=rgb(0,0,0,0.6), border=F, breaks=seq(-200,200,by=2),
#     main="", xlab="", ylab="")
#dev.off()
