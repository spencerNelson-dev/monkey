package evaluator

import "../ast"
import "../object"

NULL :: object.Null{}
TRUE :: object.Boolean{value = true}
FALSE :: object.Boolean{value = false}

eval :: proc {
    eval_statement,
    eval_expression,
}

eval_statements :: proc(stmts: []ast.Statement) -> ^object.Object {
    result: ^object.Object

    for s in stmts {
        result = eval(s)
    }

    return result
}

eval_expression :: proc(node: ast.Expression) -> ^object.Object {
    obj := new(object.Object)
    obj^ = NULL
    #partial switch n in node {
        case ast.IntegerLiteral:
            obj^ = object.Integer {type = .INTEGER, value = n.value}
        case ast.BoolLiteral:
            if n.value {
                obj^ = TRUE
            } else {
                obj^ = FALSE
            }
        case ast.PrefixExpression:
            right := eval(n.right^)
            obj^ = eval_prefix_expression(n.operator, right)
        case ast.InfixExpression:
            left := eval(n.Left^)
            right := eval(n.Right^)
            obj^ = eval_infix_expression(n.operator, left, right)
    }

    return obj
}

eval_statement :: proc(node: ast.Statement) -> ^object.Object {

    #partial switch n in node {
        case ast.Program:
            return eval_statements(n.statements[:])
        case ast.ExpressionStatement:
            return eval(n.expression)
    }

    obj := new(object.Object)
    obj^ = NULL
    return obj
}

eval_infix_expression :: proc(operator: string, left: ^object.Object, right: ^object.Object) -> object.Object {
    right_val, right_ok := right.(object.Integer)
    left_val, left_ok := left.(object.Integer)

    if left_ok && right_ok {
        return eval_int_infix_expression(operator, left_val, right_val)
    } else {
        return NULL
    }
}

eval_int_infix_expression :: proc(op: string, left: object.Integer, right: object.Integer) -> object.Object {
    r := right.value
    l := left.value
    switch op {
        case "+":
            return object.Integer{value = l + r}
        case "-":
            return object.Integer{value = l - r}
        case "*":
            return object.Integer{value = l * r}
        case "/":
            return object.Integer{value = l / r}
        case "<":
            return native_bool_to_bool_obj(l < r)
        case ">":
            return native_bool_to_bool_obj(l > r)
        case "==":
            return native_bool_to_bool_obj(l == r)
        case "!=":
            return native_bool_to_bool_obj(l != r)
        case:
            return NULL
    }
}

eval_prefix_expression :: proc(operator: string, right: ^object.Object) -> object.Object {
    switch operator {
        case "!":
            return eval_bang_operator_expression(right)
        case "-":
            return eval_minus_operator_expression(right)
        case:
            return NULL
    }
}

eval_bang_operator_expression :: proc(right: ^object.Object) -> object.Object {
    switch &r in right {
        case object.Boolean:
            r.value = !r.value
        case object.Integer:
            return NULL
        case object.Null:
            return NULL
    }

    return right^
}

eval_minus_operator_expression :: proc(right: ^object.Object) -> object.Object {
    #partial switch &r in right {
        case object.Integer:
            r.value = -r.value
            return right^
        case:
            return NULL
    }
}

native_bool_to_bool_obj :: proc(b: bool) -> object.Object {
    return object.Boolean{type = .BOOLEAN, value = b}
}