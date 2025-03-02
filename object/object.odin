package object

import "core:fmt"

ObjectType :: enum {
    NULL,
    INTEGER,
    BOOLEAN,
}

Object :: union {
    Null,
    Integer,
    Boolean,
}

Integer :: struct {
    type: ObjectType,
    value: int,
}

Boolean :: struct {
    type: ObjectType,
    value: bool
}

Null :: struct {}

inspect :: proc(object: Object) -> string {
    switch o in object {
        case Null:
            return "null"
        case Integer:
            return fmt.aprintf("%v", o.value)
        case Boolean:
            return fmt.aprint("%v", o.value)
    }

    return ""
}