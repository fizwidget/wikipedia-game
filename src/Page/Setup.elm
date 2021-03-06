module Page.Setup exposing
    ( Model
    , Msg
    , UpdateResult(..)
    , init
    , initWithArticles
    , update
    , view
    )

import Article exposing (Article, ArticleError(..), ArticleResult, Full, Preview)
import Cmd.Extra exposing (withCmd, withNoCmd)
import Css exposing (..)
import Html.Styled exposing (Html, button, div, form, text)
import Html.Styled.Attributes exposing (css, placeholder, type_, value)
import Html.Styled.Events exposing (onSubmit)
import Http
import RemoteData exposing (RemoteData(..), WebData)
import View.Button as Button
import View.Empty as Empty
import View.Input as Input
import View.Spinner as Spinner



-- MODEL


type alias Model =
    { sourceInput : UserInput
    , destinationInput : UserInput
    , source : RemoteArticle
    , destination : RemoteArticle
    , randomArticles : RemoteArticlePair
    }


type alias UserInput =
    String


type alias RemoteArticlePair =
    RemoteData RemoteArticlePairError ( Article Preview, Article Preview )


type RemoteArticlePairError
    = UnexpectedArticleCount
    | HttpError Http.Error


type alias RemoteArticle =
    RemoteData ArticleError (Article Full)



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel "" "", Cmd.none )


initWithArticles : Article a -> Article a -> ( Model, Cmd Msg )
initWithArticles source destination =
    ( initialModel (Article.title source) (Article.title destination)
    , Cmd.none
    )


initialModel : String -> String -> Model
initialModel sourceInput destinationInput =
    { sourceInput = sourceInput
    , destinationInput = destinationInput
    , source = NotAsked
    , destination = NotAsked
    , randomArticles = NotAsked
    }



-- UPDATE


type Msg
    = SourceInputChange UserInput
    | DestinationInputChange UserInput
    | FetchArticles
    | SourceArticleResponse RemoteArticle
    | DestinationArticleResponse RemoteArticle
    | FetchRandomArticles
    | RandomArticlesResponse RemoteArticlePair


type UpdateResult
    = InProgress ( Model, Cmd Msg )
    | Complete (Article Full) (Article Full)


update : Msg -> Model -> UpdateResult
update msg model =
    case msg of
        SourceInputChange input ->
            { model | sourceInput = input, source = NotAsked, randomArticles = NotAsked }
                |> withNoCmd
                |> InProgress

        DestinationInputChange input ->
            { model | destinationInput = input, destination = NotAsked, randomArticles = NotAsked }
                |> withNoCmd
                |> InProgress

        FetchRandomArticles ->
            { model | randomArticles = Loading }
                |> withCmd fetchRandomArticles
                |> InProgress

        RandomArticlesResponse response ->
            { model | randomArticles = response }
                |> showRandomArticles
                |> withNoCmd
                |> InProgress

        FetchArticles ->
            { model | source = Loading, destination = Loading }
                |> withCmd (fetchFullArticles model)
                |> InProgress

        SourceArticleResponse article ->
            { model | source = article }
                |> maybeCompleteSetup

        DestinationArticleResponse article ->
            { model | destination = article }
                |> maybeCompleteSetup


showRandomArticles : Model -> Model
showRandomArticles model =
    let
        setArticleInputs ( source, destination ) =
            { model
                | source = NotAsked
                , destination = NotAsked
                , sourceInput = Article.title source
                , destinationInput = Article.title destination
            }
    in
    model.randomArticles
        |> RemoteData.map setArticleInputs
        |> RemoteData.withDefault model


maybeCompleteSetup : Model -> UpdateResult
maybeCompleteSetup ({ source, destination } as model) =
    RemoteData.map2 Complete source destination
        |> RemoteData.withDefault (model |> withNoCmd |> InProgress)



-- FETCH RANDOM ARTICLE PREVIEWS


fetchRandomArticles : Cmd Msg
fetchRandomArticles =
    Article.fetchRandom 2
        |> RemoteData.sendRequest
        |> Cmd.map (toRemoteArticlePair >> RandomArticlesResponse)


toRemoteArticlePair : WebData (List (Article Preview)) -> RemoteArticlePair
toRemoteArticlePair remoteArticles =
    remoteArticles
        |> RemoteData.mapError HttpError
        |> RemoteData.andThen toPair


toPair : List (Article Preview) -> RemoteArticlePair
toPair articles =
    case articles of
        first :: second :: _ ->
            RemoteData.succeed ( first, second )

        _ ->
            RemoteData.Failure UnexpectedArticleCount



-- FETCH FULL ARTICLES


fetchFullArticles : Model -> Cmd Msg
fetchFullArticles { sourceInput, destinationInput } =
    Cmd.batch
        [ fetchFullArticle SourceArticleResponse sourceInput
        , fetchFullArticle DestinationArticleResponse destinationInput
        ]


fetchFullArticle : (RemoteArticle -> msg) -> String -> Cmd msg
fetchFullArticle toMsg title =
    Article.fetchByTitle title
        |> RemoteData.sendRequest
        |> Cmd.map (toRemoteArticle >> toMsg)


toRemoteArticle : WebData ArticleResult -> RemoteArticle
toRemoteArticle webData =
    webData
        |> RemoteData.mapError Article.HttpError
        |> RemoteData.andThen RemoteData.fromResult



-- VIEW


view : Model -> Html Msg
view model =
    form
        [ css
            [ displayFlex
            , alignItems center
            , flexDirection column
            ]
        , onSubmit FetchArticles
        ]
        [ viewArticleInputs model
        , viewFindPathButton (isFindPathButtonDisabled model)
        , viewRandomizeButton (isLoading model)
        , viewRandomizationError model.randomArticles
        , viewLoadingSpinner (isLoading model)
        ]


viewArticleInputs : Model -> Html Msg
viewArticleInputs ({ sourceInput, destinationInput, source, destination } as model) =
    div [ css [ displayFlex, justifyContent center, flexWrap wrap ] ]
        [ viewSourceArticleInput sourceInput source (isLoading model)
        , viewDestinationArticleInput destinationInput destination (isLoading model)
        ]


viewSourceArticleInput : UserInput -> RemoteArticle -> Bool -> Html Msg
viewSourceArticleInput =
    viewArticleInput SourceInputChange "From..."


viewDestinationArticleInput : UserInput -> RemoteArticle -> Bool -> Html Msg
viewDestinationArticleInput =
    viewArticleInput DestinationInputChange "To..."


viewArticleInput : (UserInput -> Msg) -> String -> String -> RemoteArticle -> Bool -> Html Msg
viewArticleInput toMsg placeholder title article isDisabled =
    div
        [ css
            [ padding2 (px 0) (px 8)
            , height (px 76)
            , textAlign center
            ]
        ]
        [ Input.text
            [ Input.Large
            , Input.OnInput toMsg
            , Input.Value title
            , Input.Placeholder placeholder
            , Input.Disabled isDisabled
            , Input.Error (RemoteData.isFailure article)
            ]
        , viewArticleError article
        ]


viewArticleError : RemoteArticle -> Html msg
viewArticleError remoteArticle =
    case remoteArticle of
        RemoteData.Failure error ->
            Article.viewError error

        _ ->
            Empty.view


viewFindPathButton : Bool -> Html Msg
viewFindPathButton isDisabled =
    div [ css [ padding (px 4) ] ]
        [ Button.view "Find path"
            [ Button.Primary
            , Button.Large
            , Button.Disabled isDisabled
            ]
        ]


viewRandomizeButton : Bool -> Html Msg
viewRandomizeButton isDisabled =
    div [ css [ paddingTop (px 8) ] ]
        [ Button.view "Randomize"
            [ Button.Secondary
            , Button.Large
            , Button.Disabled isDisabled
            , Button.OnClick FetchRandomArticles
            ]
        ]


viewRandomizationError : RemoteArticlePair -> Html msg
viewRandomizationError randomArticles =
    if RemoteData.isFailure randomArticles then
        text "Sorry, an error occured 😵"

    else
        Empty.view


viewLoadingSpinner : Bool -> Html msg
viewLoadingSpinner isVisible =
    if isVisible then
        Spinner.view

    else
        Empty.view


isFindPathButtonDisabled : Model -> Bool
isFindPathButtonDisabled model =
    isLoading model
        || isBlank model.sourceInput
        || isBlank model.destinationInput


isLoading : Model -> Bool
isLoading { source, destination, randomArticles } =
    RemoteData.isLoading randomArticles
        || RemoteData.isLoading source
        || RemoteData.isLoading destination


isBlank : String -> Bool
isBlank =
    String.trim >> String.isEmpty
