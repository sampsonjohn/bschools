library(googleVis)
library(maptools)
library(plyr)
library(gridExtra)
library(corrplot)
library(ggplot2)

################################ This function is going to be used at the very end for a motion chart - Can skip it for now ###############################

# Convenience interface to gvisMotionChart that allows to set default columns: Courtesy: Sebastian Kranz: http://stackoverflow.com/questions/10258970/default-variables-for-a-googlevis-motionchart
myMotionChart = function(df,idvar=colnames(df)[1],timevar=colnames(df)[2],xvar=colnames(df)[3],yvar=colnames(df)[4], colorvar=colnames(df)[5], sizevar = colnames(df)[6],...) {
  
  
  # Generate a constant variable as column for time if not provided
  # Unfortunately the motion plot still shows 1900...
  if (is.null(timevar)) {
    .TIME.VAR = rep(0,NROW(df))
    df = cbind(df,.TIME.VAR)
    timevar=".TIME.VAR"
  }
  
  # Transform booleans into 0 and 1 since otherwise an error will be thrown
  for (i in  1:NCOL(df)) {
    if (is.logical(df [,i])[1])
      df[,i] = df[,i]*1
  }
  
  # Rearrange columns in order to have the desired default values for
  # xvar, yvar, colorvar and sizevar
  firstcols = c(idvar,timevar,xvar,yvar,colorvar,sizevar)
  colorder = c(firstcols, setdiff(colnames(df),firstcols))
  df = df[,colorder]
  
  gvisMotionChart(df,idvar=idvar,timevar=timevar,...)
}
######################################################################The function ends and the fun begins##############

#Read data in, create a frequency distribution of number of schools in different States, and since the States are in an abbreviated form,
# they need to be converted into their full names

bschools<-read.csv("bschoolscsv.csv")

#Printing the dataset for viewing

bschooltable<-gvisTable(bschools, options=list(width=600, height=300))
plot(bschooltable)
print(bschooltable,file="bschooltable.html")

SchoolsbyState<-as.data.frame(table(bschools$State)) # data frame of frequencies of number of schools by state
SchoolsbyState<-rename(SchoolsbyState,c("Var1"="Stateabb","Freq"="Number.Of.Schools"))
SchoolsbyState$State <- toupper(state.name[match(SchoolsbyState$Stateabb,state.abb)])

# The above step inserted a null for washington DC, so fixing it by using a format conducive to google charts
SchoolsbyState$State[SchoolsbyState$Stateabb=="DC"]<-"US-DC"

#Generating US map with states colored based on number of schools in them

mapschoolsbystate<-gvisGeoChart(SchoolsbyState,locationvar="State", colorvar="Number.Of.Schools",
                                options=list(region="US", displayMode="marker",resolution="provinces",
                                width=600, height=400))

#...GoogleChart does not have a spot for Washington DC - it is too tiny, so look at only that region and it should be fine.

mapschoolsindcarea<-gvisGeoChart(SchoolsbyState,locationvar="State", colorvar="Number.Of.Schools",
                                 options=list(title='Number of Schools in the Washington DC area',region="US-DC", displayMode="region",resolution="provinces",
                                               width=150, height=100))
#combine the two maps together and plot
NumSchoolsbyState<-gvisMerge(mapschoolsbystate,mapschoolsindcarea, horizontal=TRUE) 
plot(NumSchoolsbyState)
print(NumSchoolsbyState,file="Numschoolsbystate.html")

#Now adding full state names to the original data frame to generate the following graph of average quality/index number in each state

bschools$States <- toupper(state.name[match(bschools$State,state.abb)])

# The above step inserted a null for washington DC, so fixing it 
bschools$States[bschools$State=="DC"]<-"WASHINGTON DC"

# Box plots for distribution of Index.Number by different states, ordered by Index.Number
ggplot(bschools,aes(x=reorder(States,Index.Number),y=Index.Number))+geom_boxplot(aes(fill=States))+
                    theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
                                                                                  theme(legend.position="none")+
                                                                                  ggtitle("Distribution of Index Number, by State (Means are in blue)")+
                                                                                  stat_summary(fun.y=mean, geom="point",color="blue", size=3)+coord_flip()+
                                                                                  labs(x="State",y="Index Number")

# Bplot 1 box plots for distribution of index number by type of school

schooltype<-ggplot(bschools,aes(x=School.Type,y=Index.Number))+geom_boxplot(aes(fill=School.Type))+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+
  ggtitle("Type of School")+
  stat_summary(fun.y=mean, geom="point",color="blue", size=5)+
  labs(x="",y="Index Number")

# Bplot 2 box plots for distribution of index number by teaching quality grade

teach<-ggplot(bschools,aes(x=reorder(Teaching.Quality.Grade,Index.Number),y=Index.Number))+geom_boxplot(aes(fill=Teaching.Quality.Grade))+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+
  ggtitle("Teaching Quality Grade")+
  stat_summary(fun.y=mean, geom="point",color="blue", size=5)+
  labs(x="",y="Index Number")

#Bplot 3 box plots for distribution of index number by facilities and services grade

facilities<-ggplot(bschools,aes(x=reorder(Facilities.and.Services.Grade,Index.Number),y=Index.Number))+geom_boxplot(aes(fill=Facilities.and.Services.Grade))+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+
  ggtitle("Facilities and Services Grade")+
  stat_summary(fun.y=mean, geom="point",color="blue", size=5)+
  labs(x="",y="Index Number")

# Bplot 4 box plots for distribution of index number by Job.Placement.Grade

jobplacement<-ggplot(bschools,aes(x=reorder(Job.Placement.Grade,Index.Number),y=Index.Number))+geom_boxplot(aes(fill=Job.Placement.Grade))+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+
  ggtitle("Job Placement Grade")+
  stat_summary(fun.y=mean, geom="point",color="blue", size=5)+
  labs(x="",y="Index Number")

#Combine Bplots 1-4 in a 2x2 grid for a combo plot

grid.arrange(schooltype,teach,facilities,jobplacement)

# Creating data for correlation analysis
bschoolcorr<-bschools[c(-2,-3,-4,-5,-16,-17,-18,-19)] #dropping non-numeric columns
corrmatrix<-cor(bschoolcorr) #store corr matrix
corrplot(corrmatrix,method="shade",shade.col=NA,tl.col="black",tl.srt=45) # Plot corrmatrix---- Where would I be without Winston Chang's R Graphics cookbook

#Scatter plot(s) ---- okay, a motion chart used as a scatter plot
bschools$Year<-c("2013") #  var created because a motion chart needs a time var 
bschools$Year<-as.numeric(bschools$Year)
# Plot motion chart using the function outlined at the very beginning..... coloring bubbles by the type of school 
scatterp<-myMotionChart(bschools, idvar="School", xvar="Annual.Tuition", yvar="Median.Starting.Salary",timevar="Year",sizevar="Index.Number",colorvar="School.Type",
              options=list(showSidePanel=FALSE,showSelectListComponent=FALSE,showXScalePicker=FALSE,
                           showYScalePicker=FALSE
                 ))
plot(scatterp)
print(scatterp,file="scatterplots.html")

                            ######################The end##################




