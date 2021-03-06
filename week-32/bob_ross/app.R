library(shiny)
library(tidyverse)
library(ggimage)

bob_ross <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-08-06/bob-ross.csv")

# elements to draw
draw_elements <- c("cloud", "mountain", "tree", "sun", "cabin",
                   "bushes", "lake", "river", "grass", "fence",
                   "waterfall", 
                   "cactus", "palm_trees", "lighthouse", "sea", "beach",
                   "moon", "boat", "rocks",
                   "night")

bob <- bob_ross %>% 
    janitor::clean_names() %>%
    rename(SE = episode) %>% 
    mutate(n = row_number()) %>% 
    separate(SE, into = c("season", "episode"), sep = "E", remove = FALSE) %>% 
    mutate(season = str_extract(SE, "[:digit:]+")) %>% 
    mutate_at(vars(season, episode), as.integer) %>%
    # remove frame elements and names (columns)
    select(-contains("FRAME"), -contains("STEVE"), -contains("DIANE")) %>%
    # remove episodes with guests (rows)
    filter(guest != 1) %>%
    # titlecase for episode titles
    mutate(title = str_to_title(title)) %>%
    # gather drawing elements
    gather("element", "exists", aurora_borealis:winter, na.rm = T) %>%
    filter(exists != 0) %>% 
    select(-exists) %>%
    # sort
    arrange(SE) %>%
    mutate(SE = paste0(SE, " - ", title)) %>% 
    # rename elements
    mutate(
        element = case_when(
            element == "barn" ~ "cabin",
            element == "building" ~ "cabin",
            element == "farm" ~ "cabin",
            element == "clouds" ~ "cloud",
            element == "mountains" ~ "mountain",
            element == "hills" ~ "mountain",
            element == "trees" ~ "tree",
            element == "conifer" ~ "tree",
            element == "deciduous" ~ "tree",
            element == "cumulus" ~ "cloud",
            element == "cirrus" ~ "cloud",
            element == "snowy_mountain" ~ "mountain",
            element == "waves" ~ "sea",
            element == "ocean" ~ "sea",
            T ~ element
        )
    ) %>% 
    # remove duplicates after renaming
    distinct(SE, season, episode, title, element, n) %>% 
    # images
    mutate(img_element = paste0(element, ".png")) %>%
    # keep elements that can be drawn
    filter(element %in% draw_elements)

ui <- fluidPage(
    includeCSS("styles.css"),
    verticalLayout(
        h3("Bob Ross - Painting by the elements"),
        plotOutput("paintingPlot", height = "300px"),
        selectInput("episodeInput", "Select episode:",
                    choices = bob$SE,
                    selected = T,
                    width = "100%"),
        tableOutput("elementsTable")
        )
    )

server <- function(input, output) {
    output$paintingPlot <- renderPlot({
        bob %>% 
            filter(SE == input$episodeInput) %>% 
            ggplot() +
            geom_image(aes(image = (paste0("www/elements/", img_element)), 0, 0), size = 1) +
            coord_fixed(xlim = c(-32, 32), ylim =  c(-32, 32)) +
            theme_void()
    }, bg="transparent")
    
    output$elementsTable <- renderTable(
        bob %>% 
            filter(SE == input$episodeInput) %>% 
            select("Elements drawn" = "element"),
        
        colnames = T, width = "100%"
    )
}

shinyApp(ui = ui, server = server)