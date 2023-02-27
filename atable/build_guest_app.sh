flutter build web -t lib/main_shop_guest.dart --base-href=/shop/ && 
# uncomment to build in "debug" mode
# flutter build web --profile --dart-define=Dart2jsOptimization=O0 -t lib/main_prof_loopback.dart --base-href=/shop/ && 
echo "Moving build to server/static/shop..." && 
rm -r ../server/static/shop/ && 
mkdir ../server/static/shop && 
cp -r build/web/* ../server/static/shop &&
echo "Removing unused music..." && 
rm ../server/static/shop/assets/assets/music/* &&
echo "Fixing bug https://github.com/flutter/flutter/issues/53745..." && 
sed -i -e 's/return cache.addAll/cache.addAll/g' ../server/static/shop/flutter_service_worker.js &&
echo "Done."