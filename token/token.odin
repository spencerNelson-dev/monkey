#+feature dynamic-literals

package token

TokenType :: enum {
    ILLEGAL,
    EOF,
    
    IDENT,
    INT,
    STRING,
    
    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,
    
    LT,
    GT,
    EQ,
    NOT_EQ,
    
    COMMA,
    SEMICOLON,
    
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    
    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,
}



keywords := map[string]TokenType {
    "fn" = .FUNCTION,
    "let" = .LET,
    "true" = .TRUE,
    "false" = .FALSE,
    "if" = .IF,
    "else" = .ELSE,
    "return" = .RETURN,
}


Token :: struct {
    type: TokenType,
    literal: string,
}

lookup_ident :: proc(ident: string) -> TokenType {
    s := ident
    tok, ok := keywords[ident]
    if ok {
        return tok
    }
    return .IDENT
}