#!/bin/sh
echo "INIT Drupal.ru"

CORE='drupal-7'
CONTRIB="bbcode bueditor captcha  comment_notify diff-7.x-3.x-dev geshifilter gravatar imageapi noindex_external_links pathauto privatemsg simplenews smtp spambot jquery_update token rrssb  fontawesome transliteration libraries bootstrap_lite xbbcode ban_user quote-7.x-1.x-dev l10n_update"

echo "Full site path: $DOCROOT"
echo "Site core: $CORE"
echo "Deploy DIR: $ZENCI_DEPLOY_DIR"

cd $DOCROOT
echo "Process make."

drush dl $CORE --drupal-project-rename="drupal"

rsync -a $DOCROOT/drupal/ $DOCROOT
rm -rf drupal

echo "Install DRUPAL"

/usr/bin/drush site-install standard -y --root=$DOCROOT --account-name=$ACCOUNT_NAME --account-mail=$ACCOUNT_MAIL --account-pass=$ACCOUNT_PASS --uri=http://$DOMAIN --site-name="$SITE_NAME" --site-mail=$SITE_MAIL --db-url=mysqli://$DATABASE_USER:$DATABASE_PASS@localhost/$DATABASE_NAME

echo "make libraries dir"
mkdir $DOCROOT/sites/all/libraries

echo "Install contrib modules"

mkdir -p $DOCROOT/sites/all/modules/contrib
drush dl $CONTRIB
drush -y en $CONTRIB

echo "Install captcha_pack"
drush dl captcha_pack
drush -y en ascii_art_captcha css_captcha

echo "Install other modules"
drush -y en imageapi_imagemagick pm_block_user pm_email_notify privatemsg_filter  views_ui book forum

echo "Prepare github modules dir"
mkdir -p $DOCROOT/sites/all/modules/github

echo "Install inner poll"

cd $DOCROOT/sites/all/modules/github
git clone --branch master http://git.drupal.org/sandbox/andypost/1413472.git inner_poll
cd  inner_poll
git checkout 7.x-1.x

echo "Deploy module"

cd  $DOCROOT/sites/all/modules/github
git clone https://github.com/itpatrol/drupal_deploy.git
cd drupal_deploy
git checkout 7.x

echo "Altpager"
cd  $DOCROOT/sites/all/modules/github
git clone https://github.com/itpatrol/altpager

echo "Alttracker"
cd  $DOCROOT/sites/all/modules/github
git clone https://github.com/itpatrol/alttracker

cd $DOCROOT
drush -y en inner_poll altpager alttracker drupal_deploy

echo "Install drupal.ru modules"
mkdir -p $DOCROOT/sites/all/modules/local

ln -s $ZENCI_DEPLOY_DIR/modules/* $DOCROOT/sites/all/modules/local/

echo "Enable quote"
drush en -y quote

echo "Enable dru_comment_quote"
drush en -y dru_comment_quote

echo "Install Font awesome"
cd  $DOCROOT/sites/all/libraries
git clone https://github.com/FortAwesome/Font-Awesome.git fontawesome


echo "Install drupal.ru themes"
mkdir -p $DOCROOT/sites/all/themes/local

ln -s $ZENCI_DEPLOY_DIR/themes/* $DOCROOT/sites/all/themes/local/

echo "Set default theme"
cd $DOCROOT

echo "Set default variables"
drush vset theme_default alpha
drush vset filestore_tmp_dir /tmp
drush vset admin_theme alpha

echo "Update translation";
drush -y dl drush_language
drush language-add ru
drush language-default ru
drush -y l10n-update-refresh
drush -y l10n-update

#set auto update weekly
drush vset l10n_update_check_frequency 7



echo "Import META structure via module http://github.com/itpatrol/drupal_deploy."

echo "Import roles"
drush ddi roles --file=$ZENCI_DEPLOY_DIR/data/roles.export

echo "Import filters"
drush ddi filters --file=$ZENCI_DEPLOY_DIR/data/filters.export

echo "Import nodetypes"
drush ddi node_types --file=$ZENCI_DEPLOY_DIR/data/blog.node_types.export

echo "Import taxonomy"
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_1.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_2.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_3.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_4.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_5.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_7.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_8.taxonomy.export
drush ddi taxonomy --file=$ZENCI_DEPLOY_DIR/data/vocabulary_10.taxonomy.export

echo "Import forum"
drush ddi forum --file=$ZENCI_DEPLOY_DIR/data/forum.export

echo "Import menu structure"
drush ddi menu --file=$ZENCI_DEPLOY_DIR/data/main-menu.menu_links.export
drush ddi menu --file=$ZENCI_DEPLOY_DIR/data/user-menu.menu_links.export

echo "Import block settings"
drush ddi blocks --file=$ZENCI_DEPLOY_DIR/data/alpha-init.blocks.export

echo "Import theme settings"

drush ddi variables --file=$ZENCI_DEPLOY_DIR/data/theme_alpha_settings.variables.export

echo "Set default tmp"
drush vset filestore_tmp_dir /tmp

#Issue #148 enable compression
echo "Enable compression for js, css"
drush vset preprocess_css 1
drush vset preprocess_js 1

if [ "$DEVEL" != "" ]; then
  cd $DOCROOT
  drush dl devel
  drusn -y en devel devel_generate
  drush generate-content 100
  drush generate-users 100
fi
echo "Please check http://$DOMAIN"
