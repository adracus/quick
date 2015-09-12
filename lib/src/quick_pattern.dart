library quick.pattern;

/** A matcher that destructures and extracts parameters from an [Uri]. */
class UrlMatcher {
  /** The regex for the matcher. */
  final RegExp regex;

  /** The specified url keys for this matcher. */
  final UrlKeys keys;

  /** Parses a path and creates a new [UrlMatcher]. */
  UrlMatcher.parse(String path)
      : regex = toRegex(path),
        keys = new UrlKeys.parse(path);

  /** Transforms the given path into a regex for matching. */
  static RegExp toRegex(String path) {
    var regexProto = path.replaceAll(new RegExp(r":\w+"), r"\w+");
    return new RegExp(regexProto);
  }

  /** Checks whether this matches the given path. */
  bool matches(String path) {
    var match = regex.matchAsPrefix(path);
    if (null == match) return false;
    match = match.group(0);
    return path.length == match.length;
  }

  /** Extracts all url parameters from the given path. */
  Map<String, String> parameters(String path) => keys.parameters(path);

  bool operator ==(other) {
    if (other is! UrlMatcher) return false;
    return this.regex.pattern == other.regex.pattern;
  }

  int get hashCode => this.regex.pattern.hashCode;
}

class UrlKeys {
  /** The names and indexes of the url keys. */
  final Map<String, int> keys;

  /** Parses and creates a new [UrlKeys] instance from the given path. */
  UrlKeys.parse(String path) : keys = parseKeys(path);

  /** Extracts and returns the parameters from the given path. */
  Map<String, String> parameters(String path) {
    var parts = path.split("/");
    var result = {};
    keys.forEach((key, index) {
      result[key] = parts[index];
    });
    return result;
  }

  /** Parses the keys and returns a map with the keys and their positions. */
  static Map<String, int> parseKeys(String path) {
    var keys = new RegExp(r":\w+") // All words with preceeding ":"
        .allMatches(path)
        .map((match) => match.group(0));

    if (_isNonUnique(keys)) throw new ArgumentError.value(
        path, "path", "Repetitive keys in $path");

    var result = {};
    var parts = path.split("/");
    keys.forEach((key) => result[key.substring(1)] = parts.indexOf(key));

    return result;
  }

  /** Checks if some keys are mentioned multiple times. */
  static bool _isNonUnique(Iterable<String> strings) {
    return strings.toSet().length != strings.length;
  }
}
