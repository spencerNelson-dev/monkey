package main

import "core:fmt"
import "core:os"
import vmem "core:mem/virtual"
import "core:mem"

import "token"
import "lexer"
import "repl"
import "parser"
import "ast"
import "evaluator"

main :: proc() {
    when ODIN_DEBUG {
        fmt.println("in debug mode")
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            fmt.println("DEFER SECTION")
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
                }
            }
            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
                }
            }
            mem.tracking_allocator_destroy(&track)    
        }            
    }

    repl.start(os.stdin, os.stdout)
}