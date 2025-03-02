package repl

import "core:io"
import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"

import "../lexer"
import "../token"
import "../parser"
import "../ast"
import "../evaluator"
import "../object"


PROMPT :: ">> "

start :: proc(input: os.Handle, out: os.Handle){
    stream := os.stream_from_handle(input)
    defer io.destroy(stream)

    reader, ok := io.to_reader(stream)
    if !ok {
        fmt.println("reader not ok")
    }
    scanner : bufio.Scanner
    defer bufio.scanner_destroy(&scanner)

    bufio.scanner_init(&scanner, reader)

    // fmt.fprintf(out, PROMPT)

    for {
        fmt.fprintf(out, PROMPT)
        start := scanner.start
        scanned := bufio.scanner_scan(&scanner)
        if !scanned {
            return
        }

        line := scanner.buf
        l := lexer.New(strings.clone_from_bytes(line[start:]))
        p := parser.parser_init(&l)

        program := parser.parse_program(&p)

        evaluated := evaluator.eval_statement(program)
        switch e in evaluated {
            case object.Boolean:
                fmt.fprintf(out, "%v\n", e.value)
            case object.Integer:
                fmt.fprintf(out, "%v\n", e.value)
            case object.Null:
                fmt.fprintf(out,"null\n")
        }

        // for tok := lexer.next_token(&l); tok.type != token.TokenType.EOF; tok = lexer.next_token(&l){
        //     fmt.fprintf(out, "%+v\n", tok)
        // }

        // ast.print_program(&program)
    }
}