module Docs.Search.Main where

import Prelude

import Docs.Search.IndexBuilder as IndexBuilder
import Docs.Search.Interactive as Interactive

import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.List as List
import Data.List.NonEmpty as NonEmpty
import Data.Maybe (Maybe, fromMaybe, optional)
import Data.Unfoldable (class Unfoldable)
import Effect (Effect)
import Options.Applicative (Parser, command, execParser, fullDesc, helper, info, long, metavar, progDesc, strOption, subparser, value, (<**>))
import Options.Applicative as CA

main :: Effect Unit
main = do

  args <- getArgs
  let defaultCommands = Search { docsFiles: defaultDocsFiles }

  case fromMaybe defaultCommands args of
    BuildIndex cfg -> IndexBuilder.run cfg
    Search cfg -> Interactive.run cfg

getArgs :: Effect (Maybe Commands)
getArgs = execParser opts
  where
    opts =
      info (commands <**> helper)
      ( fullDesc
     <> progDesc "Search frontend for the documentation generated by the PureScript compiler."
      )

data Commands
  = BuildIndex { docsFiles :: Array String
               , generatedDocs :: String
               }
  | Search { docsFiles :: Array String }

derive instance genericCommands :: Generic Commands _

instance showCommands :: Show Commands where
  show = genericShow

commands :: Parser (Maybe Commands)
commands = optional $ subparser
  ( command "build-index"
    ( info buildIndex
      ( progDesc "Build the index used to search for definitions and patch the generated docs so that they include a search field."
      )
    )
 <> command "search"
    ( info startInteractive
      ( progDesc "Run the search engine."
      )
    )
  )

buildIndex :: Parser Commands
buildIndex = ado

  docsFiles <- fromMaybe defaultDocsFiles <$>
   optional (
     some ( strOption
            ( long "docs-files"
              <> metavar "GLOB"
            )
     )
   )

  generatedDocs <- strOption
    ( long "generated-docs"
   <> metavar "DIR"
   <> value "./generated-docs/"
    )

  in BuildIndex { docsFiles, generatedDocs }

startInteractive :: Parser Commands
startInteractive = ado

  docsFiles <- fromMaybe defaultDocsFiles <$>
   optional (
     some ( strOption
            ( long "docs-files"
           <> metavar "GLOB"
            )
     )
   )

  in Search { docsFiles }

defaultDocsFiles :: Array String
defaultDocsFiles = [ "output/**/docs.json" ]

many :: forall a f. Unfoldable f => Parser a -> Parser (f a)
many x = CA.many x <#> List.toUnfoldable

some :: forall a f. Unfoldable f => Parser a -> Parser (f a)
some x = CA.some x <#> NonEmpty.toUnfoldable