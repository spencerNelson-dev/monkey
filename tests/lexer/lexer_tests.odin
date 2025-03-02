package lexer_tests

import "core:fmt"

import "../../token"
import "../../lexer"
import "core:testing"

@(test)
test_next_token :: proc(t: ^testing.T){
    input := "=+(){},;"  
    
    Test :: struct {
        expectedType: token.TokenType,
        expectedLiteral: string,
    }
    
    tests := []Test {
        {token.ASSIGN, "="},
        {token.PLUS, "+"},
        {token.LPAREN, "("},
        {token.RPAREN, ")"},
        {token.LBRACE, "{"},
        {token.RBRACE, "}"},
        {token.COMMA, ","},
        {token.SEMICOLON, ";"},
        {token.EOF, ""},
    }

    l := lexer.New(input)

    // tok := lexer.next_token(l)
    // testing.expect(t, tok.type != tests[0].expectedType, "BAD")

    for tt in tests {
        tok := lexer.next_token(&l)

        testing.expectf(t, tok.type == tt.expectedType, "BAD Type %v, expected: %v", tok.type, tt.expectedType)


        testing.expectf(t, tok.literal == tt.expectedLiteral, "BAD LITERAL %v, expected: %v", tok.literal, tt.expectedLiteral)
    
    }

    // for tt, i in tests {
    //     tok := lexer.next_token(l)

    //     testing.expect(t, tok.type == tt.expectedType, "Wrong token type.")

    //     testing.expect(t, tok.literal == tt.expectedLiteral, "Wrong token literal.")
    // }
}