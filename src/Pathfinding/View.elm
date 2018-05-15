module Pathfinding.View exposing (view)

import Css exposing (..)
import Html.Styled exposing (Html, fromUnstyled, toUnstyled, text, ol, li, h3, div)
import Html.Styled.Attributes exposing (css)
import Bootstrap.Button as ButtonOptions
import Common.Button.View as Button
import Common.Article.Model exposing (Article, RemoteArticle, ArticleError)
import Common.Article.View as Article
import Common.Title.View as Title
import Common.PriorityQueue.Model as PriorityQueue exposing (PriorityQueue)
import Common.Spinner.View as Spinner
import Pathfinding.Messages exposing (PathfindingMsg(BackToSetup))
import Pathfinding.Model exposing (PathfindingModel, Path, Error(PathNotFound))


view : PathfindingModel -> Html PathfindingMsg
view { source, destination, priorityQueue, errors, fatalError } =
    div [ css [ displayFlex, flexDirection column, alignItems center ] ]
        [ heading source destination
        , errorView errors fatalError
        , warningView priorityQueue destination
        , backView
        , priorityQueueView priorityQueue
        ]


heading : Article -> Article -> Html msg
heading source destination =
    h3 [ css [ textAlign center ] ]
        [ text "Finding path from "
        , Title.viewAsLink source.title
        , text " to "
        , Title.viewAsLink destination.title
        , text "..."
        ]


errorView : List ArticleError -> Maybe Error -> Html msg
errorView errors fatalError =
    div []
        [ fatalErrorView fatalError
        , nonFatalErrorView errors
        ]


fatalErrorView : Maybe Error -> Html msg
fatalErrorView error =
    case error of
        Just PathNotFound ->
            text "Path not found :("

        Nothing ->
            text ""


nonFatalErrorView : List ArticleError -> Html msg
nonFatalErrorView errors =
    div [] <| List.map Article.viewError errors


backView : Html PathfindingMsg
backView =
    div [ css [ margin (px 20) ] ]
        [ Button.view
            [ ButtonOptions.secondary, ButtonOptions.onClick BackToSetup ]
            [ text "Back" ]
        ]


warningView : PriorityQueue Path -> Article -> Html msg
warningView priorityQueue destination =
    div [ css [ textAlign center ] ]
        [ destinationContentWarning destination
        , pathCountWarning priorityQueue
        ]


destinationContentWarning : Article -> Html msg
destinationContentWarning destination =
    if String.contains "disambigbox" destination.content then
        div [] [ text "The destination article is a disambiguation page, so I probably won't be able to find a path to it \x1F916" ]
    else if String.length destination.content < 7000 then
        div [] [ text "The destination article has very little content, so this might not go well 😬" ]
    else
        text ""


pathCountWarning : PriorityQueue Path -> Html msg
pathCountWarning priorityQueue =
    if PriorityQueue.size priorityQueue > 100 then
        div [] [ text "This isn't looking good. Try a different destination maybe? 😅" ]
    else
        text ""


priorityQueueView : PriorityQueue Path -> Html msg
priorityQueueView queue =
    PriorityQueue.getHighestPriority queue
        |> Maybe.map pathView
        |> Maybe.withDefault (div [] [])


pathView : Path -> Html msg
pathView pathSoFar =
    let
        stops =
            pathSoFar.next :: pathSoFar.visited
    in
        div [ css [ textAlign center ] ]
            [ stops
                |> List.map Title.viewAsLink
                |> List.intersperse (div [] [ text "↑" ])
                |> List.append [ div [] [ text "↑" ] ]
                |> List.append [ Spinner.view { isVisible = True } ]
                |> div []
            ]
