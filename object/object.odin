package object

import "core:fmt"


Object :: union {
    int,
    bool,
    ReturnValue,
    ErrorValue,

}

ReturnValue :: struct {
    value: ^Object
}

ErrorValue :: struct {
    message: string
}


inspect :: proc(object: Object) -> string {
    #partial switch o in object {
        case nil:
            return "null"
        case int:
            return fmt.aprintf("%v", o)
        case bool:
            return fmt.aprint("%v", o)
        case ReturnValue:
            return inspect(o.value^)
        case ErrorValue:
            return fmt.aprintf("ERROR: %v", o.message)
    }

    return ""
}

get_type :: proc(object: Object) -> string {
    switch o in object {
        case nil:
            return "nil"
        case int:
            return "int"
        case bool:
            return "bool"
        case ReturnValue:
            return "return"
        case ErrorValue:
            return "error"
    }

    return ""
}