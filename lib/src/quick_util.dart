library quick.util;

typedef ZeroArityFunction();

eval(arg) {
  if (arg is ZeroArityFunction) return arg();
  return arg;
}
