#include "ruby.h"
 
int main() {return 0;}
int t() { void ((*volatile p)()); p = (void ((*)()))main; return 0; }
int t2() { main(); return 0; }
