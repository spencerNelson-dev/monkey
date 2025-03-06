package object

Environment :: struct {
    store: map[string]Object,
    outer: ^Environment,
}


new_enclosed_envrionment ::proc(outer: ^Environment) -> ^Environment {
    env := new(Environment)
    env.outer = outer
    return env
}

get_from_env :: proc(env: ^Environment, name: string) -> (Object, bool) {
    obj, ok := env.store[name]
    if !ok && env.outer != nil {
        obj, ok = get_from_env(env.outer, name)
    }

    return obj, ok
}