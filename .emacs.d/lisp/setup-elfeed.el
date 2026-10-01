;;; setup-elfeed.el --- Feed reader -*- lexical-binding: t; -*-

(use-package elfeed
  :bind ("C-c e" . elfeed)
  :init
  (setq elfeed-feeds
        '(("https://www.version2.dk/rss" dk tech it version2)
          ("https://www.dr.dk/nyheder/service/feeds/senestenyt" dk news)
          ("https://elixirforum.com/rss" elixir dev forum)
          ("https://techcrunch.com/feed" tech news)
          ("https://www.theverge.com/rss/index.xml" tech news)
          ("https://huggingface.co/blog/feed.xml" ai dev)
          ("https://www.technologyreview.com/topic/artificial-intelligence/feed/" ai news))))

;;; setup-elfeed.el ends here
