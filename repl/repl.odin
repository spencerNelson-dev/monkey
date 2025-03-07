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

    env := new(object.Environment)
    defer delete(env.store)

    for {
        fmt.fprintf(out, PROMPT)
        start := scanner.start
        scanned := bufio.scanner_scan(&scanner)
        if !scanned {
            return
        }

        line := scanner.buf
        text := strings.clone_from_bytes(line[start:])
        defer delete(text)
        if text[:5] == ":exit" {
            break
        }
        l := lexer.New(text)
        p := parser.parser_init(&l)

        program := parser.parse_program(&p)

        evaluated := evaluator.eval_statement(program, env)
        switch e in evaluated {
            case bool:
                fmt.fprintf(out, "%v\n", e)
            case int:
                fmt.fprintf(out, "%v\n", e)
            case nil:
                //fmt.fprintf(out,"null\n")
            case object.ReturnValue:
                fmt.fprintf(out, "%v\n", e.value)
            case object.ErrorValue:
                fmt.fprintf(out, "%v\n", e.message)
            case object.Function:
                fmt.fprint(out, "fn(")
                for p in e.parameters {
                    fmt.fprintf(out, "%v,", p.value)
                }
                fmt.fprint(out, ") {\n")
                for e in e.body.statements {
                    fmt.fprintf(out, "\t%v\n", ast.print_statement(e))
                }
                fmt.fprint(out, "}\n")
            case object.StringValue:                
                fmt.fprintf(out, "\"%v\"\n", e.value)     
            case object.Builtin:
                fmt.fprintf(out, "Builtin function\n")           
                
        }
        
        // for tok := lexer.next_token(&l); tok.type != token.TokenType.EOF; tok = lexer.next_token(&l){
        //     fmt.fprintf(out, "%+v\n", tok)
        // }

        // ast.print_program(&program)
    }
}