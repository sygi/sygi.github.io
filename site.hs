-------------------------------------------------------------------------------
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

    match "js/**" $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "templates/*" $ compile templateBodyCompiler

    match (fromList ["subpages/about.markdown", "subpages/privacy.markdown", "projects.markdown", "progress.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompilerWith readerPostOptions writerPostOptions
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

-- TODO: clean up once I have access to the sources again.
    match "posts/*.html" $ do
        route idRoute
        compile copyFileCompiler

    match "posts/lost_headers/*.html" $ do
        compile $ do
            getResourceBody
            >>= saveSnapshot "header"

    match "posts/*.markdown" $ do
        route $ setExtension "html"
        compile $
            pandocCompilerWithTransform readerPostOptions writerPostOptions addAnchors
            >>= loadAndApplyTemplate "templates/post-body.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "posts/*.markdown" $ version "header" $ do
        compile $ do
            let getHeaders (Pandoc meta blocks) = Pandoc meta (untilFirstParagraph blocks)
            pandocCompilerWithTransform readerPostOptions writerHeaderOptions getHeaders
            >>= saveSnapshot "header"
            >>= loadAndApplyTemplate "templates/post-body.html" headCtx
            >>= relativizeUrls

    match "posts/*.markdown" $ version "only_title" $
        compile $ do
            let onlyMetadata (Pandoc meta blocks) = Pandoc meta ([])
            pandocCompilerWithTransform readerPostOptions writerHeaderOptions onlyMetadata
            >>= loadAndApplyTemplate "templates/post-body.html" headCtx
            >>= relativizeUrls

    let post_contents = loadAll ("posts/*" .&&. hasNoVersion) :: Compiler [Item String]
    let post_headers = loadAll (("posts/*" .&&. hasVersion "header") .||. "posts/lost_headers/*.html") :: Compiler [Item String]
    let post_titles = loadAll (("posts/*" .&&. hasVersion "only_title") .||. "posts/lost_headers/*.html") :: Compiler [Item String]

    create ["robots.txt"] $ do
        route idRoute
        compile $ getResourceBody >>= relativizeUrls

    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< post_titles
            singlePages <- loadAll $ fromList ["subpages/about.markdown", "subpages/privacy.markdown"]
            let pages = posts `mappend` singlePages
                sitemapCtx =
                    constField "root" root `mappend`
                    listField "pages" headCtx (return pages)
            makeItem ""
                >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
-- TODO: make a single version of the list, remove projects, progress.
    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = headCtx `mappend` bodyField "description" `mappend` urlField "url"
            posts <- recentFirst =<< loadAllSnapshots ("posts/*" .&&. hasVersion "header") "header"
            renderRss feedConfiguration feedCtx posts

    match "index.html" $ do
        route idRoute
        compile $ do
            all_headers <- recentFirst =<< post_headers
            all_titles <- recentFirst =<< post_titles
            let expanded_prefix = 10
            let first_posts = take expanded_prefix all_headers
            let last_posts = drop expanded_prefix all_titles

            let headerCtx =
                      modificationTimeField "modified" "%Y-%m-%d" `mappend`
                      constField "canonical" root `mappend`
                      listField "posts" headCtx (return (first_posts ++ last_posts)) `mappend`
                      defaultContext

            getResourceBody
                >>= applyAsTemplate headerCtx
                >>= loadAndApplyTemplate "templates/default.html" headerCtx
                >>= relativizeUrls



--------------------------------------------------------------------------------
root :: String
root = "https://sygi.github.io"
postCtx :: Context String
postCtx =
    constField "root" root `mappend`
    constField "default_author" "Jakub Sygnowski" `mappend`
    modificationTimeField "modified" "%Y-%m-%d" `mappend`
    dateField "date" "%B %e, %Y" `mappend`
    boolField "is_post" (\_ -> True) `mappend`
    defaultContext

headCtx :: Context String
headCtx =
  field "post_url" urlGenerator `mappend`
  field "url" urlGenerator `mappend`
  postCtx
  where
    urlGenerator item = do
      (return . ("/" ++) . flip replaceExtension "html" . toFilePath . itemIdentifier) item

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

-- Feed
feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle       = "Jakub Sygnowski blog"
    , feedDescription = "Posts on games, programming, and art."
    , feedAuthorName  = "Jakub Sygnowski"
    , feedRoot        = "https://sygi.xyz"
    , feedAuthorEmail = "sygnowski@gmail.com"
    }

-- Post headers on the index page.
isPara :: Block -> Bool
isPara (Para p) = True
isPara _ = False

untilFirstParagraph :: [Block] -> [Block]
untilFirstParagraph x = fst $ foldl (\(acc, fin) b ->
  if fin then (acc, fin) else (
    if isPara b then (acc ++ [b], True) else (acc ++ [b], False)
  )) ([], False) x


-- Anchors Disabled here: they are added automatically by anchorjs
addAnchors (Pandoc meta blocks) = Pandoc meta blocks --(addAnchorsInside blocks)

anchorImage level = Image ("", [], [("width", T.pack (show size)), ("height", T.pack (show size))]) []
  ("../images/anchor.png", "") where size = 17 - 1 * level

anchorLink name lvl = Link ("", [], []) [anchorImage lvl] (T.pack ("#" ++ name), "")

-- T.pack maps from [Char] to T.Text in case there are problems with it.
-- reverse: T.unpack
getIdenFromAttr :: Attr -> T.Text
getIdenFromAttr (iden, _, _) = iden
addAnchorToContent :: T.Text -> Int -> [Inline] -> [Inline]
addAnchorToContent iden level content = content ++ [Str " ", anchorLink (T.unpack iden) level]

addAnchorToHeader :: Block -> Block
addAnchorToHeader (Header level attr content) = Header level attr
  (addAnchorToContent (getIdenFromAttr attr) level content)

addAnchorsInside :: [Block] -> [Block]
addAnchorsInside (Header l a c:t) = addAnchorToHeader (Header l a c):addAnchorsInside t
addAnchorsInside (h:t) = h:addAnchorsInside t
addAnchorsInside [] = []
