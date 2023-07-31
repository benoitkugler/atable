# Build the project and copy the files into the static server folder 
npm run build &&
cd .. &&
rm -r server/static/atable-web &&
mkdir server/static/atable-web && 
cp -r atable-web/dist/* server/static/atable-web/ &&
echo "Fichier copiés dans server/static/atable-web/"