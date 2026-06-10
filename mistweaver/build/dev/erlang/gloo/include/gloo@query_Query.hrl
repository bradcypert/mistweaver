-record('query', {
    table :: binary(),
    op :: gloo@query:op(),
    decoder :: gleam@dynamic@decode:decoder(any())
}).
