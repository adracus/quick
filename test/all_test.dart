library quick.test.all;

import 'quick_handler_test.dart' as handler_test;
import 'quick_pattern_test.dart' as pattern_test;
import 'quick_route_test.dart' as route_test;
import 'quick_server_test.dart' as server_test;
import 'quick_middleware_test.dart' as middleware_test;

main() {
  handler_test.defineTests();
  pattern_test.defineTests();
  route_test.defineTests();
  server_test.defineTests();
  middleware_test.defineTests();
}
