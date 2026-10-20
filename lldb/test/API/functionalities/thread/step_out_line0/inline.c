__attribute__((always_inline)) static inline int after_return(int value) {
#line 0
  volatile int saved = value;
  return saved + 7;
}
#line 7
__attribute__((noinline)) int step_out_of_here(int value) {
  return value + 5; // Set breakpoint here
}
int main(void) {
  volatile int input = 3;
  int value = after_return(step_out_of_here(input));
  value += 11;
  return value; // Ran too far
}
