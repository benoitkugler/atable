# Build script to execute from www/
# echo "Removing current folder"
# rm -rf atable/ &&
# git clone https://github.com/benoitkugler/atable.git && 
echo "Removing unused files" && 
rm -rf atable/.git atable/atable-web atable/atable-mobile &&
echo "Moving into server/src" && 
cd atable/server/src && 
echo "Building executable" &&
go build *.go && 
echo "Cleaning cache" &&
go clean -modcache && 
rm -rf ../../../../.cache/go-build/ &&
echo "Done."
