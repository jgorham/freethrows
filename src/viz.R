library(ggplot2)
library(plyr)
library(dplyr)
library(gridExtra)
library(glmnet)
library(doParallel)
library(Matrix)

source('~/utils/data_utils.R')
source('~/utils/data_import_utils.R')

registerDoParallel(5)

as.char <- as.character
options(RCurlOptions=list(followlocation=TRUE))
Sys.unsetenv("http_proxy")
options(dplyr.width = Inf)

RESULTS.DIR <- '../data'
set.seed(10)

raw <- read.csv(sprintf("%s/ft.tsv", RESULTS.DIR), sep="\t")

base <- raw %>%
    filter(period_type == "QUARTER") %>%
    mutate(
        mins_into_game = (12 * (period - 1)) + ceiling(12 - remaining_seconds_in_period / 60)
    ) %>%
    filter(mins_into_game > 0)

## OVERALL ##

per.min.stats <- ddply(base, .(mins_into_game), function (df) {
    pt <- prop.test(sum(df$was_made == "True"), nrow(df))
    c(
        "avg"=mean(df$was_made == "True"),
        "lo"=pt$conf.int[1],
        "hi"=pt$conf.int[2],
        "n"=nrow(df)
    )
})
per.min.stats$freq <- per.min.stats$n / sum(per.min.stats$n)

ggplot(data=per.min.stats, aes(x=mins_into_game, y=avg)) +
    geom_errorbar(aes(ymin=lo, ymax=hi)) +
    geom_point() +
    xlab("Minute of game") +
    ylab("Prob make") +
    theme_bw()

ggplot(data=per.min.stats, aes(x=mins_into_game, y=freq)) +
    geom_bar(stat="identity", fill="white", color="blue") +
    xlab("Minute of game") +
    ylab("Frequency") +
    theme_bw()

## PER PLAYER ##

player.per.min.stats <- ddply(base, .(actor, mins_into_game), function (df) {
    pt <- prop.test(sum(df$was_made == "True"), nrow(df))
    c(
        "avg"=mean(df$was_made == "True"),
        "lo"=pt$conf.int[1],
        "hi"=pt$conf.int[2],
        "n"=nrow(df)
    )
})

PLAYER.PANEL <- c(
    "S. Curry",
    "L. James",
    "A. Davis",
    "J. Harden",
    "K. Leonard"
)

ggplot(
    data=player.per.min.stats %>% filter(actor %in% PLAYER.PANEL),
    aes(x=mins_into_game, y=avg, color=actor)
    ) +
    geom_errorbar(aes(ymin=lo, ymax=hi)) +
    geom_point() +
    facet_wrap(~ actor) +
    xlab("Minute of game") +
    ylab("Prob make") +
    theme_bw()
