#!/bin/bash
/bin/bash /sbin/entrypoint.sh
echo "starting services"
service nginx restart
service php7.0-fpm restart
usermod -d /var/lib/mysql/ mysql
service mysql restart

echo "installing magento2"
cd /var/www/html/
sed -i -e 's/MAGENTO_REPO_USERNAME/'"${MAGENTO_REPO_USER}"'/g' /root/.composer/auth.json
sed -i -e 's/MAGENTO_REPO_PASSWORD/'"${MAGENTO_REPO_KEY}"'/g' /root/.composer/auth.json
echo "$VIRTUAL_HOST"
if [ -f ./app/etc/config.php ] || [ -f ./app/etc/env.php ]; then
  echo "It appears Magento is already installed (app/etc/config.php or app/etc/env.php exist). Exiting setup..."
  php ./bin/magento setup:store-config:set --base-url=$VIRTUAL_HOST
  php ./bin/magento cache:clean
  echo "###ready to use### ;)"
  while true; do sleep 1000; done
  exit
fi

mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $M2_DB;
CREATE USER '$M2_USER'@'localhost' IDENTIFIED BY '$M2_PASSWORD';
GRANT ALL PRIVILEGES ON $M2_DB.* TO '$M2_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
php ./bin/magento setup:install --db-host=localhost --db-name=$M2_DB --db-user=$M2_USER --db-password=$M2_PASSWORD --base-url=$VIRTUAL_HOST --admin-firstname=firstname --admin-lastname=lastname --admin-email=$MAGE_ADMIN_EMAIL --admin-user=$MAGE_ADMIN_USER --admin-password=$MAGE_ADMIN_PASSWORD --backend-frontname=admin
cp /root/.composer/auth.json /var/www/html/var/composer_home/.
if [[ $INSTALL_SAMPLE_DATA == 1 ]]; then
    echo "Installing Sample Data"
    php ./bin/magento sampledata:deploy
    php ./bin/magento setup:upgrade
fi
php ./bin/magento indexer:reindex
composer require girginsoft/module-shopfinder dev-master
rm -rf app/code/Girginsoft
php bin/magento module:enable Girginsoft_Shopfinder
php bin/magento setup:upgrade
echo "Changing ownership"
chown -R www-data .
service nginx restart
echo "installation completed"
while true; do sleep 1000; done
