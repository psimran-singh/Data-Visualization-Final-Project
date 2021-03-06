### STEP 1: IMPORTING DATA AND CREATING A BASE DATASET ###

#Load necessary libraries
library(tidyverse)
library(DataExplorer)

#Set Working Directory to Github folder
#Change to appropriate location if running on your own
setwd("~/GitHub/Data-Visualization-Final-Project")

#Import the datasets, one for each program
#Sourced from December'21 Monthly NJBPU Solar Registration Database
#At this URL: https://njcleanenergy.com/renewable-energy/project-activity-reports/solar-activity-report-archive
SRP_Data <- read.csv("~/GitHub/Data-Visualization-Final-Project/Original Data Files/NJBPU_SRP_Data.csv",na.string=c(NA,""," "))
TI_Data <- read.csv("~/GitHub/Data-Visualization-Final-Project/Original Data Files/NJBPU_TI_Data.csv",na.string=c(NA,""," "))
ADI_Data <- read.csv("~/GitHub/Data-Visualization-Final-Project/Original Data Files/NJPU_ADI_Data.csv",na.string=c(NA,""," "))

#Data Cleaning: Getting correct columns to join all datasets
#We need some key variables which are in all 3 program data, we will remove the others
col_names <- c("PROGRAM","CITY","ZIP","COUNTY_CODE","INTERCONNECTION_DATE","SYSTEM_SIZE",
               "CUSTOMER_TYPE","INTERCONNECTION_TYPE","THIRD_PARTY_OWNERSHIP")

SRP_Data <- SRP_Data %>% select(Program, Premise.City, Premise.........................Zip, 
                    County......................Code, PTO.Date..Interconnection.Date.,
                    Calculated.Total.System.Size, Customer.Type, Interconnection,
                    Third.Party.Ownership)
names(SRP_Data) <- col_names

TI_Data <- TI_Data %>% select(Program, Premise.City, Premise.........................Zip, 
                              County......................Code, PTO.Date..Interconnection.Date.,
                              Calculated.Total.System.Size, Customer.Type, Interconnection,
                              Third.Party.Ownership)
names(TI_Data) <- col_names

ADI_Data <- ADI_Data %>% select(Program, Premise.City, Premise.........................Zip, 
                               County......................Code, PTO.Date..Interconnection.Date.,
                               Calculated.Total.System.Size, Customer.Type, Interconnection,
                               Third.Party.Ownership)
names(ADI_Data) <- col_names

#Join all the datasets to create one with all entries across all programs
#We will now perform some data cleaning on this dataset
Solar_Data0 <- rbind(SRP_Data,TI_Data,ADI_Data)

remove(SRP_Data)
remove(TI_Data)
remove(ADI_Data)
remove(col_names)

### STEP 2: CLEANING DATASET ###

#First, lets create a DataExplorer report to explore missing data
#Uncomment to run:
  #create_report(Solar_Data0)
#From the report we see that our dataset is very complete
#We have 20 observations with missing town and zip codes, we will leave these in
#They still have county codes so we may roll them up or remove later

#Recode County_Codes and use county names instead
#Not sure where NJBPU got these codes, but they aren't handily available anywhere
#So, I manually went and searched town names in each county code and create this list
COUNTY_CODE <- c(1:21)
COUNTY <- c("Sussex","Warren","Morris","Hunterdon","Somerset","Passaic","Bergen",
            "Hudson","Essex","Union","Middlesex","Mercer","Burlington","Camden",
            "Gloucester","Salem","Monmouth","Ocean","Atlantic","Cumberland","Cape May")
County_Code_Conversion <- data.frame(COUNTY_CODE,COUNTY)
remove(COUNTY_CODE,COUNTY)

Solar_Data1 <- left_join(Solar_Data0,County_Code_Conversion,by=c("COUNTY_CODE"="COUNTY_CODE"))
Solar_Data1 <- Solar_Data1[c(1:4,10,5:9)]

#Reformat Zip Codes, since they're missing 0's: Not elegant but works
Solar_Data1$ZIP <- paste("0",Solar_Data1$ZIP,sep="")
Solar_Data1$ZIP[Solar_Data1$ZIP=="0NA"] <- NA

remove(County_Code_Conversion)
remove(Solar_Data0)

### STEP 3: AGGREGATE DATA ###

#Aggregate COUNTY, THIRD_PARTY_OWNERSHIP for only RESIDENTIAL
Solar_TPO_County <- Solar_Data1 %>% 
  filter(CUSTOMER_TYPE=="Residential") %>%
  group_by(COUNTY, THIRD_PARTY_OWNERSHIP) %>%
  summarize(COUNT = n()) %>%
  mutate(FREQ = COUNT / sum(COUNT)) %>%
  filter(THIRD_PARTY_OWNERSHIP == "Yes") %>%
  select(COUNTY,TPO_FREQ = FREQ)

#Aggregate ZIP, THIRD_PARTY_OWNERSHIP for only RESIDENTIAL
Solar_TPO_Zip <- Solar_Data1 %>% 
  filter(CUSTOMER_TYPE=="Residential") %>%
  group_by(ZIP, THIRD_PARTY_OWNERSHIP) %>%
  summarize(COUNT = n()) %>%
  mutate(FREQ = COUNT / sum(COUNT)) %>%
  filter(THIRD_PARTY_OWNERSHIP == "Yes") %>%
  select(ZIP,TPO_FREQ = FREQ)

#Aggregate by COUNTY for only RESIDENTIAL
Solar_Res_County <- Solar_Data1 %>% 
  filter(CUSTOMER_TYPE=="Residential") %>%
  group_by(COUNTY) %>%
  summarize(CAPACITY = sum(SYSTEM_SIZE,na.rm=TRUE), COUNT=n())

#Aggregate by Zip Code for only RESIDENTIAL
Solar_Res_Zip <- Solar_Data1 %>% 
  filter(CUSTOMER_TYPE=="Residential") %>%
  group_by(ZIP) %>%
  summarize(CAPACITY = sum(SYSTEM_SIZE,na.rm=TRUE), COUNT=n())

remove(Solar_Data1)


