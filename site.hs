--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Options
import           Text.Pandoc.Definition
import           System.FilePath (replaceExtension)

import qualified Data.Text as T
import qualified Data.Set as S

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "data/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "js/*" $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["subpages/about.markdown", "subpages/privacy.markdown", "projects.markdown", "progress.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompilerWith readerPostOptions writerPostOptions
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $
            pandocCompilerWithTransform readerPostOptions writerPostOptions addAnchors
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "posts/*" $ version "header" $
        compile $ do
            let getHeaders (Pandoc meta blocks) = Pandoc meta (untilFirstParagraph blocks)
            pandocCompilerWithTransform readerPostOptions writerHeaderOptions getHeaders
            >>= loadAndApplyTemplate "templates/post.html" headCtx
            >>= relativizeUrls

    match "posts/*" $ version "only_title" $
        compile $ do
            let onlyMetadata (Pandoc meta blocks) = Pandoc meta ([])
            pandocCompilerWithTransform readerPostOptions writerHeaderOptions onlyMetadata
            >>= loadAndApplyTemplate "templates/post.html" headCtx
            >>= relativizeUrls

    let post_contents = loadAll ("posts/*" .&&. hasNoVersion) :: Compiler [Item String]
    let post_headers = loadAll ("posts/*" .&&. hasVersion "header") :: Compiler [Item String]

    let post_titles = loadAll ("posts/*" .&&. hasVersion "only_title") :: Compiler [Item String]

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< post_contents
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls    

    match "index.html" $ do
        route idRoute
        compile $ do
            all_headers <- recentFirst =<< post_headers
            all_titles <- recentFirst =<< post_titles
            let expanded_prefix = 5
            let first_posts = take expanded_prefix all_headers
            let last_posts = drop expanded_prefix all_titles

            let headerCtx =
                      listField "posts" headCtx (return (first_posts ++ last_posts)) `mappend`
                      defaultContext

            getResourceBody
                >>= applyAsTemplate headerCtx
                >>= loadAndApplyTemplate "templates/default.html" headerCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler



--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

headCtx :: Context String
headCtx =
  field "post_url" (return . flip replaceExtension "html" . toFilePath . itemIdentifier)
    `mappend` postCtx


readerPostOptions :: ReaderOptions
readerPostOptions = defaultHakyllReaderOptions
 
writerHeaderOptions :: WriterOptions
writerHeaderOptions = defaultHakyllWriterOptions{
    writerHTMLMathMethod = MathJax "",
    writerTableOfContents = False
}

writerPostOptions :: WriterOptions
writerPostOptions = defaultHakyllWriterOptions{
    writerHTMLMathMethod = MathJax "",
    writerTableOfContents = True,
    writerTOCDepth = 1
}

isPara :: Block -> Bool
isPara (Para p) = True
isPara _ = False

untilFirstParagraph :: [Block] -> [Block]
untilFirstParagraph x = fst $ foldl (\(acc, fin) b ->
  if fin then (acc, fin) else (
    if isPara b then (acc ++ [b], True) else (acc ++ [b], False)
  )) ([], False) x

addAnchors (Pandoc meta blocks) = Pandoc meta blocks -- (addAnchorsInside blocks)

anchorImage level = Image ("", [], [("width", show size), ("height", show size)]) [] 
  ("../images/anchor.png", "") where size = 17 - 1 * level

anchorLink name lvl = Link ("", [], []) [anchorImage lvl] ("#" ++ name, "")

-- T.pack maps from [Char] to T.Text in case there are problems with it.
-- reverse: T.unpack
getIdenFromAttr :: Attr -> T.Text
getIdenFromAttr (iden, _, _) = T.pack iden
addAnchorToContent :: T.Text -> Int -> [Inline] -> [Inline]
addAnchorToContent iden level content = content ++ [Str " ", anchorLink (T.unpack iden) level]

addAnchorToHeader :: Block -> Block
addAnchorToHeader (Header level attr content) = Header level attr 
  (addAnchorToContent (getIdenFromAttr attr) level content)

addAnchorsInside :: [Block] -> [Block]
addAnchorsInside (Header l a c:t) = addAnchorToHeader (Header l a c):addAnchorsInside t
addAnchorsInside (h:t) = h:addAnchorsInside t
addAnchorsInside [] = []
