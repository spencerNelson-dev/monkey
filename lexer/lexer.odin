package lexer

import "core:unicode/utf8"
import "core:strings"
import "core:fmt"

import "../token"

Lexer :: struct {
    input: string,
    position: int,
    read_position: int,
    ch: byte,
}

New :: proc(input: string) -> Lexer {
    l := Lexer{input = input}
    read_char(&l)
    return l
}

read_char :: proc(l: ^Lexer) {
    if l.read_position >= len(l.input){
        l.ch = 0
    } else {
        l.ch = l.input[l.read_position]
    }
    l.position = l.read_position
    l.read_position += 1
}

peek_char :: proc(l: ^Lexer) -> byte {
    if l.read_position >= len(l.input) {
        return 0
    } else {
        return l.input[l.read_position]
    }
}

next_token :: proc(l: ^Lexer) -> token.Token {
    tok: token.Token

    skip_whitespace(l)

    switch l.ch {
        case '=':
            if peek_char(l) == '=' {
                ch := l.ch
                read_char(l)
                literal := strings.concatenate([]string{char_to_string(ch),char_to_string(l.ch)}) 
                tok = new_token(.EQ, literal)
            } else {
                tok = new_token(.ASSIGN, l.ch)
            }
        case ';':
            tok = new_token(.SEMICOLON, l.ch)
        case '(':
            tok = new_token(.LPAREN, l.ch)
        case ')':
            tok = new_token(.RPAREN, l.ch)
        case ',':
            tok = new_token(.COMMA, l.ch)
        case '+':
            tok = new_token(.PLUS, l.ch)
        case '-':
            tok = new_token(.MINUS, l.ch)
        case '!':
            if peek_char(l) == '=' {
                ch := l.ch
                read_char(l)
                literal := strings.concatenate([]string{char_to_string(ch),char_to_string(l.ch)}) 
                tok = new_token(.NOT_EQ, literal)
            } else {
                tok = new_token(.BANG, l.ch)
            }
        case '/':
            tok = new_token(.SLASH, l.ch)
        case '*':
            tok = new_token(.ASTERISK, l.ch)
        case '<':
            tok = new_token(.LT, l.ch)
        case '>':
            tok = new_token(.GT, l.ch)
        case '{':
            tok = new_token(.LBRACE, l.ch)
        case '}':
            tok = new_token(.RBRACE, l.ch)
        case 0:
            tok.literal = ""
            tok.type = .EOF
        case:
            if is_letter(l.ch){
                id := read_identifier(l)
                tok.literal = id
                tok.type = token.lookup_ident(tok.literal)
                return tok
            } else if is_digit(l.ch){
                tok.type = .INT
                tok.literal = read_number(l)
                return tok
            } else {
                tok = new_token(.ILLEGAL, l.ch)
            }
    }    

    read_char(l)
    return tok
}

new_token :: proc {
    new_token_byte,
    new_token_string,
}

new_token_byte :: proc(tokenType: token.TokenType, ch: byte) -> token.Token {
    return token.Token{type = tokenType, literal = char_to_string(ch)}
}

new_token_string :: proc(tokenType: token.TokenType, literal: string) -> token.Token {
    return token.Token{type = tokenType, literal = literal}
}

char_to_string :: proc (ch: byte) -> string {

    runes := []rune{rune(ch)}
    s := utf8.runes_to_string(runes)
    return s
}

read_identifier :: proc(l: ^Lexer) -> string {
    position := l.position
    for is_letter(l.ch) {
        read_char(l)
    }
    ident := l.input[position : l.position]
    return ident
}

read_number :: proc(l: ^Lexer) -> string {
    position := l.position
    for is_digit(l.ch) {
        read_char(l)
    }
    return l.input[position : l.position]
}

is_letter :: proc(ch: byte) -> bool {
    return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

is_digit :: proc(ch: byte) -> bool {
    return '0' <= ch && ch <= '9'
}

skip_whitespace :: proc(l: ^Lexer) {
    for l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' {
        read_char(l)
    }
}
