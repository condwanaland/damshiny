varnames <- function() {
	if(is.null(input$datasets)) return()

	dat <- getdata()
	colnames <- names(dat)
	names(colnames) <- paste(colnames, " {", sapply(dat,class), "}", sep = "")
	colnames
}

changedata <- function(addCol = NULL, addColName = "") {

	# function that changes data as needed
	if(is.null(addCol) || addColName == "") return()

	dat <- getdata()
	dat[,addColName] <- addCol
	assign(input$datasets, dat, inherits = TRUE)
}

getdata <- function(addCol = NULL, addColName = "") {

	dat <- get(input$datasets)
	dat
}

loadUserData <- function(uFile) {

	filename <- uFile$name
	ext <- file_ext(filename)
	file <- newdata <- sub(paste(".",ext,sep = ""),"",filename)
	ext <- tolower(ext)

	if(ext == 'rda' || ext == 'rdata') {
  	# FIX - avoid loading into global
  	# newdata <- load(inFile$datapath)
		# newdata will hold the name of the object inside the R datafile
	  newdata <- load(uFile$datapath, envir = .GlobalEnv)
	}

	if(datasets[1] == 'choosefile') {
		datasets <<- c(newdata)
	} else {
		datasets <<- unique(c(newdata,datasets))
	}

	if(ext == 'sav') {
		assign(file, read.sav(uFile$datapath), inherits = TRUE)
	} else if(ext == 'dta') {
		assign(file, read.dta(uFile$datapath), inherits = TRUE)
	} else if(ext == 'csv') {
		assign(file, read.csv(uFile$datapath, header = TRUE), inherits = TRUE)
	}
}

loadPackData <- function(pFile) {
	data(list = pFile)

	if(datasets[1] == 'choosefile') {
		datasets <<- c(pFile)
	} else {
		datasets <<- unique(c(pFile,datasets))
	}
}      

summary.dataview <- plot.dataview <- extra.dataview <- function(state) {
	return()
}

main.regression <- function(state) {
	if(is.null(state$dataset)) return()
	formula <- paste(state$var1, "~", paste(state$var2, collapse = " + "))
	result <- lm(formula, data = getdata())
	result
}

summary.regression <- function(result) {
	if(is.null(result)) return(cat("Please select one or more independent variables\n"))

	summary(result)
}

plot.regression <- function(result) {
	if(is.null(result)) return()
	par(mfrow = c(2,2))
	plot(result, ask = FALSE)
}

extra.regression <- function(result) {
	if(is.null(result)) return()
	if(length(result$coefficients) > 2) {
  	cat("Variance Inflation Factors\n")
  	VIF <- sort(vif(result), decreasing = TRUE)
		data.frame(VIF)
	} else {
  	cat("Insufficient number of independent variables selected to calculate VIF scores\n")
	}
}

summary.compareMeans <- function(state) {
	if(is.null(state$var2)) return(cat("Please select one or more variables\n"))
	if(is.null(state$datasets)) return()
	# expand to more than two groups
	formula <- as.formula(paste(state$var2, "~", state$var1))
	t.test(formula, data = getdata())
}

plot.compareMeans <- function(state) {
	if(is.null(state$datasets) || is.null(state$var2)) return()

	dat <- getdata()
	# plotting through ggplot not working yet
	# y <- dat[,state$var2]
	# x <- as.factor(dat[,state$var1])
	# dat <- data.frame(cbind(x,y))
	print(qplot(factor(dat[,state$var1]), dat[,state$var2], data = dat, xlab = state$var1, ylab = state$var2, geom = c("boxplot", "jitter")))
	# print(ggplot(dat, aes_string(x=x, y=state$var2)) + geom_boxplot()) # x must be specified as a factor --> doesn't work with aes_string
	# print(ggplot(dat, aes(x=x, y=y)) + geom_boxplot()) # x must be specified as a factor --> doesn't work with aes_string
}

extra.compareMeans <- function(state) {
	# nothing here yet, could put in test variance equality
	cat("Nothing yet\n")
}

main.hclustering <- function(state) {
	dat <- getdata()
	dist.data <- as.dist(dist(dat[,state$varinterdep], method = "euclidean")^2)
	result <- hclust(d = dist.data, method= "ward")
	result
}

summary.hclustering <- function(result) {
	if(is.null(result)) return(cat("Please select one or more variables\n"))
		result
}

plot.hclustering <- function(result) {
	if(is.null(result)) return()
	# use ggdendro when it gets back on cran
	plot(result, main = "Dendrogram")
}

extra.hclustering <- function(result) {
	height <- data.frame('height' = rev(result$height[result$height > 0]))
	height
}

main.kmeansClustering <- function(state) {
	if(is.null(state$varinterdep)) return(cat("Please select one or more variables\n"))
	set.seed(1234)
	dat <- getdata()
	nr.clus <- 3.0 	# fixed for now
	result <- kmeans(na.omit(object = dat[,state$varinterdep]), centers = nr.clus, nstart = 50, iter.max = 500)
	result
}

summary.kmeansClustering <- function(result) {
	# result$cluster <- NULL
	result
}

plot.kmeansClustering <- function(result) {

	if(is.null(input$datasets) || is.null(input$varinterdep)) return()

	dat <- getdata()[,input$varinterdep, drop = FALSE]
	# gg.xlim <- quantile(as.vector(as.matrix(dat)),probs = c(.01,.99))
	dat$clusvar <- as.factor(result$cluster)

	if(ncol(dat) > 2) {
		plots <- list()
		for(var in input$varinterdep) {
			# plots[[var]] <- ggplot(dat, aes_string(x=var, colour='clusvar')) + geom_density(adjust = 2) + xlim(gg.xlim[1],gg.xlim[2]) + theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(), axis.title.y=element_blank())
			# plots[[var]] <- ggplot(dat, aes_string(x=var, colour='clusvar')) + geom_density(adjust = 2) + theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(), axis.title.y=element_blank())
			plots[[var]] <- ggplot(dat, aes_string(x=var, colour='clusvar')) + geom_density(adjust = 1.5) 
		}
		print(do.call(grid.arrange, c(plots, ncol = 2)))
	} else {
			print(ggplot(dat, aes_string(x=input$varinterdep[1], colour='clusvar')) + geom_density(adjust = 1.5))
	}
}

extra.kmeansClustering <- function(result) {
	cat("Nothing yet\n")
}