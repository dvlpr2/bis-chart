library(shiny)
source("./bis-chart.R")

ui <- fluidPage(
  hr(style = "border-top: 10px solid #000000;"),
  titlePanel("OTC derivatives statistics produced with R"),
  hr(style = "border-top: 10px solid #000000;"),
  plotOutput("plot", width="650px", height="650px"),
  hr(),
  hr(style = "border-top: 10px solid #000000;"),
  titlePanel(tags$h1("OTC derivatives statistics at end-June 2023 [Original chart from BIS]")),
  titlePanel(tags$h4(
    tags$a("BIS original",href="https://www.bis.org/publ/otc_hy2311.htm")
  )),
  hr(style = "border-top: 10px solid #000000;"),
  tags$figure(
    class = "centerFigure",
    tags$img(
      src = "https://www.bis.org/publ/otc_hy2311/images/ch1graph1.jpg",
      width = 1400,
    )
  )
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    draw_bis_chart()
  }, res = 50)
}

shinyApp(ui, server)
