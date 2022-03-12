const std = @import("std");

const clap = @import("clap.zig");
const version = @import("version.zig");

const crc32 = std.hash.crc.Crc32;

const Allocator = std.mem.Allocator;
var default_allocator = std.heap.page_allocator;

const help_message = 
\\Usage: crc-collision [OPTION] FILE 
\\ Generates an SQL file with the same CRC32 checksum as the target file.
\\
\\ If arguments are possible, they are mandatory unless specified otherwise.
\\        -h, --help              Display this help and exit.
\\        -c, --comment           Produces a single commented line (default)
\\
;

pub fn main() !void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-c, --comment") catch unreachable,
        clap.parseParam("-h, --help") catch unreachable,
        clap.parseParam("<STR>") catch unreachable,
    };
    
    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        diag.report(std.io.getStdOut().writer(), err) catch {};
        return;
    };
    defer args.deinit();
    
    if (args.flag("--help")) {
        print(help_message, .{});
        std.os.exit(0);
    }
    
    const positionals = args.positionals();

    if (positionals.len != 1) {
        print("One file can and must be supplied. Exiting\n", .{});
        std.os.exit(1);
    }
    
    const file = std.fs.cwd().openFile(positionals[0], .{.read = true}) catch {
        print("Could not read file. Exiting\n", .{});
        std.os.exit(1);
    };
    defer file.close();
    
    var crc32_state = crc32.init();
    const bytes = try file.readToEndAlloc(default_allocator, 1 << 30);
    var tokens = std.mem.tokenize(u8, bytes, "\n");
    while (tokens.next()) |line| {
        if (line.len == 0) {
            continue;
        } else if (line[line.len - 1] == '\r') {
            crc32_state.update(line[0..line.len - 1]);
        } else {
            crc32_state.update(line);
        }
    }
    const target_hash = crc32_state.final();
    _ = target_hash;
    
    const first_value: u8 = 33;
    const last_value: u8 = 126;
    var test_state = [_]u8{'-', '-', ' ', 0, 0, 0, 0, 0, 0};
    
    var j0 = first_value;
    var j1 = first_value;
    var j2 = first_value;
    var j3 = first_value;
    var j4 = first_value;
    var j5 = first_value;
    {    
        var initial = crc32.init();
        initial.update("-- ");
        
        @setRuntimeSafety(false);
        while (j0 <= last_value): (j0 += 1) {
            j1 = first_value;
            var inner0 = initial;
            inner0.update(&.{j0});
            while (j1 <= last_value): (j1 += 1) {
                j2 = first_value;
                var inner1 = inner0;
                inner1.update(&.{j1});
                while (j2 <= last_value): (j2 += 1) {
                    j3 = first_value;
                    var inner2 = inner1;
                    inner2.update(&.{j2});
                    while (j3 <= last_value): (j3 += 1) {
                        j4 = first_value;
                        var inner3 = inner2;
                        inner3.update(&.{j3});
                        while (j4 <= last_value): (j4 += 1) {
                            j5 = first_value;
                            var inner4 = inner3;
                            inner4.update(&.{j4});
                            while (j5 <= last_value): (j5 += 1) {
                                var inner5 = inner4;
                                inner5.update(&.{j5});
                                const calc_val = inner5.final();
                                if (calc_val == target_hash) {
                                    test_state[3] = j0;
                                    test_state[4] = j1;
                                    test_state[5] = j2;
                                    test_state[6] = j3;
                                    test_state[7] = j4;
                                    test_state[8] = j5;
                                    print("{s}\n", .{test_state});
                                    std.os.exit(0);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


pub fn print(comptime format_string: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(format_string, args) catch return;
}
