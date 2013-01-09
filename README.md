CacheBot
--------

CacheBot integrates with Heroku & your Ruby on Rails app to automatically bust your cache every time you deploy.

SUMMARY
-------
CacheBot sets up a deploy hook on your app once you install it. From then on, every time you deploy any commits with the hashtag "#bust" in them, CacheBot will update your app's $RAILS_CACHE_ID with the latest commit hash.

This effectively busts your entire cache, as Rails prepends the value of that environment variable to every cache lookup.

INSECURE INSTALLATION (10 seconds)
----------------------------------

If you would just like to use this for a test or inconsequential app, just run the following.  CacheBot will take up to 10-20 minutes to recognize your app, but afterwards, cache-busts will happen immediately after deploy.

`heroku sharing:add cache-bot@thirdprestige.com`

Of course, this gives me full access to your code, database, and customer credit card data, so please don't do this for anything of consequence. I TAKE NO RESPONSIBILITY FOR ANY DAMAGE CAUSED.

THE ABOVE SERVICE IS ONLY PROVIDED FOR ACADEMIC PURPOSES.

SECURE INSTALLATION (5 minutes)
-------------------------------

Just set up the app for yourself:

    git clone git@github.com:thirdprestige/heroku-cache-bot.git CacheBot
    cd CacheBot
    heroku create <prefix>-cache-bot --stack cedar
    git push heroku master
    heroku config:add DEPLOYHOOKS_HTTP_URL="https://<prefix>-cache-bot.herokuapp.com/%s" \
      HEROKU_API_KEY=`<API KEY>` SECRET_TOKEN=`openssl rand -base64 32`
    heroku addons:add scheduler:free
    heroku addons:open scheduler

From the Heroku Scheduler Dashboard, please schedule `setup` to run every 10 minutes. (Not `rake setup`, just `setup`. See Procfile.)

Note: CacheBot will install the deployhooks:http addon into any app which it is a collaborator of, and doesn't have a $DEPLOYHOOKS_HTTP_URL already set, including non-Rails-apps, so be forewarned.

AUTOMATICALLY INCLUDE "#BUST" IN YOUR COMMIT MESSAGES
-----------------------------------------------------

So, remembering to add "#bust" to your commit messages is annoying. But you also don't want to nuke your cache every time you deploy a change to your rake tasks, for example. So what to do?  The included "commit-msg" hook should help you out.

Simply copy it into your local Rails project, and it will watch for any changes to any files in app/assets, app/views, or vendor/assets.

Sure, other changes might affect your cache as well, but this should catch most of them.  You can always change this hook later, or manually append #bust to your commit.

    curl https://raw.github.com/thirdprestige/heroku-cache-bot/master/bin/commit-msg > .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    echo "Installed cache-bust commit hook into .git/hooks/commit-msg"

