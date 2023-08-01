enum BuildMode { dev, prod }

class Env {
  final BuildMode bm;
  const Env(this.bm);

  Uri urlFor(String endPoint,
      {Map<String, String> queryParameters = const {}}) {
    if (bm == BuildMode.dev) {
      return Uri(
          scheme: "http",
          host: "localhost",
          port: 1323,
          path: endPoint,
          queryParameters: queryParameters);
    }
    return Uri(
        scheme: "https",
        host: "intendance.alwaysdata.net",
        path: endPoint,
        queryParameters: queryParameters);
  }

  Uri importSejourLink(String idSejour) {
    return urlFor("import-sejour", queryParameters: {"id": idSejour});
  }
}
