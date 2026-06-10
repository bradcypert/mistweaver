-record(live_view, {
    init :: fun((list({binary(), binary()})) -> {any(),
        lustre@effect:effect(any())}),
    update :: fun((any(), any()) -> {any(), lustre@effect:effect(any())}),
    view :: fun((any()) -> lustre@vdom@vnode:element(any()))
}).
