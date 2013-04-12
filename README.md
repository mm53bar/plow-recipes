Plow Recipes
=============

[Plow](https://github.com/mm53bar/plow) is a server provisioning tool for devs.

This repository is a public source for my plow recipes. Note that even though these recipes were written for use in plow, they're just Bash and you can use them all by themselves or as part of some other tool like Linode Stackscripts.

How to Use
==========

Install plow into your app:

    curl https://raw.github.com/mm53bar/plow/master/install.sh | sh

Edit the Plowfile that was created with the recipes that you'd like to use. I tend to go with something like this:

    RECIPES=(
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/build_essential.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/deployer.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/one_ruby.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/nginx_source.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/postgres.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/vhost.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/rails_app.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/nodejs.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/papertrail.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/datadog.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/s3fs.sh
      https://raw.github.com/mm53bar/plow-recipes/master/ubuntu/precise/pg_backup.sh
    )
 
    FILES=(
      ~/.ssh/id_rsa.pub
      ~/Dropbox/my_cert.crt
      ~/Dropbox/my_cert.key
    )
    
This gives me the skeleton of a Rails app that uses nginx, unicorn and postgres. It uses [Papertrail](http://papertrailapp.com) for logging, [DataDog](http://datadog.com) for metrics and backs up postgres to Amazon S3.

To support the recipes, you need to configure some attributes.  For example, the s3fs recipe needs to know your Amazon keys so that it can store your postgres backups.  Specify your attributes as bash variables in a `.env` file. For a production server, create an `.env.production` file similar to this:

    RUBY_VERSION="1.9.3-p125"
    DOMAIN_NAME="example.com"
    USER="my_app_name"
    APP_NAME="my_app_name"
    GIT_HOST="github.com"
    SSL_KEY="my_cert.key"
    SSL_CERT="my_cert.crt"
    DB_USER="my_app_name"
    DB_PASSWORD="P455W0RD"
    DB_NAME="my_app_name_production"
    PAPERTRAIL_PORT="34235"
    DATADOG_KEY="34lh3jk4h62kj3h6jk23h6h23234hjj"
    AWS_ACCESS_KEY="2345LKNASLDNF23"
    AWS_SECRET_KEY="a0708asASF2664asdjlASETGA26100askjdls1w3n23"
    S3_BUCKET="my_app_name-production"

Now you just need a server.  You can use [pave](http://github.com/mm53bar/pave) for this. Or just specify your server connection info in `.env.production`:

    SERVER=23.23.64.23

You're all set to provision your server. Run the following:

    bin/plow --env production build_essential deployer one_ruby nginx_source\
      postgres vhost rails_app nodejs papertrail datadog s3fs pg_backup
    
That's it!