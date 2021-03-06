# server.R
library(auth0)

# Load required libraries
source("config/init_server_globals.R")

#auth0_server(
function(input,output,session) {
    # Load init packages script
    source("config/init_packages.R")
    # Load SeqCVIBE libs
    source("server/reactiveVars.R",local=TRUE)
    source("server/dataSelectorTab/dataSelectorItem.R",local=TRUE)
    source("server/dataSelectorTab/sessionLoaderItem.R",local=TRUE)
    source("server/signalViewerTab/signalViewerItemGeneSignal.R",local=TRUE)
    source("server/signalViewerTab/signalViewerItemAreaSignal.R",local=TRUE)
    source("server/expressionViewerTab/expressionViewerItemKnownGene.R",
        local=TRUE)
    source("server/expressionViewerTab/expressionViewerItemCalculator.R",
        local=TRUE)
    source("server/analysisTab/analysisItemDiffExpr.R",local=TRUE)
    source("server/analysisTab/analysisItemClustering.R",local=TRUE)
    source("server/analysisTab/analysisItemCorrelation.R",local=TRUE)
    source("server/analysisTab/analysisItemMdsPca.R",local=TRUE)
    source("server/genomeBrowserTab/genomeBrowserItem.R",local=TRUE)
    
    # Init packages
    initPackages(session)
    
    # Make %#^%$^%$@( globals visible AND changeable
    makeReactiveBinding("loadedGenomes")
    makeReactiveBinding("loadedData")
    
    USER_ID <- reactiveVal(NULL)
    
    # Initialize all the reactive variables used...
    allReactiveVars <- initReactiveVars()
    # ...and reactive messages
    allReactiveMsgs <- initReactiveMsgs()
    
    # Data selector
    dataSelectorTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
        
    # Session loader
    sessionLoaderTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Signal viewer - Gene signal
    geneSignalTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
   
    # Signal viewer - Area signal
    areaSignalTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Expresion viewer - Known genes
    expressionExplorerTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Expresion viewer - Calculator
    expressionCalculatorTabPanelObserve(input,output,session,
        allReactiveVars,allReactiveMsgs)        
    
    # Analysis - Differential expression
    diffExprTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Analysis - Clustering
    clusteringTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
        
    # Analysis - Correlation
    correlationTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
        
    # Analysis - MDS/PCA
    mdsPcaTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Genome browser
    genomeBrowserTabPanelObserve(input,output,session,allReactiveVars,
        allReactiveMsgs)
    
    # Handle user login
    observe({
        if (!is.null(session$userData$auth0_info)) {
            email <- session$userData$auth0_info$email
            name <- session$userData$auth0_info$name
            
            cat(file="log.txt",email,"\n",append=TRUE)
            cat(file="log.txt",name,"\n",append=TRUE)
            
            # name is the primary identifier of auth0
            qCheck <- paste0("SELECT COUNT(1) FROM users WHERE name='",
                name,"'")
            n <- dbGetQuery(metadata,qCheck)[1,1]
            if (n == 0) { # Create also the user in our local db
                iQuery <- paste0("INSERT INTO users (email, name) ",
                    "VALUES ('",email,"',","'",name,"')")
                #print(iQuery)
                cat(file="log.txt",iQuery,"\n",append=TRUE)
                nr <- dbExecute(metadata,iQuery)
            }
            
            # Then get the (new) user_id
            ii <- dbGetQuery(metadata,paste0("SELECT _id FROM users WHERE ",
                "name='",name,"'"))[1,1]
            USER_ID(as.numeric(ii))
            #print(USER_ID())
        }
    })
    
    # Handle user logout
    observe({
        if (!is.null(session$userData$auth0_info)) {
            if (req(input$preLogoutHelper) == "42") {
                options(auth0_config_file="config/_auth0.yml")
                showModal(modalDialog(
                    title="Logout?",
                    "Are you sure you want to log out from SeqCVIBE?",
                    easyClose=FALSE,
                    size="s",
                    footer=tagList(
                        actionButton("cancelLogout","Cancel",icon=icon("ban")),
                        logoutButton(icon=icon("check"))
                    )
                ))
            }
        }
    })
    observeEvent(input$cancelLogout,{
        if (!is.null(session$userData$auth0_info)) {
            updateTextInput(session,"preLogoutHelper",value="0")
            updateNavbarPage(session,"seqcnavbar",selected="Data selector")
            removeModal()
        }
    })
    
    onRestore(function(state) {
        query <- getQueryString()
        
        # If onRestore has fired, it means that query is not empty
        if (!is.null(query$code)) { # Fired with auth0, further check
            if (!is.null(query$`_state_id_`)) { # Then fire server script
                # # Strip auth0 url data. Fixes a problem with auth0 
                # re-authentication when restoring a session (which should not
                # be happening anyway)
                updateQueryString(paste0("?_state_id_=",query$`_state_id_`))
                
                shinyjs::show("spinnerContainer")
                updateNavbarPage(session,"seqcnavbar",selected="Data selector")
                
                # Reruning the whole server script to restore Bookmarked session
                shinyjs::delay(3000,{
                dataSelectorTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                geneSignalTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                areaSignalTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)  
                expressionExplorerTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                expressionCalculatorTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)   
                diffExprTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                clusteringTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                correlationTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                mdsPcaTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                genomeBrowserTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                })
            }
            else # Clear the URL (https://github.com/curso-r/auth0/issues/54)
                session$sendCustomMessage("clearUrl",
                    list(path=session$clientData$url_pathname))
                # Does not completely fix...
        }
        else { # Just check _state_id_
            if (!is.null(query$`_state_id_`)) { # Then fire server script
                shinyjs::show("spinnerContainer")
                updateNavbarPage(session,"seqcnavbar",selected="Data selector")
                
                # Reruning the whole server script to restore Bookmarked session
                shinyjs::delay(3000,{
                dataSelectorTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                geneSignalTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                areaSignalTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)  
                expressionExplorerTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                expressionCalculatorTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)   
                diffExprTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                clusteringTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                correlationTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                mdsPcaTabPanelObserve(state$input,state$output,session,
                    allReactiveVars,allReactiveMsgs)
                genomeBrowserTabPanelObserve(state$input,output,session,
                    allReactiveVars,allReactiveMsgs)
                })
            }
        }
    })
    
    onRestored(function(state) {
        observe({
            # Will always be filled after a session restore, as session creation
            # is not allowed if a dataset has not been created
            query <- getQueryString()
            if (!is.null(allReactiveVars$currentMetadata$final) 
                && !is.null(query[["_state_id_"]])) {
                shinyjs::hide("spinnerContainer")
                session$sendCustomMessage("clearUrl",
                    list(path=session$clientData$url_pathname))
                updateQueryString("")
                showModal(modalDialog(HTML("The selected session has been ",
                    "restored! Remember To hit <strong>Clear Dataset</strong> ",
                    "if you want to start over!"),
                    title="Session restored",
                    easyClose=TRUE,
                    size="s"
                ))
                #assign("state",state,envir=.GlobalEnv)
                # This is the right way to make table show
                updateTextInput(session,"dataSource",
                    value=state$input$dataSource)
                updateTextInput(session,"dataDataset",
                    value=state$input$dataDataset)
            }
        })
    })
    
    # Excluding unnecessary actions from bookmarking
    setBookmarkExclude(c("bookmarkBtn","showFastqc","clearDataset","deleteBM"))
        
    onStop(function() {
        if (!is(metadata,"SQLiteConnection"))
            dbDisconnect(metadata)
    })
}
#,info=auth0_info("config/_auth0.yml"))
#,info=a0_info)
