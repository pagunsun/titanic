#########################
## Reading in the Data
#########################

train<-read.csv("train.csv",header=TRUE)

##########################################################################################
## Cleaning and transforming the Data
##########################################################################################

train$Name<-as.character(train$Name)
train$Survived<-as.factor(train$Survived)
train$Ticket<-as.character(train$Ticket)
train$Sex<-as.numeric(train$Sex)
train$Sex[train$Sex == "1"]="0"
train$Sex[train$Sex == "2"]="1"
train$Sex<-as.factor(train$Sex)
train$Embarked<-as.character(train$Embarked)


# Coding embarked variable: C = 1, Q = 2, S = 3

train$Embarked<-ifelse(train$Embarked == "C", "1",
                       ifelse (train$Embarked == "Q", "2",
                               ifelse (train$Embarked == "S", "3",
                                       "0")))

train$Embarked<-as.factor(train$Embarked)

# cabin
train$Cabin<-as.character(train$Cabin)
a<-cbind(train$Fare,train$Cabin)

# we only need character in cabin

train$Cabin<- gsub("[0-9]","", train$Cabin)
train$Cabin[train$Cabin==""]="H"  # put "H" level on lowest class 
train$Cabin<-substr(train$Cabin, start=1,stop=1)
train$Cabin
train$Cabin[train$Cabin=="A"]="1"
train$Cabin[train$Cabin=="B"]="1"
train$Cabin[train$Cabin=="C"]="1"
train$Cabin[train$Cabin=="D"]="1"
train$Cabin[train$Cabin=="E"]="2"
train$Cabin[train$Cabin=="F"]="2"
train$Cabin[train$Cabin=="G"]="3"
train$Cabin[train$Cabin=="H"]="4"


train$Cabin<-as.numeric(train$Cabin)

train$Cabin<-as.factor(train$Cabin)
train$Cabin[is.na(train$Cabin)]="4" # Assuming any letter that is not A-G is worst accomidation
train$Pclass <- factor(train$Pclass)


##########################################
# Dividing observation that have "NA"
##########################################

train.original <- train
train.all <- train
train.na <- train[(rowMeans(!is.na(train)) < 1),]
train <-na.omit(train)

##########################################
# Only missing variable is Age
##########################################

summary(train.na)
train.all$Age <- NULL

##################################################################################################
# Checking Full Models
######################
library(MASS)
library(car)

#############
# With Age
#############

train1<-train[c("Survived","PassengerId","Pclass","Sex","Age","SibSp","Parch","Fare","Cabin","Embarked")]
train.lm<-glm(Survived~.,data=train1,family="binomial")
summary(train.lm)
dffits(train.lm)
vif(train.lm)
plot(train.lm,which = 5)

# Suggests most influential variables are Pclass, Sex, Age, SibSp and Cabin

#############
# Without Age
#############

train1.all<-train.all[c("Survived","PassengerId","Pclass","Sex","SibSp","Parch","Fare","Cabin","Embarked")]
train.all.lm<-glm(Survived~.,data=train1.all,family="binomial")
summary(train.all.lm)
dffits(train.all.lm)
vif(train.all.lm)
plot(train.all.lm,which = 5)

# Suggests most influential variables are Pclass, Sex, SibSp and Cabin

#######################################################################
# Using AIC and BIC to guess model variables
#######################################################################

#############
# With Age
#############

stepAIC(train.lm,k=2)
train.aic<-glm(Survived ~ Pclass + Sex + Age + SibSp + Cabin,data=train1,family="binomial")
summary(train.aic)

stepAIC(train.lm,k=log(length(train[,1]))) # BIC
train.bic<-glm(Survived ~ Pclass + Sex + Age + SibSp,data=train1,family="binomial")
summary(train.bic)

#############
# Without Age
#############

stepAIC(train.all.lm,k=2)
train.all.aic<-glm(Survived ~ Pclass + Sex + SibSp + Cabin + Embarked,data=train.all,family="binomial")
summary(train.all.aic)

# Decided to drop embarked as they are not significant
train.all.aic_noembarked<-glm(Survived ~ Pclass + Sex + SibSp + Cabin,data=train.all,family="binomial")
summary(train.all.aic_noembarked)

stepAIC(train.all.lm,k=log(length(train.all[,1]))) # BIC
train.all.bic<-glm(Survived ~ Pclass + Sex + SibSp,data=train.all,family="binomial")
summary(train.all.bic)


#################################################################################################
# Comparing models
#################################################################################################

#############
# With Age
#############

anova(train.aic,train.bic, test="Chisq") # Testing significance of Cabin
anova(train.lm,train.aic, test="Chisq")  # Testing significance vs full model

# Best model for data with age: AIC
plot(train.aic,which = 5)

#############
# Without Age
#############

anova(train.all.aic,train.all.bic, test="Chisq") # Testing significance of Cabin and Embarked
anova(train.all.aic,train.all.aic_noembarked, test="Chisq") # Testing significance of Embarked
anova(train.all.lm,train.all.aic_noembarked, test="Chisq")  # Testing significance vs full model
anova(train.all.aic_noembarked,train.all.bic, test="Chisq") # Testing significance of Cabin
# Best model: AIC without Embarked
plot(train.all.aic_noembarked,which = 5)

################################
# Checking for multicollinearity
################################


# Rule of thumb: less than 5 is good
vif(train.aic)
vif(train.all.aic_noembarked)

################################
# Predicting using the AIC models
################################

#############
# With Age
#############

newvalue1 <- data.frame(predict(train.aic,train1,interval="predict"))
newvalue1[newvalue1<=0.5]=0
newvalue1[newvalue1>0.5]=1
predictions <- data.frame(Prediction = as.numeric(newvalue1[,1]),Actual = as.numeric(train1$Survived)-1)
predictions$Correct <- (predictions$Actual == predictions$Prediction)
AIC_withAge_Accuracy <- table(predictions$Correct)/length(predictions$Correct)*100
AIC_withAge_Accuracy

#############
# Without Age
#############

newvalue1 <- data.frame(predict(train.all.aic_noembarked,train.all,interval="predict"))
newvalue1[newvalue1<=0.5]=0
newvalue1[newvalue1>0.5]=1
predictions <- data.frame(Prediction = as.numeric(newvalue1[,1]),Actual = as.numeric(train1.all$Survived)-1)
predictions$Correct <- (predictions$Actual == predictions$Prediction)
AIC_noAge__noEmbarked_Accuracy <-table(predictions$Correct)/length(predictions$Correct)*100
AIC_noAge__noEmbarked_Accuracy

#################################
## Using a classification tree
#################################

library(ElemStatLearn)
library(tree)
require(rpart)

tree <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data=train, method="class")
plot(tree);text(tree)

library(rattle)
library(rpart.plot)
library(RColorBrewer)
fancyRpartPlot(tree,main = "", sub = "")

# prediction
prediction2 <- data.frame(predict(tree, train, type = "class"))
prediction3 <- data.frame(Prediction = as.numeric(prediction2[,1])-1,Actual = as.numeric(train$Survived)-1)
prediction3$Correct <- (prediction3$Actual == prediction3$Prediction)
Tree_Accuracy <- table(prediction3$Correct)/length(prediction3$Correct)*100
Tree_Accuracy

#############
# With All Data
#############

tree_all <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data=train.original, method="class")
plot(tree_all);text(tree_all)
fancyRpartPlot(tree_all,main = "", sub = "")

# prediction
prediction4 <- data.frame(predict(tree_all, train.original, type = "class"))
prediction5 <- data.frame(Prediction = as.numeric(prediction4[,1])-1,Actual = as.numeric(train.original$Survived)-1)
prediction5$Correct <- (prediction5$Actual == prediction5$Prediction)
Tree_Accuracy_2 <- table(prediction5$Correct)/length(prediction5$Correct)*100
Tree_Accuracy_2


########################################
# Fixed and Random effects model
########################################
require(lme4)
train$Last_names <- as.factor(sub(",.*", "", train$Name))
train.all$Last_names <- as.factor(sub(",.*", "", train.all$Name))

model <- glmer(Survived ~ Pclass + Sex + Age + SibSp + Cabin
				 + (1|Last_names), data=train, family = "binomial")
summary(model)

# Cabin becomes insignificant and could be dropped
model <- glmer(Survived ~ Pclass + Sex + Age + SibSp
				 + (1|Last_names), data=train, family = "binomial")
summary(model)

#############
# With All Data no age
#############

model.all <- glmer(Survived ~ Pclass + Sex + SibSp + Cabin
				 + (1|Last_names), data=train.all, family = "binomial")

summary(model.all)

# Pclass becomes insignificant and could be dropped

model.all <- glmer(Survived ~ Sex + SibSp + Cabin
				 + (1|Last_names), data=train.all, family = "binomial")

summary(model.all)


#########################################
# Predicting using the Fixed Effect model
#########################################

newvalue2 <- data.frame(predict(model,train,interval="predict",allow.new.levels = T))
newvalue2[newvalue2<=0.5]=0
newvalue2[newvalue2>0.5]=1
predictions <- data.frame(Prediction = as.numeric(newvalue2[,1]),Actual = as.numeric(train$Survived)-1)
predictions$Correct <- (predictions$Actual == predictions$Prediction)
logistic_random_modle_Age <- table(predictions$Correct)/length(predictions$Correct)*100
logistic_random_modle_Age


newvalue2 <- data.frame(predict(model.all,train.all,interval="predict",allow.new.levels = T))
newvalue2[newvalue2<=0.5]=0
newvalue2[newvalue2>0.5]=1
predictions <- data.frame(Prediction = as.numeric(newvalue2[,1]),Actual = as.numeric(train.all$Survived)-1)
predictions$Correct <- (predictions$Actual == predictions$Prediction)
logistic_random_modle_noAge <- table(predictions$Correct)/length(predictions$Correct)*100
logistic_random_modle_noAge

#################################################################################################################
# Very good at predicting onto the same data set but need to test otherwise
#################################################################################################################
