
filepath <- readline(prompt="Enter absolute filepath: ")

df <- read.csv(filepath)
c <- cor(df, method = "spearman")
c[is.na(c)] <- 0
library(corrplot)
cp <- corrplot(c,type = "upper", tl.cex = 0.8, tl.col = "black", addCoef.col = "black", number.cex = 0.5)

