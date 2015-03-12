library quick.pattern;

class UrlMatcher {
  final RegExp regex;
  final UrlKeys keys;
  
  UrlMatcher.parse(String path)
      : regex = toRegex(path),
        keys = new UrlKeys.parse(path);
  
  static RegExp toRegex(String path) {
    var regexProto = path.replaceAll(new RegExp(r":\w+"), r"\w+");
    return new RegExp(regexProto);
  }
  
  bool matches(String path) {
    var match = regex.matchAsPrefix(path);
    if (null == match) return false;
    match = match.group(0);
    return path.length == match.length;
  }
  
  int longestMatch(String path) => regex.matchAsPrefix(path).group(0).length;
  
  bool operator==(other) {
    if (other is! UrlMatcher) return false;
    return this.regex.pattern == other.regex.pattern;
  }
  
  int get hashCode => this.regex.pattern.hashCode;
}

class UrlKeys {
  final Map<String, int> keys;
  
  UrlKeys.parse(String path)
      : keys = parseKeys(path);
  
  Map<String, String> parameters(String path) {
    var parts = path.split("/");
    var result = {};
    keys.forEach((key, index) {
      result[key] = parts[index];
    });
    return result;
  }
  
  static Map<String, int> parseKeys(String path) {
    var keys = new RegExp(r":\w+") // All words with preceeding ":"
      .allMatches(path)
      .map((match) => match.group(0));
    
    if (_isNonUnique(keys))
      throw new ArgumentError.value(path, "path", "Repetitive keys in $path");
    
    var result = {};
    var parts = path.split("/");
    keys.forEach((key) => result[key.substring(1)] = parts.indexOf(key));
    
    return result;
  }
  
  static bool _isNonUnique(Iterable<String> strings) {
    return strings.toSet().length != strings.length;
  }
}