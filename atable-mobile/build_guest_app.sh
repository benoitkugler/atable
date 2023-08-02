flutter build web -t lib/main_shop_guest.dart --web-renderer canvaskit --base-href=/shop-session/ && 
# uncomment to build in "debug" mode
# flutter build web --profile --dart-define=Dart2jsOptimization=O0 -t lib/main_prof_loopback.dart --base-href=/shop/ && 
echo "Moving build to server/static/shop-session..." && 
rm -r ../server/static/shop-session/ && 
mkdir ../server/static/shop-session && 
cp -r build/web/* ../server/static/shop-session &&
# echo "Fixing bug https://github.com/flutter/flutter/issues/53745..." && 
# sed -i -e 's/return cache.addAll/cache.addAll/g' ../server/static/shop-session/flutter_service_worker.js &&
echo "Done."