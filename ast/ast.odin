package ast

import "core:fmt"
import "core:strings"

import "../token"

Program :: struct {
    statements: [dynamic]Statement,
    errors: [dynamic]string,
}

Statement :: union {
    Program,
    LetStatement,
    ReturnStatement,
    ExpressionStatement,
    BlockStatement,
}

LetStatement :: struct {
    token: token.Token,
    name: Identifier,
    expression: Expression
}

ReturnStatement :: struct {
    token: token.Token,
    expression: Expression
}

ExpressionStatement :: struct {
    token: token.Token,
    expression: Expression
}

BlockStatement :: struct {
    token: token.Token,
    statements: [dynamic]Statement,
}


Expression :: union {
    Identifier,
    IntegerLiteral,
    BoolLiteral,
    StringLiteral,
    PrefixExpression,
    InfixExpression,
    IfExpression,
    FunctionLiteral,
    CallExpression,
    ERROR,
}

Identifier :: struct {
    token: token.Token,
    value: string
}

IntegerLiteral :: struct {
    token: token.Token,
    value: int
}

BoolLiteral :: struct {
    token: token.Token,
    value: bool,
}

StringLiteral :: struct {
    token: token.Token,
    value: string,
}

PrefixExpression :: struct {
    token: token.Token,
    operator: string,
    right: ^Expression,
}

InfixExpression :: struct {
    token: token.Token,
    Left: ^Expression,
    operator: string,
    Right: ^Expression,
}

IfExpression :: struct {
    token: token.Token,
    condition: ^Expression,
    consequence: ^BlockStatement,
    alternative: ^BlockStatement,
}

FunctionLiteral :: struct {
    token: token.Token,
    parameters: [dynamic]^Identifier,
    body: ^BlockStatement,
}

CallExpression :: struct {
    token: token.Token,
    function: ^Expression,
    arguments: [dynamic]^Expression
}

ERROR :: struct {
    message: ^string
}

print_program :: proc (p: ^Program){
    builder := strings.builder_make()
    for s in p.statements {
        strings.write_string(&builder, print_statement(s))
        strings.write_string(&builder, "\n")
    }

    fmt.println(strings.to_string(builder))

    free_all(context.temp_allocator)
}

print_statements :: proc(statements: []Statement) -> string {
    b := strings.builder_make(context.temp_allocator)
    strings.write_string(&b, " {\n")
    for s in statements {
        the_string := print_statement(s)
        strings.write_byte(&b, '\t')
        strings.write_string(&b, the_string)
        strings.write_byte(&b, '\n')
    }
    strings.write_string(&b, "\u0008}")
    return strings.to_string(b)
}

print_statement :: proc(statement: Statement) -> string {

    switch v in statement {
        case Program:
            return "PROGRAM"
        case LetStatement:
           return fmt.tprintf("%v %v = %v", 
            v.token.literal, 
            v.name.value, 
            print_expression(v.expression))
        case ReturnStatement:
            return fmt.tprintf("%v %v", 
            v.token.literal, 
            print_expression(v.expression))
        case ExpressionStatement:
            return fmt.tprintf("%v", 
            print_expression(v.expression))
        case BlockStatement:
            return print_statements(v.statements[:])
    }

    return ""
}

print_expression :: proc(expression: Expression) -> string {
    switch e in expression {
        case Identifier:
            return fmt.tprintf("%v", e.value)
        case IntegerLiteral:
            return fmt.tprintf("%v", e.value)
        case BoolLiteral:
            return fmt.tprint(e.value)
        case StringLiteral:
            return fmt.tprint(e.value)
        case PrefixExpression:
            return fmt.tprintf("%v%v", e.operator, print_expression(e.right^))
        case InfixExpression:
            return fmt.tprintf("(%v %v %v)", print_expression(e.Left^), e.operator, print_expression(e.Right^))
        case IfExpression:
            return fmt.tprintf("if %v%v", print_expression(e.condition^), print_statement(e.consequence^))
        case FunctionLiteral:
            return fmt.tprintf("%v (params) %v", e.token.literal, print_statement(e.body^))
        case CallExpression:
            return fmt.tprintf("%v(%v)", e.function.(Identifier).value, e.arguments)
        case ERROR:
            return fmt.tprintf("ERROR: %v", e.message)
    }
    return ""
}