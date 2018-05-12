module Setup.Messages exposing (SetupMsg(..))

import Common.Article.Model exposing (RemoteArticle)
import Common.Title.Model exposing (RemoteTitlePair)
import Setup.Model exposing (UserInput)


type SetupMsg
    = SourceArticleTitleChange UserInput
    | DestinationArticleTitleChange UserInput
    | FetchArticlesRequest
    | FetchSourceArticleResponse RemoteArticle
    | FetchDestinationArticleResponse RemoteArticle
    | FetchRandomTitlesRequest
    | FetchRandomTitlesResponse RemoteTitlePair
