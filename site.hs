--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Options
import           Text.Pandoc.Definition
import           System.FilePath (replaceExtension)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "js/*" $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "projects.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $
            pandocCompilerWith defaultHakyllReaderOptions pandocPostOptions
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "posts/*" $ version "header" $
        compile $ do
            let getHeaders (Pandoc meta blocks) = Pandoc meta (untilFirstParagraph blocks)
            pandocCompilerWithTransform defaultHakyllReaderOptions pandocHeaderOptions getHeaders
            >>= loadAndApplyTemplate "templates/post.html" headCtx
            >>= relativizeUrls

    let post_contents = loadAll ("posts/*" .&&. hasNoVersion) :: Compiler [Item String]
    let post_headers = loadAll ("posts/*" .&&. hasVersion "header") :: Compiler [Item String]

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
            all_posts <- recentFirst =<< post_headers
            let some_posts = take 3 all_posts

            let headerCtx =
                      listField "posts" headCtx (return some_posts) `mappend`
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
    field "post_url" (return . flip replaceExtension "html" . toFilePath . itemIdentifier) `mappend`
    postCtx

pandocHeaderOptions :: WriterOptions
pandocHeaderOptions = defaultHakyllWriterOptions{
    writerHTMLMathMethod = MathJax "",
    writerTableOfContents = False
}

pandocPostOptions :: WriterOptions
pandocPostOptions = defaultHakyllWriterOptions{
    writerHTMLMathMethod = MathJax "",
    writerTableOfContents = True,
    writerTOCDepth = 1
}

untilFirstParagraph :: [Block] -> [Block]
untilFirstParagraph [] = []
untilFirstParagraph (Para p:t) = [Para p]
untilFirstParagraph (h:t) = h:untilFirstParagraph t
-- TODO: there's a function for that
