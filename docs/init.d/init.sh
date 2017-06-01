HUGO_URL=https://github.com/spf13/hugo/releases/download/v0.20.7/hugo_0.20.7_Linux-64bit.tar.gz;
SHARED_FOLDER=/etc/shared
LANDING_FOLDER="$SHARED_FOLDER/landing"
CI_FOLDER="$SHARED_FOLDER/ci"
ERROR_PAGES_FOLDER=/var/www/public/errors

# install python, sphinx and breathe
echo 'Installing python, sphinx and breathe...';
apk --update add python py-pip && \
pip install Sphinx --no-cache-dir && \
pip install alabaster --no-cache-dir && \
pip install breathe --no-cache-dir;

# install doxygen
echo 'Installing doxygen...';
apk add doxygen;

# install nodejs and npm
echo 'Installing node & npm...';
apk add nodejs;

# install gettext
# gettext is installed only because of the envsubst
echo 'Installing gettext...';
apk add gettext;

# install hugo
echo 'Installing hugo...';
apk add curl && \
apk add tar && \
#rm -rf /var/cache/apk &&
mkdir -p /tmp/hugo && \
curl -L -o /tmp/hugo/hugo.tar.gz $HUGO_URL && \
cd /tmp/hugo && \
tar -zxf hugo.tar.gz && \
mv hugo /bin && \
cd ~ && rm -rf /tmp/hugo;

# clone ci shared repo
if [ ! -d "$CI_FOLDER" ]; then
        echo 'Cloning CI shared repo...';
        git clone https://github.com/src-d/ci.git $CI_FOLDER;
fi;

# install landing and export commons
if [ ! -d "$LANDING_FOLDER" ]; then
        echo 'Installing landing and exporting commons...';
        git clone https://github.com/src-d/landing.git $LANDING_FOLDER;
fi;

# export landing commons
cd $LANDING_FOLDER && \
make export-landing-commons target=landing-common.tar;

# prepare all hugo template assets
cd "$CI_FOLDER/docs/site-generator/hugo-template" \
        && make dependencies LANDING_PATH="$LANDING_FOLDER";

# build error-pages hugo
# TODO: use the hugo-template instead
echo 'Building error pages...';
mkdir -p /tmp/error-pages-hugo-build && \
cd /tmp/error-pages-hugo-build && \
cp "$LANDING_FOLDER/landing-common.tar" . && \
tar -xf landing-common.tar && \
mkdir -p hugo/content && \
cp "$CI_FOLDER/docs/error-pages/404.md" hugo/content && \
cp "$CI_FOLDER/docs/error-pages/500.md" hugo/content && \
mkdir -p hugo/layouts/_default && \
cp "$CI_FOLDER/docs/error-pages/tpl.html" hugo/layouts/_default/single.html;

# make and install error-pages
echo 'Installing error-pages...';
hugo --config hugo.config.yaml && \
mv public/404/index.html public/404.html && \
mv public/500/index.html public/500.html && \
rm -rf public/404 public/500 && \
cp -R public/* $ERROR_PAGES_FOLDER;
cd ~ && rm -rf /tmp/error-pages-hugo-build;
