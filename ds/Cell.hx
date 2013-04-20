package ds;

enum Cell<T> {
    Cons(head:T, tail:Cell<T>);
    Nil;
}