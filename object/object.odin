package object

import "core:fmt"

import "../ast"


Object :: union {
    int,
    bool,
    ReturnValue,
    ErrorValue,
    Function,
}

ReturnValue :: struct {
    value: ^Object
}

ErrorValue :: struct {
    message: string
}

Function :: struct {
    parameters: [dynamic]^ast.Identifier,
    body: ^ast.BlockStatement,
    environment: ^Environment,
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
        case Function:
            return fmt.aprintf("fn(){}")
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
        case Function:
            return "functon"
    }

    return ""
}