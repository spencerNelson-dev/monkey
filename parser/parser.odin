#+feature dynamic-literals

package parser

import "core:fmt"
import "core:strconv"

import "../ast"
import "../lexer"
import "../token"

Precedence :: enum {
    _,
    LOWEST,
    EQUALS,
    LESSGREATER,
    SUM,
    PRODUCT,
    PREFIX,
    CALL
}

precedences := map[token.TokenType]Precedence{
    .EQ         = .EQUALS,
    .NOT_EQ     = .EQUALS,
    .LT         = .LESSGREATER,
    .GT         = .LESSGREATER,
    .PLUS       = .SUM,
    .MINUS      = .SUM,
    .SLASH      = .PRODUCT,
    .ASTERISK   = .PRODUCT,
    .LPAREN     = .CALL,
}

Parser :: struct {
    l: ^lexer.Lexer,

    curToken: token.Token,
    peekToken: token.Token,

    prefixParseFns: map[token.TokenType]prefixParseFn,
    infixParseFns: map[token.TokenType]infixfixParseFn,
}

prefixParseFn :: proc(p: ^Parser) -> (ast.Expression, bool)
infixfixParseFn :: proc(p: ^Parser, expression: ^ast.Expression) -> (ast.Expression, bool)

parser_init :: proc(l: ^lexer.Lexer) -> Parser {
    p : Parser
    p.l = l

    next_token(&p)
    next_token(&p)

    register_prefix(&p, token.TokenType.IDENT, parse_identifier)
    register_prefix(&p, .INT, parse_integer_literal)
    register_prefix(&p, .MINUS, parse_prefix_expression)
    register_prefix(&p, .BANG, parse_prefix_expression)
    register_prefix(&p, .TRUE, parse_boolean)
    register_prefix(&p, .FALSE, parse_boolean)
    register_prefix(&p, .LPAREN, parse_grouped_expression)
    register_prefix(&p, .IF, parse_if_expression)
    register_prefix(&p, .FUNCTION, parse_function_literal)

    register_infix(&p, .PLUS, parse_infix_expression)
    register_infix(&p, .MINUS, parse_infix_expression)
    register_infix(&p, .SLASH, parse_infix_expression)
    register_infix(&p, .ASTERISK, parse_infix_expression)
    register_infix(&p, .EQ, parse_infix_expression)
    register_infix(&p, .NOT_EQ, parse_infix_expression)
    register_infix(&p, .LT, parse_infix_expression)
    register_infix(&p, .GT, parse_infix_expression)
    register_infix(&p, .LPAREN, parse_call_expression)

    return p
}

register_prefix :: proc(p: ^Parser, token_type: token.TokenType, fn: prefixParseFn ) {
    p.prefixParseFns[token_type] = fn
}

register_infix :: proc(p: ^Parser, token_type: token.TokenType, fn: infixfixParseFn) {
    p.infixParseFns[token_type] = fn
}

next_token :: proc(p: ^Parser) {
    p.curToken = p.peekToken
    p.peekToken = lexer.next_token(p.l)
}

cur_token_is :: proc(p: ^Parser, t: token.TokenType) -> bool {
    return p.curToken.type == t
}

cur_precedence :: proc(p: ^Parser) -> Precedence {
    if prec, ok := precedences[p.curToken.type]; ok {
        return prec
    }

    return .LOWEST
}

peek_token_is :: proc(p: ^Parser, t: token.TokenType) -> bool {
    return p.peekToken.type == t
}

peek_precedence :: proc (p: ^Parser) -> Precedence {
    if prec, ok := precedences[p.peekToken.type]; ok {
        return prec
    }

    return .LOWEST
}

expect_peek :: proc(p: ^Parser, t: token.TokenType) -> bool {
    if peek_token_is(p, t) {
        next_token(p)
        return true
    } else {
        return false
    }
}

parse_program :: proc(p: ^Parser,) -> ast.Program {
    program := ast.Program{}
    
    for p.curToken.type != .EOF {
        stmt, ok := parse_statement(p)
        if ok {
            append(&program.statements, stmt)
        }
        next_token(p)
    }

    return program
}


parse_statement :: proc(p: ^Parser) -> (ast.Statement, bool) {
    test := p.curToken.type == token.TokenType.LET
    #partial switch p.curToken.type {
        case token.TokenType.LET:
            return parse_let_statement(p)
        case token.TokenType.RETURN:
            return parse_return_statement(p)
        case:
            return parse_expression_statement(p)
    }
}

parse_let_statement :: proc(p: ^Parser) -> (ast.Statement, bool){
    stmt := ast.LetStatement {
            token = p.curToken,
        }

    if !expect_peek(p, token.TokenType.IDENT) {
        return stmt, false
    }

    stmt.name = ast.Identifier{
        token = p.curToken,
        value = p.curToken.literal,
    }

    if !expect_peek(p, token.TokenType.ASSIGN) {
        return stmt, false
    }

    next_token(p)

    ok: bool
    stmt.expression, ok = parse_expression(p, .LOWEST)

    if peek_token_is(p, .SEMICOLON) {
        next_token(p)
    }

    return stmt, true
}

parse_return_statement :: proc(p: ^Parser) -> (ast.Statement, bool) {
    stmt := ast.ReturnStatement {
        token = p.curToken,
    }

    next_token(p)

    ok: bool
    stmt.expression, ok = parse_expression(p, .LOWEST)

    if peek_token_is(p, .SEMICOLON) {
        next_token(p)
    }

    return stmt, ok
}

parse_expression :: proc(p: ^Parser, precedence: Precedence) -> (ast.Expression, bool) {
    prefix, ok := p.prefixParseFns[p.curToken.type]
    if !ok {
        return ast.Identifier{}, false
    }
    l_e , _ := prefix(p)
    left_exp := new(ast.Expression)
    left_exp^ = l_e


    for !peek_token_is(p, .SEMICOLON) && precedence < peek_precedence(p){
        infix, ok_p := p.infixParseFns[p.peekToken.type]
        if !ok_p {
            return left_exp^, true
        }

        next_token(p)

        left_exp^, _ = infix(p, left_exp)
    }

    return left_exp^, true
}

parse_expression_statement :: proc(p: ^Parser) -> (ast.Statement, bool){
    stmt := ast.ExpressionStatement{
        token = p.curToken
    }
    ok : bool

    stmt.expression, ok = parse_expression(p, .LOWEST)

    if peek_token_is(p, token.TokenType.SEMICOLON) {
        next_token(p)
    }

    return stmt, ok
}

parse_identifier :: proc(p: ^Parser) -> (ast.Expression, bool) {
    return ast.Identifier{
        token = p.curToken,
        value = p.curToken.literal
    }, true
}

parse_boolean :: proc(p: ^Parser) -> (ast.Expression, bool) {
    boolean := ast.BoolLiteral{token = p.curToken}

    value, ok := strconv.parse_bool(p.curToken.literal)
    if !ok {
        return boolean, false
    }

    boolean.value = value

    return boolean, ok
}

parse_integer_literal :: proc(p: ^Parser) -> (ast.Expression, bool) {
    lit := ast.IntegerLiteral{token = p.curToken}

    value, ok := strconv.parse_int(p.curToken.literal)
    if !ok {
        return lit, false
    }

    lit.value = value

    return lit, ok
}

parse_prefix_expression :: proc(p: ^Parser) -> (ast.Expression, bool) {
    expression := ast.PrefixExpression {
        token = p.curToken,
        operator = p.curToken.literal,
    }

    next_token(p)

    ex, ok := parse_expression(p, .PREFIX)

    right_expression := new(ast.Expression)
    right_expression^ = ex

    expression.right = right_expression

    return expression, ok
}

parse_infix_expression :: proc(p: ^Parser, left: ^ast.Expression) -> (ast.Expression, bool){
    new_left := new(ast.Expression)
    new_left^ = left^

    expression := ast.InfixExpression {
        token = p.curToken,
        operator = p.curToken.literal,
        Left = new_left
    }

    precedence := cur_precedence(p)
    next_token(p)

    r, ok := parse_expression(p, precedence)
    right_expression := new(ast.Expression)
    right_expression^ = r
    expression.Right = right_expression

    return expression, ok
}

parse_grouped_expression :: proc(p: ^Parser) -> (ast.Expression, bool){
    next_token(p)

    exp, ok := parse_expression(p, .LOWEST)

    if !expect_peek(p, .RPAREN) {
        return nil, false
    }

    return exp, ok
}

parse_block_statement :: proc(p: ^Parser) -> ^ast.BlockStatement {
    block := new(ast.BlockStatement)
    block.token = p.curToken

    next_token(p)

    for !cur_token_is(p, .RBRACE) && !cur_token_is(p, .EOF) {
        stmt, ok := parse_statement(p)
        if ok {
            append(&block.statements, stmt)
        }
        next_token(p)
    }

    return block
}

parse_if_expression :: proc(p: ^Parser) -> (ast.Expression, bool) {
    expression := ast.IfExpression{token = p.curToken}

    if !expect_peek(p, .LPAREN) {
        return nil, false
    }

    next_token(p)
    if_expression := new(ast.Expression)
    ie, _ := parse_expression(p, .LOWEST)
    if_expression^ = ie
    expression.condition = if_expression

    if !expect_peek(p, .RPAREN) {
        return nil, false
    }

    if !expect_peek(p, .LBRACE){
        return nil, false
    }

    expression.consequence = parse_block_statement(p)

    if peek_token_is(p, .ELSE) {
        next_token(p)

        if !expect_peek(p, .LBRACE) {
            return nil, false
        }

        expression.alternative = parse_block_statement(p)
    }

    return expression, true
}

parse_function_literal :: proc(p: ^Parser) -> (ast.Expression, bool) {
    lit := ast.FunctionLiteral {token = p.curToken}

    if !expect_peek(p, .LPAREN){
        return nil, false
    }

    ok := parse_function_parameters(p, &lit.parameters)
    if !ok {
        return nil, false
    }

    if !expect_peek(p, .LBRACE) {
        return nil, false
    }

    lit.body = parse_block_statement(p)

    return lit, true
}

parse_function_parameters :: proc(p: ^Parser, params: ^[dynamic]^ast.Identifier) -> bool {
    if peek_token_is(p, .RPAREN) {
        next_token(p)
        return true
    }

    next_token(p)

    ident := new(ast.Identifier)
    ident.token = p.curToken
    ident.value = p.curToken.literal
    
    append(params, ident)

    for peek_token_is(p, .COMMA) {
        next_token(p)
        next_token(p)
        ident = new(ast.Identifier)
        ident.token = p.curToken
        ident.value = p.curToken.literal
        append(params, ident)
    }

    if !expect_peek(p, .RPAREN){
        return false
    }

    return true
}

parse_call_expression :: proc(p: ^Parser, function: ^ast.Expression) -> (ast.Expression, bool) {
    exp := ast.CallExpression {token = p.curToken, function = function}
    ok := parse_call_arguments(p, &exp.arguments)
    if !ok {
        return nil, false
    }

    return exp, ok
}

parse_call_arguments :: proc(p: ^Parser, args: ^[dynamic]^ast.Expression) -> bool {
    if peek_token_is(p, .RPAREN) {
        next_token(p)
        return true
    }

    next_token(p)
    arg := new(ast.Expression)
    ex, _ := parse_expression(p, .LOWEST)
    arg^ = ex
    append(args, arg)

    for peek_token_is(p, .COMMA) {
        next_token(p)
        next_token(p)
        arg = new(ast.Expression)
        ex, _ = parse_expression(p, .LOWEST)
        arg^ = ex
        append(args, arg)
    }

    if !expect_peek(p, .RPAREN) {
        return false
    }

    return true
}