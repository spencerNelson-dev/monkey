package evaluator

import "core:fmt"

import "../ast"
import "../object"

eval :: proc {
    eval_statement,
    eval_expression,
}

eval_statements :: proc(stmts: []ast.Statement) -> ^object.Object {
    result: ^object.Object

    for s in stmts {
        result = eval(s)

        if result != nil {
            rt := object.get_type(result^)

            if rt == "return" || rt == "error" {
                return result
            }
        }

        if returnValue, ok := result.(object.ReturnValue); ok {
            return returnValue.value
        }
    }

    return result
}

eval_expression :: proc(node: ast.Expression) -> ^object.Object {
    obj := new(object.Object)
    #partial switch n in node {
        case ast.IntegerLiteral:
            obj^ = n.value
        case ast.BoolLiteral:
            if n.value {
                obj^ = true
            } else {
                obj^ = false
            }
        case ast.PrefixExpression:
            right := eval(n.right^)
            if is_error(right){ return right}
            obj^ = eval_prefix_expression(n.operator, right)
        case ast.InfixExpression:
            left := eval(n.Left^)
            if is_error(left){ return left}
            right := eval(n.Right^)
            if is_error(right){ return right}
            obj^ = eval_infix_expression(n.operator, left, right)
        case ast.IfExpression:
            obj^ = eval_if_expression(n)
    }

    return obj
}

eval_statement :: proc(node: ast.Statement) -> ^object.Object {

    #partial switch n in node {
        case ast.Program:
            return eval_program(n)
        case ast.ExpressionStatement:
            return eval(n.expression)
        case ast.BlockStatement:
            return eval_statements(n.statements[:])
        case ast.ReturnStatement:
            val := eval(n.expression)
            if is_error(val){ return val}
            rv := new(object.Object)
            rv^ = object.ReturnValue{value = val}
            return rv
        case ast.LetStatement:
            val := eval(n.expression)
            if is_error(val){return val}
    }

    obj := new(object.Object)

    return obj
}

eval_program :: proc(program: ast.Program) -> ^object.Object {
    result: ^object.Object

    for s in program.statements {
        result = eval(s)

        #partial switch r in result {
            case object.ReturnValue:
                return r.value
            case object.ErrorValue:
                return result
        }
    }

    return result
}

eval_infix_expression :: proc(operator: string, left: ^object.Object, right: ^object.Object) -> object.Object {
    right_val, right_ok := right.(int)
    left_val, left_ok := left.(int)

    if left_ok && right_ok {
        return eval_int_infix_expression(operator, left_val, right_val)
    } else if object.get_type(left^) != object.get_type(right^) {
        return new_error("type mismatch: %v %v %v",
            object.get_type(left^), operator, object.get_type(right^))^
    } else {
        return new_error("unknown operator: %v %v %v",
            object.get_type(left^), operator,object.get_type(right^))^
    }
}

eval_int_infix_expression :: proc(op: string, left: int, right: int) -> object.Object {
    switch op {
        case "+":
            return left + right
        case "-":
            return left - right
        case "*":
            return left * right
        case "/":
            return left / right
        case "<":
            return left < right
        case ">":
            return left > right
        case "==":
            return left == right
        case "!=":
            return left != right
        case:
            return new_error("unknown operator: %s %s %s", object.get_type(left), op, object.get_type(right))^
    }
}

eval_prefix_expression :: proc(operator: string, right: ^object.Object) -> object.Object {
    switch operator {
        case "!":
            return eval_bang_operator_expression(right)
        case "-":
            return eval_minus_operator_expression(right)
        case:
            return new_error("unknown operator: %s%s", operator, object.get_type(right^))^
    }
}

eval_bang_operator_expression :: proc(right: ^object.Object) -> object.Object {
    #partial switch &r in right {
        case bool:
            r = !r
        case int:
            return new_error("unknown operator: %s%s", "!", object.get_type(right^))^
        case nil:
            return new_error("unknown operator: %s%s", "!", object.get_type(right^))^
    }

    return right^
}

eval_minus_operator_expression :: proc(right: ^object.Object) -> object.Object {
    switch &r in right {
        case int:
            r = -r
            return right^
        case bool, object.ReturnValue, object.ErrorValue:
            return new_error("unknown operator: -%s", object.get_type(r))^
        case:
            return nil
    }
}


eval_if_expression :: proc(ie: ast.IfExpression) -> object.Object {
    condition := eval_expression(ie.condition^)
    if is_error(condition) {return condition^}

    if is_truthy(condition^) {
        return eval_statement(ie.consequence^)^
    } else if ie.alternative != nil {
        return eval_statement(ie.alternative^)^
    } else {
        return nil
    }

    return nil
}

is_truthy :: proc (obj: object.Object) -> bool {
    #partial switch o in obj {
        case nil:
            return false
        case int:
            return false
        case bool:
            return o
    }

    return false
}

new_error :: proc(format: string, a: ..any) -> ^object.ErrorValue {
    message := fmt.tprintfln(format, ..a)
    return new_clone(object.ErrorValue{message = message})
}  

is_error :: proc(obj: ^object.Object) -> bool {
    if obj != nil {
        return object.get_type(obj^) == "error"
    }
    return false
}