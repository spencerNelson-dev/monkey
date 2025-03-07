package object

import "core:fmt"

import "../ast"


Object :: union {
    int,
    bool,
    ReturnValue,
    ErrorValue,
    Function,
    StringValue,
    Builtin,
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

StringValue :: struct {
    value: string
}

Builtin :: struct {
    fn: BuiltinFunction
}

BuiltinFunction :: proc(args: ..Object) -> Object

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
        case StringValue:
            return o.value
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
        case StringValue:
            return "string"
        case Builtin:
            return "builtin"
    }

    return ""
}