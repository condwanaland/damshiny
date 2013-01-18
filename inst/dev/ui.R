shinyUI(

  pageWithSidebar(

    headerPanel("Data Analysis Menu using Shiny"),
    
    sidebarPanel(

      includeHTML("www/js/damtools.js"),

      wellPanel(
        # if there are no datasets available only show the UI to make data available
        conditionalPanel(condition = "input.datasets != 'choosefile'",
          # selectInput(inputId = "tool", label = "Tool:", choices = toolChoices, selected = 'Data view')
          selectInput(inputId = "tool", label = "Tool:", choices = toolChoices, selected = 'EDAT - Compare means')
        ),
        br()
        # uiOutput("datasets")
      ),

      conditionalPanel(condition = "input.analysistabs == 'Summary'",
        conditionalPanel(condition = "input.tool == 'regression'",
          actionButton("saveres", "Save residuals (see Data view)")
        ),
        conditionalPanel(condition = "input.tool == 'kmeansClustering'",
          actionButton("saveclus", "Save cluster membership (see Data view)")
        )
      )
    ),
    
    mainPanel(
      includeHTML('www/js/lr.js'), # needed for livereload
              plotOutput("plots", height = 1200)
    )
  )
)